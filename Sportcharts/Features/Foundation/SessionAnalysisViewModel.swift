//
//  SessionAnalysisViewModel.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/05/26.
//

import Combine
import Foundation
import FoundationModels

@MainActor
final class SessionAnalysisViewModel: ObservableObject {
	@Published var isResponding: Bool = false
	@Published var messages: [ChatMessage] = []
	@Published var pilots: [F1Driver] = []
	@Published var analysisText: String = ""
	@Published var smartQuestions: [String] = []

	private let maxPrimaryContextLength = 6_000
	private let maxFallbackContextLength = 3_200
	private let maxPrimaryResults = 12
	private let maxFallbackResults = 6
	private let streamingDelayNanoseconds: UInt64 = 8_000_000

	private let modelInstructions = """
	Você é um analista esportivo de Fórmula 1.
	Responda em português do Brasil.
	Seja claro, objetivo e específico com base no contexto da sessão.
	"""

	func startSessionAnalysis(sessionContext: String) async {
		let trimmedContext = sessionContext.trimmingCharacters(
			in: .whitespacesAndNewlines
		)

		guard !trimmedContext.isEmpty else {
			analysisText = ""
			smartQuestions = []
			messages = [
				ChatMessage(
					role: .assistant,
					content: "Não encontrei dados suficientes para analisar esta sessão."
				)
			]
			pilots = []
			return
		}

		isResponding = true
		analysisText = ""
		messages = []
		pilots = []
		smartQuestions = []

		defer { isResponding = false }

		let compactPrimary = compactSessionContext(
			trimmedContext,
			maxLength: maxPrimaryContextLength,
			maxResults: maxPrimaryResults
		)

		do {
			guard case .available = SystemLanguageModel.default.availability else {
				await publishFallbackAnalysis(
					for: trimmedContext,
					reason: modelUnavailableMessage()
				)
				return
			}

			try await requestAndPublishAnalysis(context: compactPrimary)
		} catch {
			if shouldRetryWithSmallerContext(error) {
				do {
					let compactFallback = compactSessionContext(
						trimmedContext,
						maxLength: maxFallbackContextLength,
						maxResults: maxFallbackResults
					)

					try await requestAndPublishAnalysis(context: compactFallback)
					return
				} catch {
					await publishFallbackAnalysis(
						for: trimmedContext,
						reason: error.localizedDescription
					)
					return
				}
			}

			await publishFallbackAnalysis(
				for: trimmedContext,
				reason: error.localizedDescription
			)
		}
	}

	private func requestAndPublishAnalysis(context: String) async throws {
		let session = LanguageModelSession(instructions: modelInstructions)

		let response = try await session.respond(
			to: """
				Analise esta sessão com base no contexto resumido abaixo.
				Use apenas as informações fornecidas.
				Quando citar um piloto pela primeira vez no texto, use o nome completo exatamente como aparece no contexto.
				Em driverNumbers, inclua somente números de carros que aparecem no contexto.

				\(context)
			""",
			generating: SessionAnalysis.self
		)

		let sanitized = sanitize(response.content)
		let rendered = render(sanitized)

		await publishAnalysis(
			rendered,
			smartQuestions: sanitized.smartQuestions,
			pilots: resolvedPilots(from: sanitized.driverNumbers)
		)
	}

	private func publishFallbackAnalysis(for context: String, reason: String) async {
		let analysis = fallbackAnalysis(from: context)
		let rendered = render(analysis)
		let note = cleanSentence(reason)
		let displayed = """
		\(rendered)

		> Análise local usada porque o Foundation Model não respondeu: \(note)
		"""

		await publishAnalysis(
			displayed,
			copyableText: rendered,
			smartQuestions: analysis.smartQuestions,
			pilots: resolvedPilots(from: analysis.driverNumbers)
		)
	}

	private func publishAnalysis(
		_ displayedText: String,
		copyableText: String? = nil,
		smartQuestions resolvedSmartQuestions: [String],
		pilots resolvedPilots: [F1Driver]
	) async {
		let assistantMessage = ChatMessage(
			role: .assistant,
			content: "",
			state: .typing
		)

		analysisText = copyableText ?? displayedText
		messages = [assistantMessage]
		pilots = resolvedPilots
		smartQuestions = resolvedSmartQuestions

		for character in displayedText {
			if Task.isCancelled { return }

			guard let index = messages.firstIndex(where: {
				$0.id == assistantMessage.id
			}) else {
				return
			}

			messages[index].content.append(character)
			try? await Task.sleep(nanoseconds: streamingDelayNanoseconds)
		}

		if let index = messages.firstIndex(where: {
			$0.id == assistantMessage.id
		}) {
			messages[index].state = .sent
		}
	}

	private func shouldRetryWithSmallerContext(_ error: Error) -> Bool {
		let description = error.localizedDescription.lowercased()
		return description.contains("context window")
			|| description.contains("window size")
			|| description.contains("token")
	}

	private func compactSessionContext(
		_ context: String,
		maxLength: Int,
		maxResults: Int
	) -> String {
		let cleaned = context
			.replacingOccurrences(of: "\r", with: "")
			.trimmingCharacters(in: .whitespacesAndNewlines)

		guard let resultsRange = cleaned.range(of: "Resultados:") else {
			return hardLimit(cleaned, maxLength: maxLength)
		}

		let header = cleaned[..<resultsRange.lowerBound]
		let resultsText = cleaned[resultsRange.upperBound...]
		let additionalContext = extractAdditionalContext(String(resultsText))

		let compactHeader = header
			.split(separator: "\n")
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty }
			.joined(separator: "\n")

		let blocks = extractResultBlocks(String(resultsText))
		let selectedBlocks = Array(blocks.prefix(maxResults))

		let compactResults = selectedBlocks.enumerated().map { index, block in
			compactResultBlock(block, fallbackIndex: index + 1)
		}.joined(separator: "\n")

		var compact = """
		\(compactHeader)

		Resultados resumidos (\(selectedBlocks.count) de \(blocks.count)):
		\(compactResults)
		"""

		if blocks.count > selectedBlocks.count {
			compact += "\n... \(blocks.count - selectedBlocks.count) resultados omitidos para caber no contexto."
		}

		if let additionalContext {
			compact += "\n\n\(additionalContext)"
		}

		return hardLimit(compact, maxLength: maxLength)
	}

	private func extractAdditionalContext(_ resultsText: String) -> String? {
		let marker = "Contexto adicional leve da OpenF1:"

		guard let range = resultsText.range(of: marker) else {
			return nil
		}

		let context = resultsText[range.lowerBound...]
			.trimmingCharacters(in: .whitespacesAndNewlines)

		guard !context.isEmpty else {
			return nil
		}

		return hardLimit(context, maxLength: 1_800)
	}

	private func extractResultBlocks(_ resultsText: String) -> [String] {
		let rows = resultsText
			.components(separatedBy: "\n\n")
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty }
			.filter { $0.contains("Posição:") && $0.contains("Piloto:") }

		if !rows.isEmpty {
			return rows
		}

		return resultsText
			.split(separator: "\n")
			.map(String.init)
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { $0.hasPrefix("Posição:") }
	}

	private func compactResultBlock(_ block: String, fallbackIndex: Int) -> String {
		let lines = block
			.split(separator: "\n")
			.map(String.init)
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

		func value(for prefix: String) -> String? {
			if let line = lines.first(where: { $0.hasPrefix(prefix) }) {
				let replaced = line.replacingOccurrences(of: prefix, with: "")
				return replaced.trimmingCharacters(in: .whitespacesAndNewlines)
			}
			return nil
		}

		let position = value(for: "Posição:") ?? "\(fallbackIndex)"
		let driver = value(for: "Piloto:") ?? "Desconhecido"
		let team = value(for: "Equipe:") ?? ""
		let number = value(for: "Número:") ?? "--"
		let points = value(for: "Pontos:") ?? "0"
		let laps = value(for: "Voltas completadas:") ?? "0"
		let gap = value(for: "Gap para líder:") ?? "--"

		let dnf = (value(for: "- DNF:")?.lowercased() == "true")
		let dsq = (value(for: "- DSQ:")?.lowercased() == "true")
		let dns = (value(for: "- DNS:")?.lowercased() == "true")

		var status: [String] = []
		if dnf { status.append("DNF") }
		if dsq { status.append("DSQ") }
		if dns { status.append("DNS") }

		let statusText = status.isEmpty ? "OK" : status.joined(separator: ",")

		return "P\(position) | #\(number) | \(driver) | \(team) | \(points) pts | \(laps) voltas | gap \(gap) | \(statusText)"
	}

	private func hardLimit(_ text: String, maxLength: Int) -> String {
		let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
		guard trimmed.count > maxLength else { return trimmed }

		let prefix = String(trimmed.prefix(maxLength - 80))
		return prefix + "\n... contexto truncado para manter o limite do modelo."
	}

	private func sanitize(_ analysis: SessionAnalysis) -> SessionAnalysis {
		var sanitized = analysis
		sanitized.summary = cleanSentence(analysis.summary)
		sanitized.storyline = cleanSentence(analysis.storyline)
		sanitized.keyMoment = cleanSentence(analysis.keyMoment)
		sanitized.nextAction = cleanSentence(analysis.nextAction)

		if sanitized.storyline.isEmpty {
			sanitized.storyline = sanitized.summary
		}

		if sanitized.keyMoment.isEmpty {
			sanitized.keyMoment = "O resultado final e os gaps foram os principais sinais da sessão."
		}

		sanitized.positives = sanitizedList(
			analysis.positives,
			emptyFallback: "Nenhum destaque informado"
		)

		sanitized.improvements = sanitizedList(
			analysis.improvements,
			emptyFallback: "Nenhum ponto de melhoria informado"
		)

		sanitized.smartQuestions = sanitizedList(
			analysis.smartQuestions,
			emptyFallback: "O que decidiu esta sessão?"
		)

		if sanitized.smartQuestions.count > 3 {
			sanitized.smartQuestions = Array(sanitized.smartQuestions.prefix(3))
		}

		let fallbackQuestions = [
			"O que decidiu esta sessão?",
			"Quem superou mais as expectativas?",
			"Qual é o principal ponto de atenção para a próxima sessão?",
		]

		for question in fallbackQuestions where sanitized.smartQuestions.count < 3 {
			if !sanitized.smartQuestions.contains(where: {
				$0.caseInsensitiveCompare(question) == .orderedSame
			}) {
				sanitized.smartQuestions.append(question)
			}
		}

		sanitized.driverNumbers = uniqueDriverNumbers(analysis.driverNumbers)
		return sanitized
	}

	private func sanitizedList(_ items: [String], emptyFallback: String) -> [String] {
		let normalized = items
			.map { cleanSentence($0) }
			.filter { !$0.isEmpty }

		var seen = Set<String>()
		let unique = normalized.filter { item in
			let key = item.lowercased()
			let inserted = seen.insert(key).inserted
			return inserted
		}

		if unique.isEmpty {
			return [emptyFallback]
		}

		return Array(unique.prefix(5))
	}

	private func uniqueDriverNumbers(_ numbers: [Int]) -> [Int] {
		var seenNumbers = Set<Int>()
		let cleaned = numbers.filter { number in
			guard F1Grid2026.driver(byNumber: number) != nil else { return false }
			return seenNumbers.insert(number).inserted
		}

		return Array(cleaned.prefix(8))
	}

	private func resolvedPilots(from numbers: [Int]) -> [F1Driver] {
		numbers.compactMap { F1Grid2026.driver(byNumber: $0) }
	}

	private func cleanSentence(_ text: String) -> String {
		text
			.replacingOccurrences(of: "\n", with: " ")
			.replacingOccurrences(of: "  ", with: " ")
			.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private func render(_ analysis: SessionAnalysis) -> String {
		let positives = analysis.positives
			.map { "- \($0)" }
			.joined(separator: "\n")

		let improvements = analysis.improvements
			.map { "- \($0)" }
			.joined(separator: "\n")

		return """
## Storyline
\(analysis.storyline)

## Momento-chave
\(analysis.keyMoment)

## Resumo
\(analysis.summary)

## Pontos positivos
\(positives)

## Melhorias
\(improvements)

## Próxima ação
\(analysis.nextAction)
"""
	}
}

private extension SessionAnalysisViewModel {
	struct ResultSummary {
		let position: Int?
		let driverNumber: Int?
		let driverName: String
		let teamName: String
		let points: Double
		let laps: Int
		let gap: String
		let status: String
	}

	func modelUnavailableMessage() -> String {
		switch SystemLanguageModel.default.availability {
		case .available:
			return "Modelo disponível."
		case .unavailable(.deviceNotEligible):
			return "este dispositivo não é compatível com Apple Intelligence."
		case .unavailable(.appleIntelligenceNotEnabled):
			return "Apple Intelligence não está ativado nos Ajustes."
		case .unavailable(.modelNotReady):
			return "o modelo local ainda não está pronto."
		case .unavailable(let reason):
			return "o modelo local não está disponível agora (\(reason))."
		}
	}

	func fallbackAnalysis(from context: String) -> SessionAnalysis {
		let results = parseResults(from: context)
		let classified = classify(results)
		let winner = results.first(where: { $0.position == 1 }) ?? results.first
		let podium = results
			.filter { ($0.position ?? Int.max) <= 3 }
			.map(\.driverName)
			.joined(separator: ", ")

		let summary = fallbackSummary(
			winner: winner,
			podium: podium,
			resultCount: results.count
		)

		let positives = fallbackPositives(
			winner: winner,
			podium: podium,
			pointsScorers: classified.pointsScorers
		)

		let improvements = fallbackImprovements(
			incidents: classified.incidents,
			lowLaps: classified.lowLaps
		)

		let driverNumbers = ([
			winner?.driverNumber,
			results.first(where: { $0.position == 2 })?.driverNumber,
			results.first(where: { $0.position == 3 })?.driverNumber
		] + classified.incidents.prefix(3).map(\.driverNumber))
			.compactMap { $0 }

		let storyline = fallbackStoryline(
			winner: winner,
			podium: podium
		)
		let keyMoment = fallbackKeyMoment(
			winner: winner,
			incidents: classified.incidents
		)

		return sanitize(
			SessionAnalysis(
				summary: summary,
				storyline: storyline,
				keyMoment: keyMoment,
				positives: positives,
				improvements: improvements,
				nextAction: "Revise os gaps e os abandonos antes de definir o foco da próxima sessão.",
				smartQuestions: SessionSmartQuestionBuilder.questions(from: context),
				driverNumbers: driverNumbers
			)
		)
	}

	func fallbackStoryline(
		winner: ResultSummary?,
		podium: String
	) -> String {
		guard let winner else {
			return "A sessão ainda não tem dados suficientes para uma storyline confiável."
		}

		let podiumText = podium.isEmpty ? "com o restante do pódio indefinido" : "à frente de \(podium)"
		return "\(winner.driverName) marcou a narrativa da sessão \(podiumText)."
	}

	func fallbackKeyMoment(
		winner: ResultSummary?,
		incidents: [ResultSummary]
	) -> String {
		if let incident = incidents.first {
			return "O status \(incident.status) de \(incident.driverName) foi o principal ponto de atenção do resultado."
		}

		if let winner {
			return "A liderança de \(winner.driverName) e o gap final orientam a leitura da sessão."
		}

		return "Os resultados disponíveis ainda não indicam um momento-chave claro."
	}

	func fallbackSummary(
		winner: ResultSummary?,
		podium: String,
		resultCount: Int
	) -> String {
		guard let winner else {
			return "Não há resultados suficientes para produzir uma análise completa da sessão."
		}

		let podiumText = podium.isEmpty ? "sem pódio definido" : "com pódio formado por \(podium)"
		return "\(winner.driverName) liderou a sessão pela \(winner.teamName), \(podiumText). A classificação inclui \(resultCount) resultados e destaca diferenças de ritmo, pontuação e status de chegada."
	}

	func fallbackPositives(
		winner: ResultSummary?,
		podium: String,
		pointsScorers: [ResultSummary]
	) -> [String] {
		var positives: [String] = []

		if let winner {
			positives.append("\(winner.driverName) converteu a liderança em referência principal da sessão")
		}

		if !podium.isEmpty {
			positives.append("O pódio concentrou os melhores resultados com \(podium)")
		}

		if !pointsScorers.isEmpty {
			positives.append("\(pointsScorers.count) pilotos terminaram na zona de pontos")
		}

		return positives
	}

	func fallbackImprovements(
		incidents: [ResultSummary],
		lowLaps: [ResultSummary]
	) -> [String] {
		var improvements: [String] = []

		if !incidents.isEmpty {
			let names = incidents.map(\.driverName).joined(separator: ", ")
			improvements.append("Investigar os status de corrida de \(names)")
		}

		if !lowLaps.isEmpty {
			let names = lowLaps.map(\.driverName).joined(separator: ", ")
			improvements.append("Entender a perda de voltas de \(names)")
		}

		if improvements.isEmpty {
			improvements.append("Comparar gaps por equipe para encontrar oportunidades de ritmo")
		}

		return improvements
	}

	func classify(_ results: [ResultSummary]) -> (
		pointsScorers: [ResultSummary],
		incidents: [ResultSummary],
		lowLaps: [ResultSummary]
	) {
		let maxLaps = results.map(\.laps).max() ?? 0
		let pointsScorers = results.filter { $0.points > 0 }
		let incidents = results.filter { $0.status != "OK" }
		let lowLaps = results.filter {
			maxLaps > 0 && $0.laps > 0 && $0.laps < maxLaps
		}

		return (pointsScorers, incidents, lowLaps)
	}

	func parseResults(from context: String) -> [ResultSummary] {
		guard let resultsRange = context.range(of: "Resultados") else {
			return []
		}

		return extractResultBlocks(String(context[resultsRange.upperBound...]))
			.enumerated()
			.map { index, block in
				resultSummary(from: block, fallbackPosition: index + 1)
			}
	}

	func resultSummary(
		from block: String,
		fallbackPosition: Int
	) -> ResultSummary {
		let lines = block
			.split(separator: "\n")
			.map(String.init)
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

		func value(for prefix: String) -> String? {
			guard let line = lines.first(where: { $0.hasPrefix(prefix) }) else {
				return nil
			}

			return line
				.replacingOccurrences(of: prefix, with: "")
				.trimmingCharacters(in: .whitespacesAndNewlines)
		}

		let statusFlags = ["DNF", "DSQ", "DNS"].filter { flag in
			value(for: "- \(flag):")?.lowercased() == "true"
		}

		return ResultSummary(
			position: Int(value(for: "Posição:") ?? "") ?? fallbackPosition,
			driverNumber: Int(value(for: "Número:") ?? ""),
			driverName: value(for: "Piloto:") ?? "Desconhecido",
			teamName: value(for: "Equipe:") ?? "Equipe não informada",
			points: Double(value(for: "Pontos:") ?? "") ?? 0,
			laps: Int(value(for: "Voltas completadas:") ?? "") ?? 0,
			gap: value(for: "Gap para líder:") ?? "--",
			status: statusFlags.isEmpty ? "OK" : statusFlags.joined(separator: ",")
		)
	}
}

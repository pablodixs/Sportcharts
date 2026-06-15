//
//  HomeBriefViewModel.swift
//  Sportcharts
//
//  Created by Codex on 15/06/26.
//

import Foundation
import FoundationModels
import Observation

@MainActor
@Observable
final class HomeBriefViewModel {
	enum State: Equatable {
		case idle
		case loading
		case success
		case empty
		case failure(String)
	}

	private(set) var state: State = .idle
	private(set) var brief: HomeSessionBrief?
	private(set) var sessionContext: String = ""

	private let service: OpenF1Service
	private static var cache: [Int: CachedBrief] = [:]

	private let maxResults = 8
	private let modelInstructions = """
	Você é um analista esportivo de Fórmula 1.
	Responda em português do Brasil.
	Use somente os dados fornecidos.
	Seja curto, específico e útil para uma tela inicial.
	"""

	init(service: OpenF1Service = OpenF1Service()) {
		self.service = service
	}

	func loadBrief(for session: Session) async {
		guard state != .loading else {
			return
		}

		if let cached = Self.cache[session.sessionKey] {
			brief = cached.brief
			sessionContext = cached.context
			state = .success
			return
		}

		state = .loading
		brief = nil
		sessionContext = ""

		do {
			let results = try await service.fetchSessionResult(
				sessionKey: session.sessionKey
			)
			.sorted { lhs, rhs in
				(lhs.position ?? Int.max) < (rhs.position ?? Int.max)
			}

			guard !results.isEmpty else {
				state = .empty
				return
			}

			let context = makeContext(session: session, results: results)
			let generated = await makeBrief(
				session: session,
				results: results,
				context: context
			)

			brief = generated
			sessionContext = context
			Self.cache[session.sessionKey] = CachedBrief(
				brief: generated,
				context: context
			)
			state = .success
		} catch {
			state = .failure(error.localizedDescription)
		}
	}

	private func makeBrief(
		session: Session,
		results: [SessionResult],
		context: String
	) async -> HomeSessionBrief {
		let fallback = fallbackBrief(session: session, results: results)

		guard case .available = SystemLanguageModel.default.availability else {
			return fallback
		}

		do {
			let modelSession = LanguageModelSession(instructions: modelInstructions)
			let response = try await modelSession.respond(
				to: """
				Gere um brief compacto para a tela inicial do app com base no contexto abaixo.
				Mantenha headline, resumo, destaques e perguntas curtos.
				Não cite dados que não aparecem no contexto.

				\(context)
				""",
				generating: HomeSessionBrief.self
			)

			return sanitize(response.content, fallback: fallback)
		} catch {
			return fallback
		}
	}

	private func makeContext(session: Session, results: [SessionResult]) -> String {
		let topResults = results.prefix(maxResults).map { result in
			let driver = F1Grid2026.driver(byNumber: result.driverNumber)
			let gap = gapText(for: result)
			let status = statusText(for: result)

			return """
			Posição: \(result.position?.description ?? "--")
			Piloto: \(driver?.fullName ?? "Desconhecido")
			Equipe: \(driver?.team.rawValue ?? "")
			Número: \(result.driverNumber)
			Pontos: \(result.points)
			Voltas: \(result.numberOfLaps)
			Gap: \(gap)
			Status: \(status)
			"""
		}
		.joined(separator: "\n\n")

		return """
		Sessão de Fórmula 1

		Evento: \(session.sessionName)
		Local: \(session.location), \(session.countryName)
		Circuito: \(session.circuitShortName)
		Tipo: \(session.sessionType)
		Data: \(session.formattedDateStart(useTrackTime: false))

		Resultados:

		\(topResults)
		"""
	}

	private func fallbackBrief(
		session: Session,
		results: [SessionResult]
	) -> HomeSessionBrief {
		let ordered = results.sorted {
			($0.position ?? Int.max) < ($1.position ?? Int.max)
		}
		let winner = ordered.first.flatMap {
			F1Grid2026.driver(byNumber: $0.driverNumber)
		}
		let podium = ordered.prefix(3).compactMap {
			F1Grid2026.driver(byNumber: $0.driverNumber)?.lastName
		}
		let dnfs = ordered.filter { $0.dnf || $0.dns || $0.dsq }.count
		let winnerText = winner?.fullName ?? "o vencedor"

		var highlights: [String] = []

		if !podium.isEmpty {
			highlights.append("Pódio: \(podium.joined(separator: ", ")).")
		}

		if let leader = ordered.first {
			highlights.append(
				"\(winnerText) somou \(leader.points) pontos na sessão."
			)
		}

		if dnfs > 0 {
			highlights.append("\(dnfs) piloto(s) tiveram DNF, DNS ou DSQ.")
		} else {
			highlights.append("Sem abandonos ou desclassificações no top analisado.")
		}

		return HomeSessionBrief(
			headline: "\(winnerText) lidera a leitura da última sessão",
			summary:
				"\(session.sessionName) fechou com \(winnerText) no topo. O resultado dá uma leitura rápida de forma antes da próxima atividade.",
			highlights: Array(highlights.prefix(3)),
			smartQuestions: SessionSmartQuestionBuilder.questions(
				from: makeContext(session: session, results: results)
			)
		)
	}

	private func sanitize(
		_ brief: HomeSessionBrief,
		fallback: HomeSessionBrief
	) -> HomeSessionBrief {
		var sanitized = brief

		sanitized.headline = clean(brief.headline)
		if sanitized.headline.isEmpty {
			sanitized.headline = fallback.headline
		}

		sanitized.summary = clean(brief.summary)
		if sanitized.summary.isEmpty {
			sanitized.summary = fallback.summary
		}

		sanitized.highlights = sanitizedList(
			brief.highlights,
			fallback: fallback.highlights,
			limit: 3
		)
		sanitized.smartQuestions = sanitizedList(
			brief.smartQuestions,
			fallback: fallback.smartQuestions,
			limit: 3
		)

		return sanitized
	}

	private func sanitizedList(
		_ values: [String],
		fallback: [String],
		limit: Int
	) -> [String] {
		var seen = Set<String>()
		let cleaned = values
			.map(clean)
			.filter { !$0.isEmpty }
			.filter { seen.insert($0.lowercased()).inserted }

		let source = cleaned.isEmpty ? fallback : cleaned
		return Array(source.prefix(limit))
	}

	private func clean(_ text: String) -> String {
		text
			.replacingOccurrences(of: "\n", with: " ")
			.replacingOccurrences(of: "  ", with: " ")
			.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private func gapText(for result: SessionResult) -> String {
		switch result.gapToLeader {
		case .seconds(let seconds):
			seconds == 0 ? "Líder" : "+\(String(format: "%.3f", seconds))s"
		case .laps(let laps):
			laps
		case nil:
			"--"
		}
	}

	private func statusText(for result: SessionResult) -> String {
		if result.dsq { return "DSQ" }
		if result.dns { return "DNS" }
		if result.dnf { return "DNF" }
		return "Classificado"
	}

	private struct CachedBrief {
		let brief: HomeSessionBrief
		let context: String
	}
}

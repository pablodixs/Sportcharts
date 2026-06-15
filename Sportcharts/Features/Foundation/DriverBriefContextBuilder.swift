//
//  DriverBriefContextBuilder.swift
//  Sportcharts
//
//  Created by Codex on 15/06/26.
//

import Foundation

enum DriverBriefContextBuilder {
	static func makeContext(
		driver: F1Driver,
		sessions: [Session],
		results: [(Session, SessionResult)],
		standings: [DriverStanding]
	) -> String {
		let completedSessions = sessions.filter {
			!$0.isFuture && !$0.isCancelled
		}
		
		let resultLines = results.map { session, result in
			let position = result.position.map { "P\($0)" } ?? "--"
			let gap = gapText(result)
			let points = result.points > 0 ? "\(result.points) pts" : "sem pontos"
			let status = statusText(result)
			
			return "- \(session.countryName) \(session.sessionName): \(position), \(points), \(result.numberOfLaps) voltas, gap \(gap), \(status)"
		}
		
		let pointsScored = results.reduce(0) { partialResult, item in
			partialResult + item.1.points
		}
		
		let positions = results.compactMap { $0.1.position }
		let bestPosition = positions.min().map { "P\($0)" } ?? "--"
		let worstPosition = positions.max().map { "P\($0)" } ?? "--"
		let issueCount = results.filter {
			$0.1.dnf || $0.1.dns || $0.1.dsq
		}.count
		
		let standingText = standings.first.map { standing in
			let delta = standing.positionStart - standing.positionCurrent
			let deltaText: String
			
			if delta > 0 {
				deltaText = "ganhou \(delta) posição(ões)"
			} else if delta < 0 {
				deltaText = "perdeu \(abs(delta)) posição(ões)"
			} else {
				deltaText = "manteve posição"
			}
			
			return "Classificação: P\(standing.positionCurrent), \(standing.pointsCurrent) pts, \(deltaText) desde o início da sessão."
		} ?? "Classificação: indisponível para as sessões recentes."
		
		return """
		Piloto:
		Nome: \(driver.fullName)
		Número: \(driver.number)
		Equipe: \(driver.team.rawValue)
		Nacionalidade: \(driver.nationalityName)
		Status: \(driver.isRookie ? "rookie" : "titular")
		
		Resumo numérico recente:
		Sessões de \(Calendar.current.component(.year, from: .now)) carregadas: \(sessions.count)
		Sessões já realizadas: \(completedSessions.count)
		Resultados recentes encontrados: \(results.count)
		Pontos somados nos resultados recentes: \(pointsScored)
		Melhor posição recente: \(bestPosition)
		Pior posição recente: \(worstPosition)
		Resultados com DNF/DNS/DSQ: \(issueCount)
		\(standingText)
		
		Resultados recentes:
		\(resultLines.isEmpty ? "- Sem resultados recentes publicados para este piloto." : resultLines.joined(separator: "\n"))
		
		Use apenas esses dados. Se os dados forem insuficientes, diga isso claramente.
		"""
	}
	
	static func fallbackBrief(
		driver: F1Driver,
		sessions: [Session],
		results: [(Session, SessionResult)],
		standings: [DriverStanding]
	) -> DriverBrief {
		let context = makeContext(
			driver: driver,
			sessions: sessions,
			results: results,
			standings: standings
		)
		
		guard !results.isEmpty else {
			return DriverBrief(
				headline: "Ainda faltam dados recentes para \(driver.lastName).",
				formSummary: "A OpenF1 ainda não retornou resultados recentes suficientes para montar uma leitura confiável de forma.",
				strengths: ["Base de perfil e equipe já disponível"],
				watchouts: ["Aguardar resultados publicados das próximas sessões"]
			)
		}
		
		let points = results.reduce(0) { $0 + $1.1.points }
		let positions = results.compactMap { $0.1.position }
		let best = positions.min().map { "P\($0)" } ?? "--"
		let worst = positions.max().map { "P\($0)" } ?? "--"
		let issueCount = results.filter {
			$0.1.dnf || $0.1.dns || $0.1.dsq
		}.count
		
		let headline = points > 0
			? "\(driver.lastName) somou \(points) ponto(s) recentemente."
			: "\(driver.lastName) busca transformar ritmo em pontos."
		
		let formSummary = """
		Nos dados recentes encontrados, \(driver.fullName) aparece em \(results.count) sessão(ões), com melhor resultado \(best) e pior resultado \(worst). \(context.contains("Classificação: P") ? "Há dados de classificação disponíveis para contextualizar a fase." : "A classificação recente não estava disponível no recorte consultado.")
		"""
		
		var strengths = [
			"Melhor posição recente: \(best)",
			"Pontos recentes: \(points)",
		]
		
		if issueCount == 0 {
			strengths.append("Sem DNF/DNS/DSQ no recorte recente")
		}
		
		var watchouts = [
			"Pior posição recente: \(worst)",
		]
		
		if issueCount > 0 {
			watchouts.append("\(issueCount) resultado(s) com DNF/DNS/DSQ")
		} else {
			watchouts.append("Comparar com o companheiro para medir ritmo relativo")
		}
		
		return DriverBrief(
			headline: headline,
			formSummary: formSummary,
			strengths: Array(strengths.prefix(3)),
			watchouts: Array(watchouts.prefix(3))
		)
	}
	
	private static func statusText(_ result: SessionResult) -> String {
		if result.dsq { return "DSQ" }
		if result.dns { return "DNS" }
		if result.dnf { return "DNF" }
		return "classificado"
	}
	
	private static func gapText(_ result: SessionResult) -> String {
		switch result.gapToLeader {
		case .seconds(let seconds):
			return seconds == 0 ? "líder" : "+\(String(format: "%.3f", seconds))s"
		case .laps(let laps):
			return laps
		case nil:
			return "--"
		}
	}
}

//
//  SessionSmartQuestionBuilder.swift
//  Sportcharts
//
//  Created by Codex on 15/06/26.
//

import Foundation

enum SessionSmartQuestionBuilder {
	static func questions(from context: String) -> [String] {
		let winner = value(after: "Posição: 1", label: "Piloto:", in: context)
		let second = value(after: "Posição: 2", label: "Piloto:", in: context)
		let hasStints = context.contains("Pneus e stints:")
		let hasWeather = context.contains("Clima:")
		let hasRaceControl = context.contains("Race control:")
		let fastestDriver = fastestLapDriver(from: context)
		
		var questions: [String] = []
		
		if let winner {
			questions.append("O que decidiu a sessão para \(lastName(winner))?")
		}
		
		if let winner, let second {
			questions.append("Onde \(lastName(winner)) abriu vantagem sobre \(lastName(second))?")
		}
		
		if hasStints {
			questions.append("Como a estratégia de pneus influenciou o resultado?")
		}
		
		if let fastestDriver {
			questions.append("Por que \(lastName(fastestDriver)) apareceu forte em ritmo de volta?")
		}
		
		if hasRaceControl {
			questions.append("Quais eventos de pista mudaram a leitura da sessão?")
		}
		
		if hasWeather {
			questions.append("O clima teve impacto relevante no desempenho?")
		}
		
		questions.append("Quem superou mais as expectativas nesta sessão?")
		questions.append("Qual foi o principal ponto de atenção para a próxima sessão?")
		
		return Array(unique(questions).prefix(3))
	}
	
	private static func value(
		after marker: String,
		label: String,
		in text: String
	) -> String? {
		guard let markerRange = text.range(of: marker) else {
			return nil
		}
		
		let suffix = text[markerRange.upperBound...]
		guard let line = suffix
			.split(separator: "\n")
			.map(String.init)
			.first(where: {
				$0.trimmingCharacters(in: .whitespaces).hasPrefix(label)
			})
		else {
			return nil
		}
		
		return line
			.replacingOccurrences(of: label, with: "")
			.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	private static func fastestLapDriver(from context: String) -> String? {
		guard let range = context.range(of: "Voltas rápidas:") else {
			return nil
		}
		
		let suffix = context[range.upperBound...]
		guard let firstLine = suffix
			.split(separator: "\n")
			.map(String.init)
			.first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("- ") })
		else {
			return nil
		}
		
		let cleaned = firstLine
			.replacingOccurrences(of: "- ", with: "")
			.trimmingCharacters(in: .whitespacesAndNewlines)
		
		return cleaned
			.split(separator: ":")
			.first
			.map(String.init)
	}
	
	private static func lastName(_ name: String) -> String {
		name
			.split(separator: " ")
			.last
			.map(String.init) ?? name
	}
	
	private static func unique(_ questions: [String]) -> [String] {
		var seen = Set<String>()
		
		return questions.filter { question in
			seen.insert(question.lowercased()).inserted
		}
	}
}

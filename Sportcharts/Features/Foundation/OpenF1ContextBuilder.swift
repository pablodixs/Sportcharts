//
//  OpenF1ContextBuilder.swift
//  Sportcharts
//
//  Created by Codex on 15/06/26.
//

import Foundation

enum OpenF1ContextBuilder {
	static func sessionInsights(
		laps: [Lap],
		stints: [Stint],
		weather: [Weather],
		raceControl: [RaceControlEvent],
		maxDrivers: Int = 8
	) -> String {
		var sections: [String] = []
		
		let bestLapText = bestLaps(laps, maxDrivers: maxDrivers)
		if !bestLapText.isEmpty {
			sections.append("""
			Voltas rápidas:
			\(bestLapText)
			""")
		}
		
		let stintText = stintSummary(stints, maxDrivers: maxDrivers)
		if !stintText.isEmpty {
			sections.append("""
			Pneus e stints:
			\(stintText)
			""")
		}
		
		if let weatherText = weatherSummary(weather) {
			sections.append("""
			Clima:
			\(weatherText)
			""")
		}
		
		let raceControlText = raceControlSummary(raceControl)
		if !raceControlText.isEmpty {
			sections.append("""
			Race control:
			\(raceControlText)
			""")
		}
		
		guard !sections.isEmpty else {
			return ""
		}
		
		return """
		Contexto adicional leve da OpenF1:
		
		\(sections.joined(separator: "\n\n"))
		"""
	}
	
	static func recentDriverResults(
		driver: F1Driver,
		sessions: [Session],
		resultsBySession: [(Session, SessionResult)]
	) -> String {
		guard !resultsBySession.isEmpty else {
			return ""
		}
		
		let lines = resultsBySession.map { session, result in
			let position = result.position.map { "P\($0)" } ?? "--"
			let points = result.points > 0 ? ", \(result.points) pts" : ""
			let status = statusText(result)
			let gap = gapText(result)
			
			return "- \(session.countryName) \(session.sessionName): \(position), \(result.numberOfLaps) voltas\(points), gap \(gap), status \(status)"
		}
		
		let completedSessions = sessions.filter { !$0.isFuture && !$0.isCancelled }
		
		return """
		Contexto recente da OpenF1 para \(driver.fullName):
		Sessões de 2026 carregadas: \(sessions.count), já realizadas: \(completedSessions.count).
		Resultados recentes:
		\(lines.joined(separator: "\n"))
		"""
	}
	
	private static func bestLaps(
		_ laps: [Lap],
		maxDrivers: Int
	) -> String {
		let validLaps = laps.filter {
			$0.lapDuration != nil && $0.isPitOutLap != true
		}
		
		let bestByDriver = Dictionary(grouping: validLaps, by: \.driverNumber)
			.compactMap { driverNumber, laps -> Lap? in
				laps.min {
					($0.lapDuration ?? .greatestFiniteMagnitude)
						< ($1.lapDuration ?? .greatestFiniteMagnitude)
				}
			}
			.sorted {
				($0.lapDuration ?? .greatestFiniteMagnitude)
					< ($1.lapDuration ?? .greatestFiniteMagnitude)
			}
			.prefix(maxDrivers)
		
		return bestByDriver.map { lap in
			let driver = F1Grid2026.driver(byNumber: lap.driverNumber)
			let name = driver?.abbreviation ?? "#\(lap.driverNumber)"
			let time = formatSeconds(lap.lapDuration)
			let sectors = [
				formatSeconds(lap.durationSector1),
				formatSeconds(lap.durationSector2),
				formatSeconds(lap.durationSector3),
			].joined(separator: "/")
			let speed = lap.stSpeed.map { ", speed trap \($0) km/h" } ?? ""
			
			return "- \(name): volta \(lap.lapNumber), \(time), setores \(sectors)\(speed)"
		}
		.joined(separator: "\n")
	}
	
	private static func stintSummary(
		_ stints: [Stint],
		maxDrivers: Int
	) -> String {
		let grouped = Dictionary(grouping: stints, by: \.driverNumber)
		
		return grouped
			.keys
			.sorted()
			.prefix(maxDrivers)
			.compactMap { driverNumber in
				guard let driverStints = grouped[driverNumber] else {
					return nil
				}
				
				let driver = F1Grid2026.driver(byNumber: driverNumber)
				let name = driver?.abbreviation ?? "#\(driverNumber)"
				let parts = driverStints
					.sorted { $0.stintNumber < $1.stintNumber }
					.map { stint in
						let compound = stint.compound ?? "UNKNOWN"
						let start = stint.lapStart.map(String.init) ?? "?"
						let end = stint.lapEnd.map(String.init) ?? "?"
						let age = stint.tyreAgeAtStart.map { ", idade \($0)" } ?? ""
						
						return "\(compound) L\(start)-\(end)\(age)"
					}
					.joined(separator: " | ")
				
				return "- \(name): \(parts)"
			}
			.joined(separator: "\n")
	}
	
	private static func weatherSummary(_ weather: [Weather]) -> String? {
		guard !weather.isEmpty else {
			return nil
		}
		
		let first = weather.first
		let last = weather.last
		let rainfallCount = weather.filter { ($0.rainfall ?? 0) > 0 }.count
		
		let track = rangeText(
			weather.compactMap(\.trackTemperature),
			unit: "C"
		)
		let air = rangeText(
			weather.compactMap(\.airTemperature),
			unit: "C"
		)
		let humidity = rangeText(
			weather.compactMap { $0.humidity.map(Double.init) },
			unit: "%"
		)
		let wind = rangeText(
			weather.compactMap(\.windSpeed),
			unit: "m/s"
		)
		
		let finalRain = (last?.rainfall ?? first?.rainfall ?? 0) > 0
			? "sim"
			: "não"
		
		return "pista \(track), ar \(air), umidade \(humidity), vento \(wind), chuva em \(rainfallCount) amostras, chuva no fim: \(finalRain)"
	}
	
	private static func raceControlSummary(
		_ raceControl: [RaceControlEvent]
	) -> String {
		let important = raceControl
			.filter { event in
				guard let message = event.message?.trimmingCharacters(
					in: .whitespacesAndNewlines
				), !message.isEmpty else {
					return false
				}
				
				let category = event.category?.lowercased() ?? ""
				let flag = event.flag?.lowercased() ?? ""
				
				return category.contains("flag")
					|| category.contains("safety")
					|| category.contains("car")
					|| flag.contains("yellow")
					|| flag.contains("red")
					|| flag.contains("black")
			}
			.suffix(8)
		
		return important.map { event in
			let lap = event.lapNumber.map { "L\($0)" } ?? "sem volta"
			let driver = event.driverNumber.map { " carro \($0)" } ?? ""
			let flag = event.flag.map { " \($0)" } ?? ""
			let message = event.message ?? ""
			
			return "- \(lap)\(driver)\(flag): \(message)"
		}
		.joined(separator: "\n")
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
	
	private static func rangeText(_ values: [Double], unit: String) -> String {
		guard let min = values.min(), let max = values.max() else {
			return "--"
		}
		
		return "\(formatNumber(min))-\(formatNumber(max)) \(unit)"
	}
	
	private static func formatSeconds(_ value: Double?) -> String {
		guard let value else {
			return "--"
		}
		
		let minutes = Int(value) / 60
		let seconds = value - Double(minutes * 60)
		
		if minutes > 0 {
			return String(format: "%d:%06.3f", minutes, seconds)
		}
		
		return String(format: "%.3fs", value)
	}
	
	private static func formatNumber(_ value: Double) -> String {
		String(format: "%.1f", value)
	}
}

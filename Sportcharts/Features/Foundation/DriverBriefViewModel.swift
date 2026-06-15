//
//  DriverBriefViewModel.swift
//  Sportcharts
//
//  Created by Codex on 15/06/26.
//

import Foundation
import FoundationModels
import Observation

@MainActor
@Observable
final class DriverBriefViewModel {
	enum State: Equatable {
		case idle
		case loading
		case success
		case failure(String)
	}
	
	private(set) var state: State = .idle
	private(set) var brief: DriverBrief?
	
	private let service: OpenF1Service
	private static var cache: [Int: DriverBrief] = [:]
	
	private let maxSessionsToInspect = 8
	private let maxResultsToCollect = 4
	
	private let modelInstructions = """
	Você é um analista técnico de Fórmula 1.
	Responda em português do Brasil.
	Use somente os dados fornecidos.
	Se os dados forem insuficientes, deixe isso claro sem inventar justificativas.
	Seja útil, objetivo e específico.
	"""
	
	init(service: OpenF1Service = OpenF1Service()) {
		self.service = service
	}
	
	func loadBrief(for driver: F1Driver) async {
		if let cached = Self.cache[driver.number] {
			brief = cached
			state = .success
			return
		}
		
		state = .loading
		
		let year = Calendar.current.component(.year, from: .now)
		
		do {
			let sessions = try await service.fetchSessionsByYear(year: year)
			let completedSessions = sessions
				.filter { !$0.isFuture && !$0.isCancelled }
				.sorted { $0.dateStart > $1.dateStart }
			
			var driverResults: [(Session, SessionResult)] = []
			var standings: [DriverStanding] = []
			
			for session in completedSessions.prefix(maxSessionsToInspect) {
				guard driverResults.count < maxResultsToCollect else {
					break
				}
				
				guard
					let results = try? await service.fetchSessionResult(
						sessionKey: session.sessionKey
					),
					let result = results.first(where: {
						$0.driverNumber == driver.number
					})
				else {
					continue
				}
				
				driverResults.append((session, result))
				
				if standings.isEmpty,
				   let driverStandings = try? await service.fetchDriverStandingsBySession(
					key: session.sessionKey,
					driverNumber: driver.number
				   ) {
					standings = driverStandings
				}
			}
			
			let generatedBrief = await makeBrief(
				driver: driver,
				sessions: sessions,
				results: driverResults,
				standings: standings
			)
			
			brief = generatedBrief
			Self.cache[driver.number] = generatedBrief
			state = .success
		} catch {
			let fallback = DriverBriefContextBuilder.fallbackBrief(
				driver: driver,
				sessions: [],
				results: [],
				standings: []
			)
			
			brief = fallback
			Self.cache[driver.number] = fallback
			state = .success
		}
	}
	
	func reset() {
		state = .idle
		brief = nil
	}
	
	private func makeBrief(
		driver: F1Driver,
		sessions: [Session],
		results: [(Session, SessionResult)],
		standings: [DriverStanding]
	) async -> DriverBrief {
		let fallback = DriverBriefContextBuilder.fallbackBrief(
			driver: driver,
			sessions: sessions,
			results: results,
			standings: standings
		)
		
		guard !results.isEmpty else {
			return fallback
		}
		
		guard case .available = SystemLanguageModel.default.availability else {
			return fallback
		}
		
		do {
			let context = DriverBriefContextBuilder.makeContext(
				driver: driver,
				sessions: sessions,
				results: results,
				standings: standings
			)
			
			let session = LanguageModelSession(instructions: modelInstructions)
			let response = try await session.respond(
				to: """
				Gere um brief de performance do piloto com base no contexto abaixo.
				Mantenha tudo curto e ancorado nos números.
				
				\(context)
				""",
				generating: DriverBrief.self
			)
			
			return sanitize(response.content, fallback: fallback)
		} catch {
			return fallback
		}
	}
	
	private func sanitize(
		_ brief: DriverBrief,
		fallback: DriverBrief
	) -> DriverBrief {
		var sanitized = brief
		
		sanitized.headline = clean(brief.headline)
		if sanitized.headline.isEmpty {
			sanitized.headline = fallback.headline
		}
		
		sanitized.formSummary = clean(brief.formSummary)
		if sanitized.formSummary.isEmpty {
			sanitized.formSummary = fallback.formSummary
		}
		
		sanitized.strengths = sanitizedList(
			brief.strengths,
			fallback: fallback.strengths,
			limit: 3
		)
		
		sanitized.watchouts = sanitizedList(
			brief.watchouts,
			fallback: fallback.watchouts,
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
			.filter { value in
				seen.insert(value.lowercased()).inserted
			}
		
		let source = cleaned.isEmpty ? fallback : cleaned
		return Array(source.prefix(limit))
	}
	
	private func clean(_ text: String) -> String {
		text
			.replacingOccurrences(of: "\n", with: " ")
			.replacingOccurrences(of: "  ", with: " ")
			.trimmingCharacters(in: .whitespacesAndNewlines)
	}
}

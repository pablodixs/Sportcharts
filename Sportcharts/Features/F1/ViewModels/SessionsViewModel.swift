//
//  DriversViewModel.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/03/26.
//

import Foundation
import SwiftUI

@Observable
final class SessionsViewModel {

	enum State: Equatable {
		case idle
		case loading
		case success
		case failure(String)
	}

	private(set) var results: [SessionResult] = []
	private(set) var sessions: [Session] = []
	private(set) var session: [Session] = []
	private(set) var sessionInsights: String = ""
	private(set) var didLoadSessionInsights = false

	private(set) var state: State = .idle

	private let service: OpenF1Service

	init(service: OpenF1Service = OpenF1Service()) {
		self.service = service
	}

	var meetingGroups: [MeetingGroup] {
		let grouped = Dictionary(grouping: sessions, by: \.meetingKey)

		return grouped.map { meetingKey, sessions in
			let first = sessions[0]
			return MeetingGroup(
				id: meetingKey,
				location: first.location,
				countryName: first.countryName,
				year: first.year,
				sessions: sessions.sorted { $0.dateStart < $1.dateStart }
			)
		}
		.sorted {
			$0.sessions.first?.dateStart ?? "" < $1.sessions.first?.dateStart
			?? ""
		}
	}

	var currentMeetingID: Int? {
		currentSession?.meetingKey
	}

	var currentSessionID: Int? {
		currentSession?.sessionKey
	}

	private var currentSession: Session? {
		let now = Date()
		let availableSessions = sessions
			.filter { !$0.isCancelled }
			.sorted { lhs, rhs in
				guard
					let lhsDate = sessionDate(lhs.dateStart),
					let rhsDate = sessionDate(rhs.dateStart)
				else {
					return lhs.dateStart < rhs.dateStart
				}

				return lhsDate < rhsDate
			}

		if let liveSession = availableSessions.first(where: { session in
			guard
				let startDate = sessionDate(session.dateStart),
				let endDate = sessionDate(session.dateEnd)
			else {
				return false
			}

			return startDate <= now && now <= endDate
		}) {
			return liveSession
		}

		if let nextSession = availableSessions.first(where: { session in
			guard let startDate = sessionDate(session.dateStart) else {
				return false
			}

			return startDate > now
		}) {
			return nextSession
		}

		return availableSessions.last
	}

	var previousSession: Session? {
		let now = Date()
		let formatter = ISO8601DateFormatter()

		return sessions
			.filter { session in
				guard !session.isCancelled,
					  let startDate = formatter.date(from: session.dateStart)
				else {
					return false
				}

				return startDate < now
			}
			.max { lhs, rhs in
				guard
					let lhsDate = formatter.date(from: lhs.dateStart),
					let rhsDate = formatter.date(from: rhs.dateStart)
				else {
					return false
				}

				return lhsDate < rhsDate
			}
	}

	var nextSession: Session? {
		let now = Date()
		let formatter = ISO8601DateFormatter()

		return sessions
			.filter { session in
				guard
					!session.isCancelled,
					let startDate = formatter.date(from: session.dateStart)
				else {
					return false
				}

				return startDate > now
			}
			.min { lhs, rhs in
				guard
					let lhsDate = formatter.date(from: lhs.dateStart),
					let rhsDate = formatter.date(from: rhs.dateStart)
				else {
					return false
				}

				return lhsDate < rhsDate
			}
	}

	func loadSessionResults(sessionKey: Int) async {
		state = .loading
		do {
			results = try await service.fetchSessionResult(
				sessionKey: sessionKey
			)
			state = .success
		} catch {
			state = .failure(error.localizedDescription)
		}
	}

	func loadSessionsByYear(year: Int) async {
		state = .loading
		do {
			sessions = try await service.fetchSessionsByYear(year: year)
			state = .success
		} catch {
			state = .failure(error.localizedDescription)
		}
	}

	func loadSessionByKey(key: Int) async {
		state = .loading
		do {
			session = try await service.fetchSessionByKey(key: key)
			state = .success
		} catch {
			state = .failure(error.localizedDescription)
		}
	}

	func loadSessionInsights(sessionKey: Int) async {
		guard !didLoadSessionInsights else {
			return
		}

		let laps = (try? await service.fetchLaps(sessionKey: sessionKey)) ?? []
		let stints = (try? await service.fetchStints(sessionKey: sessionKey)) ?? []
		let weather = (try? await service.fetchWeather(sessionKey: sessionKey)) ?? []
		let raceControl = (try? await service.fetchRaceControl(sessionKey: sessionKey)) ?? []

		sessionInsights = OpenF1ContextBuilder.sessionInsights(
			laps: laps,
			stints: stints,
			weather: weather,
			raceControl: raceControl
		)
		didLoadSessionInsights = true
	}

	func reset() {
		results = []
		sessionInsights = ""
		didLoadSessionInsights = false
		state = .idle
	}

	private func sessionDate(_ value: String) -> Date? {
		Self.isoFormatter.date(from: value)
			?? Self.isoFracFormatter.date(from: value)
	}

	private static let isoFormatter: ISO8601DateFormatter = {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime]
		return formatter
	}()

	private static let isoFracFormatter: ISO8601DateFormatter = {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
		return formatter
	}()
}

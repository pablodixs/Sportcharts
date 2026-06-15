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
		let now = Date()
		let formatter = ISO8601DateFormatter()
		
		return meetingGroups.first { group in
			guard let lastSession = group.sessions.last,
				  let endDate = formatter.date(from: lastSession.dateEnd)
			else {
				return false
			}
			return endDate >= now
		}?.id
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
	
	func reset() {
		results = []
		state = .idle
	}
}

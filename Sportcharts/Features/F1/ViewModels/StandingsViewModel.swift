//
//  StandingsViewModel.swift
//  Sportcharts
//
//  Created by Pablo Dias on 19/05/26.
//

import Foundation

@Observable
final class StandingsViewModel {
	enum State: Equatable {
		case idle
		case loading
		case success
		case failure(String)
	}
	
	private(set) var state: State = .idle
	
	private(set) var driversStadings: [DriverStanding] = []
	
	private let service: OpenF1Service
	
	init(service: OpenF1Service = OpenF1Service()) {
		self.service = service
	}
	
	func loadDriversStandings(sessionKey: Int) async {
		state = .loading
		
		do {
			driversStadings = try await service.fetchDriverStandingsBySession(key: sessionKey)
			state = .success
		} catch {
			state = .failure(error.localizedDescription)
		}
	}
	
	func reset() {
		driversStadings = []
		state = .idle
	}
}


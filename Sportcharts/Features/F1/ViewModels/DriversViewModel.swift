//
//  DriversViewModel.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/03/26.
//

import Foundation
import SwiftUI

@Observable
final class DriversViewModel {

	enum State: Equatable {
		case idle
		case loading
		case success
		case failure(String)
	}

	private(set) var drivers: [Driver] = []
	private(set) var selectedDriver: Driver?
	private(set) var state: State = .idle

	var hasDrivers: Bool { !drivers.isEmpty }

	private let service: OpenF1Service

	init(service: OpenF1Service = OpenF1Service()) {
		self.service = service
	}

	func loadDrivers(sessionKey: Int) async {
		state = .loading
		do {
			drivers = try await service.fetchDrivers(sessionKey: sessionKey)
			state = .success
		} catch {
			state = .failure(error.localizedDescription)
		}
	}

	func loadDriver(driverNumber: Int, sessionKey: Int) async {
		state = .loading
		do {
			let results = try await service.fetchDrivers(
				driverNumber: driverNumber,
				sessionKey: sessionKey
			)
			withAnimation {
				selectedDriver = results.first
				state = .success
			}
		} catch {
			state = .failure(error.localizedDescription)
		}
	}

	func driver(by number: Int) -> Driver? {
		drivers.first(where: { $0.driver_number == number })
	}

	func reset() {
		drivers = []
		selectedDriver = nil
		state = .idle
	}
}

//
//  OpenF1Service.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/03/26.
//


final class OpenF1Service {

    private let client: HTTPClient

    init(client: HTTPClient = .shared) {
        self.client = client
    }

    func fetchDrivers(driverNumber: Int? = nil, sessionKey: Int? = nil) async throws -> [Driver] {
        try await client.fetch(OpenF1Endpoint.drivers(driverNumber: driverNumber, sessionKey: sessionKey))
    }

	func fetchSessionsByMeeting(meetingKey: Int? = nil) async throws -> [Session] {
		try await client.fetch(OpenF1Endpoint.sessions(meetingKey: meetingKey))
    }
	
	func fetchSessionResult(sessionKey: Int) async throws -> [SessionResult] {
		try await client.fetch(OpenF1Endpoint.sessionResult(sessionKey: sessionKey))
	}
	
	func fetchSessionsByYear(year: Int) async throws -> [Session] {
		try await client.fetch(OpenF1Endpoint.sessions(year: year))
	}
	
	func fetchSessionByKey(key: Int) async throws -> [Session] {
		try await client.fetch(OpenF1Endpoint.sessions(key: key))
	}
	
	func fetchDriverStandingsBySession(key: Int) async throws -> [DriverStanding] {
		try await client.fetch(OpenF1Endpoint.driversStandings(sessionKey: key))
	}

//
//    func fetchLaps(sessionKey: Int, driverNumber: Int? = nil) async throws -> [Lap] {
//        try await client.fetch(.laps(sessionKey: sessionKey, driverNumber: driverNumber))
//    }
//
//    func fetchWeather(sessionKey: Int) async throws -> [Weather] {
//        try await client.fetch(.weather(sessionKey: sessionKey))
//    }

    // demais endpoints seguem o mesmo padrão...
}

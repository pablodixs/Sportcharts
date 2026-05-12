//
//  OpenF1Requestable.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/03/26.
//

import Foundation

protocol OpenF1Requestable {
	var path: String { get }
	var queryItems: [URLQueryItem] { get }
}

enum OpenF1Endpoint: OpenF1Requestable {
	case drivers(driverNumber: Int? = nil, sessionKey: Int? = nil)
	case sessions(meetingKey: Int? = nil, year: Int? = nil, key: Int? = nil)
	case laps(sessionKey: Int, driverNumber: Int? = nil)
	case positions(sessionKey: Int, driverNumber: Int? = nil)
	case intervals(sessionKey: Int, driverNumber: Int? = nil)
	case carData(sessionKey: Int, driverNumber: Int? = nil)
	case stints(sessionKey: Int, driverNumber: Int? = nil)
	case weather(sessionKey: Int)
	case raceControl(sessionKey: Int)
	case meetings(year: Int? = nil)
	case sessionResult(sessionKey: Int)

	var path: String {
		switch self {
		case .drivers: return "/v1/drivers"
		case .sessions: return "/v1/sessions"
		case .laps: return "/v1/laps"
		case .positions: return "/v1/position"
		case .intervals: return "/v1/intervals"
		case .carData: return "/v1/car_data"
		case .stints: return "/v1/stints"
		case .weather: return "/v1/weather"
		case .raceControl: return "/v1/race_control"
		case .meetings: return "/v1/meetings"
		case .sessionResult: return "/v1/session_result"
		}
	}

	var queryItems: [URLQueryItem] {
		switch self {
		case .drivers(let driverNumber, let sessionKey):
			return build(
				("driver_number", driverNumber),
				("session_key", sessionKey)
			)
		case .sessions(let meetingKey, let year, let key):
			return build(
				("meeting_key", meetingKey),
				("year", year),
				("session_key", key)
			)
			
		case .laps(let sessionKey, let driverNumber):
			return build(
				("session_key", sessionKey),
				("driver_number", driverNumber)
			)
		case .positions(let sessionKey, let driverNumber):
			return build(
				("session_key", sessionKey),
				("driver_number", driverNumber)
			)
		case .intervals(let sessionKey, let driverNumber):
			return build(
				("session_key", sessionKey),
				("driver_number", driverNumber)
			)
		case .carData(let sessionKey, let driverNumber):
			return build(
				("session_key", sessionKey),
				("driver_number", driverNumber)
			)
		case .stints(let sessionKey, let driverNumber):
			return build(
				("session_key", sessionKey),
				("driver_number", driverNumber)
			)
		case .weather(let sessionKey):
			return build(("session_key", sessionKey))
		case .raceControl(let sessionKey):
			return build(("session_key", sessionKey))
		case .meetings(let year):
			return build(("year", year))
		case .sessionResult(let sessionKey):
			return build(("session_key", sessionKey))
		}
	}

	private func build(_ pairs: (String, (any CustomStringConvertible)?)...)
		-> [URLQueryItem]
	{
		pairs.compactMap { key, value in
			value.map { URLQueryItem(name: key, value: "\($0)") }
		}
	}
}

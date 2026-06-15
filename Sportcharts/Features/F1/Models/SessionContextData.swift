//
//  SessionContextData.swift
//  Sportcharts
//
//  Created by Codex on 15/06/26.
//

import Foundation

struct Lap: Decodable, Hashable {
	let dateStart: String?
	let driverNumber: Int
	let durationSector1: Double?
	let durationSector2: Double?
	let durationSector3: Double?
	let i1Speed: Int?
	let i2Speed: Int?
	let isPitOutLap: Bool?
	let lapDuration: Double?
	let lapNumber: Int
	let meetingKey: Int
	let sessionKey: Int
	let stSpeed: Int?
	
	enum CodingKeys: String, CodingKey {
		case dateStart = "date_start"
		case driverNumber = "driver_number"
		case durationSector1 = "duration_sector_1"
		case durationSector2 = "duration_sector_2"
		case durationSector3 = "duration_sector_3"
		case i1Speed = "i1_speed"
		case i2Speed = "i2_speed"
		case isPitOutLap = "is_pit_out_lap"
		case lapDuration = "lap_duration"
		case lapNumber = "lap_number"
		case meetingKey = "meeting_key"
		case sessionKey = "session_key"
		case stSpeed = "st_speed"
	}
}

struct Stint: Decodable, Hashable {
	let compound: String?
	let driverNumber: Int
	let lapEnd: Int?
	let lapStart: Int?
	let meetingKey: Int
	let sessionKey: Int
	let stintNumber: Int
	let tyreAgeAtStart: Int?
	
	enum CodingKeys: String, CodingKey {
		case compound
		case driverNumber = "driver_number"
		case lapEnd = "lap_end"
		case lapStart = "lap_start"
		case meetingKey = "meeting_key"
		case sessionKey = "session_key"
		case stintNumber = "stint_number"
		case tyreAgeAtStart = "tyre_age_at_start"
	}
}

struct Weather: Decodable, Hashable {
	let airTemperature: Double?
	let date: String
	let humidity: Int?
	let meetingKey: Int
	let pressure: Double?
	let rainfall: Int?
	let sessionKey: Int
	let trackTemperature: Double?
	let windDirection: Int?
	let windSpeed: Double?
	
	enum CodingKeys: String, CodingKey {
		case airTemperature = "air_temperature"
		case date
		case humidity
		case meetingKey = "meeting_key"
		case pressure
		case rainfall
		case sessionKey = "session_key"
		case trackTemperature = "track_temperature"
		case windDirection = "wind_direction"
		case windSpeed = "wind_speed"
	}
}

struct RaceControlEvent: Decodable, Hashable {
	let category: String?
	let date: String
	let driverNumber: Int?
	let flag: String?
	let lapNumber: Int?
	let meetingKey: Int
	let message: String?
	let qualifyingPhase: Int?
	let scope: String?
	let sector: Int?
	let sessionKey: Int
	
	enum CodingKeys: String, CodingKey {
		case category
		case date
		case driverNumber = "driver_number"
		case flag
		case lapNumber = "lap_number"
		case meetingKey = "meeting_key"
		case message
		case qualifyingPhase = "qualifying_phase"
		case scope
		case sector
		case sessionKey = "session_key"
	}
}

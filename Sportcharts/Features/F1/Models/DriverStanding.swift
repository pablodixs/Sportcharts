//
//  DriverStanding.swift
//  Sportcharts
//
//  Created by Pablo Dias on 19/05/26.
//

import Foundation

struct DriverStanding: Decodable, Hashable, Identifiable {
	var id: Int { driverNumber }
	let meetingKey: Int
	let sessionKey: Int
	let driverNumber: Int
	let positionStart: Int
	let positionCurrent: Int
	let pointsStart: Int
	let pointsCurrent: Int
	
	enum CodingKeys: String, CodingKey {
		case meetingKey = "meeting_key"
		case sessionKey = "session_key"
		case driverNumber = "driver_number"
		case positionStart = "position_start"
		case positionCurrent = "position_current"
		case pointsStart = "points_start"
		case pointsCurrent = "points_current"
	}
}

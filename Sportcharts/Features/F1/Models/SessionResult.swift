//
//  SessionResult.swift
//  Sportcharts
//
//  Created by Pablo Dias on 30/03/26.
//

import Foundation

struct SessionResult: Decodable, Hashable {
	let position: Int?
	let driverNumber: Int
	let numberOfLaps: Int
	let points: Int
	let dnf: Bool
	let dns: Bool
	let dsq: Bool
	let duration: Double?
	let gapToLeader: GapToLeader?
	let meetingKey: Int
	let sessionKey: Int

	enum CodingKeys: String, CodingKey {
		case position
		case driverNumber = "driver_number"
		case numberOfLaps = "number_of_laps"
		case points
		case dnf
		case dns
		case dsq
		case duration
		case gapToLeader = "gap_to_leader"
		case meetingKey = "meeting_key"
		case sessionKey = "session_key"
	}

	enum GapToLeader: Hashable {
		case seconds(Double)
		case laps(String)
	}

	var formattedDuration: String? {
		guard let duration else { return nil }
		let totalSeconds = Int(duration)
		let hours = totalSeconds / 3600
		let minutes = (totalSeconds % 3600) / 60
		let seconds = totalSeconds % 60
		let milliseconds = Int((duration - Double(totalSeconds)) * 1000)

		if hours > 0 {
			return String(format: "%d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
		} else {
			return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
		}
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		position = try container.decodeIfPresent(Int.self, forKey: .position)
		driverNumber = try container.decode(Int.self, forKey: .driverNumber)
		numberOfLaps = try container.decode(Int.self, forKey: .numberOfLaps)
		points = try container.decode(Int.self, forKey: .points)
		dnf = try container.decode(Bool.self, forKey: .dnf)
		dns = try container.decode(Bool.self, forKey: .dns)
		dsq = try container.decode(Bool.self, forKey: .dsq)
		duration = try container.decodeIfPresent(Double.self, forKey: .duration)
		meetingKey = try container.decode(Int.self, forKey: .meetingKey)
		sessionKey = try container.decode(Int.self, forKey: .sessionKey)

		if let seconds = try? container.decode(
			Double.self,
			forKey: .gapToLeader
		) {
			gapToLeader = .seconds(seconds)
		} else if let str = try? container.decode(
			String.self,
			forKey: .gapToLeader
		) {
			gapToLeader = .laps(str)
		} else {
			gapToLeader = nil
		}
	}
}

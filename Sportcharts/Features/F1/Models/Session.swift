//
//  Session.swift
//  Sportcharts
//
//  Created by Pablo Dias on 30/03/26.
//

import Foundation

struct Session: Decodable, Hashable, Identifiable {
	var id: Int { sessionKey }
	let sessionKey: Int
	let sessionType: String
	let sessionName: String
	let dateStart: String
	let dateEnd: String
	let meetingKey: Int
	let circuitKey: Int
	let circuitShortName: String
	let countryKey: Int
	let countryCode: String
	let countryName: String
	let location: String
	let gmtOffset: String
	let year: Int
	let isCancelled: Bool
	
	enum CodingKeys: String, CodingKey {
		case sessionKey = "session_key"
		case sessionType = "session_type"
		case sessionName = "session_name"
		case dateStart = "date_start"
		case dateEnd = "date_end"
		case meetingKey = "meeting_key"
		case circuitKey = "circuit_key"
		case circuitShortName = "circuit_short_name"
		case countryKey = "country_key"
		case countryCode = "country_code"
		case countryName = "country_name"
		case location
		case gmtOffset = "gmt_offset"
		case year
		case isCancelled = "is_cancelled"
	}

	var isFuture: Bool {
		guard let date = Self.isoFormatter.date(from: dateStart)
				?? Self.isoFracFormatter.date(from: dateStart)
		else { return true }
		return date > Date()
	}

	private static let isoFormatter: ISO8601DateFormatter = {
		let f = ISO8601DateFormatter()
		f.formatOptions = [.withInternetDateTime]
		return f
	}()

	private static let isoFracFormatter: ISO8601DateFormatter = {
		let f = ISO8601DateFormatter()
		f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
		return f
	}()

	private static func makeDisplayFormatter(timeZone: TimeZone = .current) -> DateFormatter {
		let f = DateFormatter()
		f.dateFormat = "dd/MM HH:mm"
		f.locale = Locale(identifier: "pt_BR")
		f.timeZone = timeZone
		return f
	}

	private var trackTimeZone: TimeZone? {
		let parts = gmtOffset.split(separator: ":")
		guard parts.count >= 2,
			  let hours = Int(parts[0]),
			  let minutes = Int(parts[1])
		else { return nil }
		let sign = hours < 0 ? -1 : 1
		let seconds = (abs(hours) * 3600 + minutes * 60) * sign
		return TimeZone(secondsFromGMT: seconds)
	}

	func formatted(_ isoString: String, useTrackTime: Bool) -> String {
		guard let date = Self.isoFormatter.date(from: isoString)
				?? Self.isoFracFormatter.date(from: isoString)
		else { return isoString }
		let tz = useTrackTime ? (trackTimeZone ?? .current) : .current
		let formatter = Self.makeDisplayFormatter(timeZone: tz)
		return formatter.string(from: date)
	}

	func formattedDateStart(useTrackTime: Bool) -> String { formatted(dateStart, useTrackTime: useTrackTime) }
	func formattedDateEnd(useTrackTime: Bool) -> String { formatted(dateEnd, useTrackTime: useTrackTime) }
}

struct MeetingGroup: Identifiable {
	let id: Int           // meeting_key
	let location: String
	let countryName: String
	let year: Int
	let sessions: [Session]
}

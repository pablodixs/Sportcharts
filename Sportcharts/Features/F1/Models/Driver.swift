//
//  Driver.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/03/26.
//

import Foundation

struct Driver: Codable, Hashable {
	let broadcast_name: String
	let driver_number: Int
	let first_name: String
	let full_name: String
	let headshot_url: String?
	let last_name: String
	let meeting_key: Int
	let name_acronym: String
	let session_key: Int
	let team_colour: String
	let team_name: String
}

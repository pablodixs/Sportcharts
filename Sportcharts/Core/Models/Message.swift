//
//  Message.swift
//  Sportcharts
//
//  Created by Pablo Dias on 11/05/26.
//

import Foundation

struct ChatMessage: Identifiable, Hashable, Codable {
	
	let id: UUID
	
	var role: Role
	
	var content: String
	
	var createdAt: Date
	
	var state: MessageState
	
	init(
		id: UUID = UUID(),
		role: Role,
		content: String,
		createdAt: Date = .now,
		state: MessageState = .sent
	) {
		self.id = id
		self.role = role
		self.content = content
		self.createdAt = createdAt
		self.state = state
	}
}

enum Role: String, Codable {
	case user
	case assistant
	case system
}

enum MessageState: Codable, Hashable {
	case sending
	case sent
	case typing
	case error
}

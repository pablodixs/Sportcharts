//
//  OllamaResponse.swift
//  Sportcharts
//
//  Created by Pablo Dias on 11/05/26.
//

import Foundation

struct OllamaMessage: Codable {
	let role: String
	let content: String
}

struct OllamaResponse: Codable {
	let message: OllamaMessage
}

struct OllamaRequest: Codable {
	let model: String
	let stream: Bool
	let messages: [OllamaMessage]
	let options: OllamaOptions
}

struct OllamaStreamResponse: Codable {
	let message: OllamaMessage?
	let done: Bool?
}

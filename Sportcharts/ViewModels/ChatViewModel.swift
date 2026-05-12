//
//  ChatViewModel.swift
//  Sportcharts
//
//  Created by Pablo Dias on 11/05/26.
//

import Foundation
import Observation
import SwiftUI

@Observable
final class ChatViewModel {

	var messages: [ChatMessage] = []

	var input: String = ""

	var isResponding = false

	private let service = OllamaService()

	func sendMessage(driver: F1Driver?) async {
		withAnimation {
			isResponding = true
		}
		
		let trimmedInput = input.trimmingCharacters(
			in: .whitespacesAndNewlines
		)
		
		guard !trimmedInput.isEmpty else {
			return
		}
		
		// USER MESSAGE
		
		let userMessage = ChatMessage(
			role: .user,
			content: trimmedInput,
			state: .sent
		)
		
		messages.append(userMessage)
		
		input = ""
		
		// TYPING MESSAGE
		
		let assistantMessage = ChatMessage(
			role: .assistant,
			content: "",
			state: .typing
		)
		
		messages.append(assistantMessage)
		
		guard let assistantIndex = messages.firstIndex(where: {
			$0.id == assistantMessage.id
		}) else {
			return
		}
		
		do {
			
			let stream = try await service.streamMessage(
				userMessage: trimmedInput,
				driver: driver,
				history: messages
			)
			
			for try await chunk in stream {
				
				messages[assistantIndex].content += chunk
			}
			
			messages[assistantIndex].state = .sent
			
		} catch {
			
			messages[assistantIndex].content =
			"Erro ao conectar com o modelo."
			
			messages[assistantIndex].state = .error
		}
		withAnimation {
			isResponding = false
		}
	}
}

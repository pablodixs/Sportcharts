//
//  ChatViewModel.swift
//  Sportcharts
//
//  Created by Pablo Dias on 11/05/26.
//

import Foundation
import FoundationModels
import Observation
import SwiftUI

@MainActor
@Observable
final class ChatViewModel {
	
	enum ChatMode {
		case sessionAnalysis
		case sessionChat
	}
	
	var messages: [ChatMessage] = []
	
	var input: String = ""
	
	var sessionContext: String = ""
	
	var isResponding = false
	
	private let service = OllamaService()
	private let maxHistoryMessages = 8
	private let streamingDelayNanoseconds: UInt64 = 8_000_000
	
	func sendMessage(driver: F1Driver?) async {
		let trimmedInput = input.trimmingCharacters(
			in: .whitespacesAndNewlines
		)
		
		guard !trimmedInput.isEmpty else {
			return
		}
		
		withAnimation {
			isResponding = true
		}
		
		defer {
			withAnimation {
				isResponding = false
			}
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
		
		guard
			let assistantIndex = messages.firstIndex(where: {
				$0.id == assistantMessage.id
			})
		else {
			return
		}
		
		do {
			guard case .available = SystemLanguageModel.default.availability else {
				throw FoundationDriverChatError.modelUnavailable
			}
			
			let response = try await requestDriverResponse(
				userMessage: trimmedInput,
				driver: driver
			)
			
			for character in response {
				if Task.isCancelled { return }
				
				messages[assistantIndex].content.append(character)
				try? await Task.sleep(nanoseconds: streamingDelayNanoseconds)
			}
			
			messages[assistantIndex].state = .sent
			
		} catch {
			
			messages[assistantIndex].content =
			"Não consegui responder com o Foundation Model agora."
			
			messages[assistantIndex].state = .error
		}
	}
	
	func startSessionAnalysis(sessionContext: String) async {
		withAnimation {
			isResponding = true
		}
		
		let assistantMessage = ChatMessage(
			role: .assistant,
			content: "",
			state: .typing
		)
		messages.append(assistantMessage)
		guard
			let index = messages.firstIndex(where: {
				$0.id == assistantMessage.id
			})
		else {
			return
		}
		do {
			let stream = try await service.generateSessionAnalysis(
				sessionContext: sessionContext
			)
			for try await chunk in stream {
				messages[index].content += chunk
			}
			messages[index].state = .sent
		} catch {
			messages[index].content =
			"Erro ao analisar sessão."
			messages[index].state = .error
		}
		
		withAnimation {
			isResponding = false
		}
	}
	
	func sendSessionMessage() async {
		withAnimation {
			isResponding = true
		}
		let trimmedInput = input.trimmingCharacters(
			in: .whitespacesAndNewlines
		)
		
		guard !trimmedInput.isEmpty else {
			return
		}
		
		let userMessage = ChatMessage(
			role: .user,
			content: trimmedInput,
			state: .sent
		)
		
		messages.append(userMessage)
		
		input = ""
		
		let assistantMessage = ChatMessage(
			role: .assistant,
			content: "",
			state: .typing
		)
		
		messages.append(assistantMessage)
		
		guard
			let index = messages.firstIndex(where: {
				$0.id == assistantMessage.id
			})
		else {
			return
		}
		
		do {
			
			let stream = try await service.chatAboutSession(
				userMessage: trimmedInput,
				sessionContext: sessionContext,
				history: messages
			)
			
			for try await chunk in stream {
				messages[index].content += chunk
			}
			
			messages[index].state = .sent
			
		} catch {
			
			messages[index].content =
			"Erro ao conversar com o modelo."
			
			messages[index].state = .error
		}
		
		withAnimation {
			isResponding = false
		}
	}
}

extension ChatViewModel {
	private func requestDriverResponse(
		userMessage: String,
		driver: F1Driver?
	) async throws -> String {
		let session = LanguageModelSession(
			instructions: buildDriverInstructions(driver: driver)
		)
		
		let response = try await session.respond(
			to: buildDriverPrompt(userMessage: userMessage)
		)
		
		return response.content.trimmingCharacters(
			in: .whitespacesAndNewlines
		)
	}
	
	private func buildDriverPrompt(userMessage: String) -> String {
		let history = messages
			.dropLast(2)
			.filter {
				$0.state == .sent
					&& !$0.content.trimmingCharacters(
						in: .whitespacesAndNewlines
					).isEmpty
			}
			.suffix(maxHistoryMessages)
			.map { message in
				let role = switch message.role {
				case .user:
					"Usuário"
				case .assistant:
					"Vrum"
				case .system:
					"Sistema"
				}
				
				return "\(role): \(message.content)"
			}
			.joined(separator: "\n")
		
		return """
		Conversa recente:
		\(history)
		
		Pergunta atual:
		\(userMessage)
		"""
	}
	
	private func buildDriverInstructions(driver: F1Driver?) -> String {
		let driverContext: String
		
		if let driver {
			driverContext = """
			
			Contexto do piloto:
			Nome: \(driver.firstName) \(driver.lastName)
			Número: \(driver.number)
			Equipe: \(driver.team.rawValue)
			Nacionalidade: \(driver.nationalityName)
			
			Bio:
			\(driver.bio)
			"""
		} else {
			driverContext = ""
		}
		
		return """
		Você é Vrum, um analista técnico e engenheiro de Fórmula 1.
		Responda em português do Brasil.
		Seja claro, objetivo, técnico e acessível.
		Explique conceitos técnicos quando necessário.
		Não invente fatos.
		Não diga que você é uma IA.
		Não reafirme seu papel ao usuário.
		Foque em precisão técnica sobre estratégia, pneus, qualifying, corrida, DRS, undercut, overcut, telemetria, degradação, race pace e pilotagem.
		\(driverContext)
		"""
	}
}

private enum FoundationDriverChatError: Error {
	case modelUnavailable
}

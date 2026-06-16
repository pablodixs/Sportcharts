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

	private let openF1Service = OpenF1Service()
	private var driverContextCache: [Int: String] = [:]
	private let maxHistoryMessages = 8
	private let maxSessionContextLength = 5_500
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
				driver: driver,
				apiContext: await recentDriverContext(for: driver)
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
			guard case .available = SystemLanguageModel.default.availability else {
				throw FoundationSessionChatError.modelUnavailable
			}

			let response = try await requestSessionAnalysisResponse(
				sessionContext: sessionContext
			)

			for character in response {
				if Task.isCancelled { return }

				messages[index].content.append(character)
				try? await Task.sleep(nanoseconds: streamingDelayNanoseconds)
			}

			messages[index].state = .sent
		} catch {
			messages[index].content =
			"Não consegui analisar a sessão com o Foundation Model agora."
			messages[index].state = .error
		}

		withAnimation {
			isResponding = false
		}
	}

	func sendSessionMessage() async {
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
			guard case .available = SystemLanguageModel.default.availability else {
				throw FoundationSessionChatError.modelUnavailable
			}

			let response = try await requestSessionResponse(
				userMessage: trimmedInput,
				sessionContext: sessionContext
			)

			for character in response {
				if Task.isCancelled { return }

				messages[index].content.append(character)
				try? await Task.sleep(nanoseconds: streamingDelayNanoseconds)
			}

			messages[index].state = .sent

		} catch {

			messages[index].content =
			"Não consegui responder com o Foundation Model agora."

			messages[index].state = .error
		}
	}
}

extension ChatViewModel {
	private func requestDriverResponse(
		userMessage: String,
		driver: F1Driver?,
		apiContext: String
	) async throws -> String {
		let session = LanguageModelSession(
			instructions: buildDriverInstructions(
				driver: driver,
				apiContext: apiContext
			)
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

	private func buildDriverInstructions(
		driver: F1Driver?,
		apiContext: String
	) -> String {
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

		let apiContextText = apiContext.isEmpty
			? ""
			: "\n\n\(apiContext)"

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
		\(apiContextText)
		"""
	}

	private func recentDriverContext(for driver: F1Driver?) async -> String {
		guard let driver else {
			return ""
		}

		if let cached = driverContextCache[driver.number] {
			return cached
		}

		let year = Calendar.current.component(.year, from: .now)
		guard let sessions = try? await openF1Service.fetchSessionsByYear(year: year) else {
			return ""
		}

		let completed = sessions
			.filter { !$0.isFuture && !$0.isCancelled }
			.sorted { $0.dateStart > $1.dateStart }

		var driverResults: [(Session, SessionResult)] = []

		for session in completed.prefix(8) {
			guard driverResults.count < 4 else {
				break
			}

			guard
				let results = try? await openF1Service.fetchSessionResult(
					sessionKey: session.sessionKey
				),
				let result = results.first(where: {
					$0.driverNumber == driver.number
				})
			else {
				continue
			}

			driverResults.append((session, result))
		}

		let context = OpenF1ContextBuilder.recentDriverResults(
			driver: driver,
			sessions: sessions,
			resultsBySession: driverResults
		)

		driverContextCache[driver.number] = context

		return context
	}
}

private enum FoundationDriverChatError: Error {
	case modelUnavailable
}

extension ChatViewModel {
	private func requestSessionAnalysisResponse(
		sessionContext: String
	) async throws -> String {
		let session = LanguageModelSession(
			instructions: buildSessionInstructions()
		)

		let response = try await session.respond(
			to: """
			Analise esta sessão com base no contexto abaixo.
			Use apenas as informações fornecidas.
			Destaque storyline, momento-chave, pontos positivos, melhorias e próxima ação.

			Contexto resumido da sessão:
			\(compactSessionContext(sessionContext))
			"""
		)

		return response.content.trimmingCharacters(
			in: .whitespacesAndNewlines
		)
	}

	private func requestSessionResponse(
		userMessage: String,
		sessionContext: String
	) async throws -> String {
		let session = LanguageModelSession(
			instructions: buildSessionInstructions()
		)

		let response = try await session.respond(
			to: buildSessionPrompt(
				userMessage: userMessage,
				sessionContext: sessionContext
			)
		)

		return response.content.trimmingCharacters(
			in: .whitespacesAndNewlines
		)
	}

	private func buildSessionInstructions() -> String {
		"""
		Você é Vrum, um engenheiro de performance e analista técnico de Fórmula 1.
		Responda em português do Brasil.
		Use apenas o contexto da sessão fornecido.
		Se a resposta depender de dados que não aparecem no contexto, diga isso claramente.
		Seja técnico, direto e contextual.
		Não diga que você é uma IA.
		Não reafirme seu papel ao usuário.
		"""
	}

	private func buildSessionPrompt(
		userMessage: String,
		sessionContext: String
	) -> String {
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
		Contexto resumido da sessão:
		\(compactSessionContext(sessionContext))

		Conversa recente:
		\(history)

		Pergunta atual:
		\(userMessage)
		"""
	}

	private func compactSessionContext(_ context: String) -> String {
		let cleaned = context
			.replacingOccurrences(of: "\r", with: "")
			.trimmingCharacters(in: .whitespacesAndNewlines)

		guard cleaned.count > maxSessionContextLength else {
			return cleaned
		}

		let prefix = String(cleaned.prefix(maxSessionContextLength - 80))
		return prefix + "\n... contexto truncado para manter o limite do modelo."
	}
}

private enum FoundationSessionChatError: Error {
	case modelUnavailable
}

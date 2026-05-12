//
//  OllamaService.swift
//  Sportcharts
//
//  Created by Pablo Dias on 11/05/26.
//

import Foundation

enum ReasoningMode {
	case automatic
	case enabled
	case disabled

	var command: String {
		switch self {
		case .enabled:
			return "/thinking"

		case .disabled:
			return "/no_thinking"

		case .automatic:
			return ""
		}
	}
}

struct OllamaOptions: Codable {
	let temperature: Double
	let numCtx: Int

	enum CodingKeys: String, CodingKey {
		case temperature
		case numCtx = "num_ctx"
	}
}

final class OllamaService {

	private let baseURL =
		"http://192.168.1.66:11434/api/chat"

	// MARK: - Streaming

	func streamMessage(
		userMessage: String,
		driver: F1Driver?,
		history: [ChatMessage],
		reasoning: ReasoningMode = .disabled
	) async throws -> AsyncThrowingStream<String, Error> {

		guard let url = URL(string: baseURL) else {
			throw URLError(.badURL)
		}

		let requestBody = buildRequestBody(
			userMessage: userMessage,
			driver: driver,
			history: history,
			reasoning: reasoning
		)

		let jsonData = try JSONEncoder().encode(
			requestBody
		)

		var request = URLRequest(url: url)

		request.httpMethod = "POST"
		request.httpBody = jsonData

		request.setValue(
			"application/json",
			forHTTPHeaderField: "Content-Type"
		)

		return AsyncThrowingStream { continuation in

			let task = Task {

				do {

					let (bytes, response) =
						try await URLSession.shared.bytes(
							for: request
						)

					guard
						let httpResponse =
							response as? HTTPURLResponse
					else {
						throw URLError(.badServerResponse)
					}

					guard 200...299 ~= httpResponse.statusCode
					else {
						throw URLError(.badServerResponse)
					}

					for try await line in bytes.lines {

						if Task.isCancelled {
							continuation.finish()
							return
						}

						guard !line.isEmpty else {
							continue
						}

						guard
							let data = line.data(
								using: .utf8
							)
						else {
							continue
						}

						do {

							let chunk =
								try JSONDecoder().decode(
									OllamaStreamResponse.self,
									from: data
								)

							guard
								let content =
									chunk.message?.content
							else {

								if chunk.done == true {
									continuation.finish()
								}

								continue
							}

							let cleanedContent =
								cleanThinkTags(
									from: content
								)

							if !cleanedContent.isEmpty {

								continuation.yield(
									cleanedContent
								)
							}

							if chunk.done == true {

								continuation.finish()
							}

						} catch {

							print(
								"Chunk decode error:",
								error
							)
						}
					}

				} catch {

					continuation.finish(
						throwing: error
					)
				}
			}

			continuation.onTermination = { _ in
				task.cancel()
			}
		}
	}
}

// MARK: - Helpers

extension OllamaService {

	private func shouldUseReasoning(
		for text: String
	) -> Bool {

		let keywords = [
			"analisar",
			"análise",
			"compare",
			"comparar",
			"estratégia",
			"preveja",
			"telemetria",
			"pace",
			"degradação",
			"simulação",
			"undercut",
			"overcut",
			"stint",
		]

		return keywords.contains {
			text.lowercased().contains($0)
		}
	}

	private func resolveReasoningMode(
		userMessage: String,
		reasoning: ReasoningMode
	) -> ReasoningMode {

		switch reasoning {

		case .enabled:
			return .enabled

		case .disabled:
			return .disabled

		case .automatic:

			return shouldUseReasoning(
				for: userMessage
			)
				? .enabled
				: .disabled
		}
	}

	private func cleanThinkTags(
		from text: String
	) -> String {

		text
			.replacingOccurrences(
				of: "<think>",
				with: ""
			)
			.replacingOccurrences(
				of: "</think>",
				with: ""
			)
	}
}

// MARK: - Request Builder

extension OllamaService {

	fileprivate func buildRequestBody(
		userMessage: String,
		driver: F1Driver?,
		history: [ChatMessage],
		reasoning: ReasoningMode
	) -> OllamaRequest {

		let resolvedReasoning =
			resolveReasoningMode(
				userMessage: userMessage,
				reasoning: reasoning
			)

		let systemPrompt =
			buildSystemPrompt(
				driver: driver
			)

		var messages: [OllamaMessage] = []

		messages.append(
			OllamaMessage(
				role: "system",
				content: systemPrompt
			)
		)

		let historyMessages =
			history
			.filter {
				$0.state != .error && $0.state != .typing
			}
			.map {
				OllamaMessage(
					role: $0.role.rawValue,
					content: $0.content
				)
			}

		messages.append(
			contentsOf: historyMessages
		)

		let finalMessage: String

		if resolvedReasoning == .automatic {

			finalMessage = userMessage

		} else {

			finalMessage = """
				\(resolvedReasoning.command)

				\(userMessage)
				"""
		}

		messages.append(
			OllamaMessage(
				role: "user",
				content: finalMessage
			)
		)

		return OllamaRequest(
			model: "qwen3",
			stream: true,
			messages: messages,
			options: OllamaOptions(
				temperature: 0.4,
				numCtx: 2048
			)
		)
	}
}

// MARK: - Prompts

extension OllamaService {

	fileprivate func buildSystemPrompt(
		driver: F1Driver?
	) -> String {

		guard let driver else {
			return basePrompt()
		}

		return """
			\(basePrompt())

			Contexto do piloto:

			Nome: \(driver.firstName) \(driver.lastName)
			Número: \(driver.number)
			Equipe: \(driver.team.rawValue)
			Nacionalidade: \(driver.nationalityName)

			Bio:
			\(driver.bio)
			"""
	}

	fileprivate func basePrompt() -> String {

		"""
		Você é Vrum,
		um analista técnico e engenheiro de Fórmula 1.

		Regras:
		- Responda de forma clara e objetiva
		- Explique conceitos técnicos quando necessário
		- Seja técnico mas acessível
		- Não invente fatos
		- Responda em português
		- Não diga que você é uma IA
		- Não reafirme seu papel ao usuário
		- Foque em precisão técnica

		Especialidades:
		- estratégia de corrida
		- pneus
		- qualifying
		- corrida
		- DRS
		- undercut
		- overcut
		- telemetria
		- degradação
		- race pace
		- pilotagem
		"""
	}
}

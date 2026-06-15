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
	"http://172.20.10.9:11434/api/chat"
	
	// MARK: - Streaming
	
	func streamMessage(
		userMessage: String,
		driver: F1Driver?,
		history: [ChatMessage],
		systemPrompt: String? = nil,
		reasoning: ReasoningMode = .disabled
	) async throws -> AsyncThrowingStream<String, Error> {
		
		guard let url = URL(string: baseURL) else {
			throw URLError(.badURL)
		}
		
		let requestBody = buildRequestBody(
			userMessage: userMessage,
			driver: driver,
			history: history,
			systemPrompt: systemPrompt,
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
	
	func generateSessionAnalysis(
		sessionContext: String
	) async throws -> AsyncThrowingStream<String, Error> {
		
		let systemPrompt = """
  Você é um engenheiro de performance da Fórmula 1.
  
  Gere uma análise técnica da sessão fornecida.
  
  Foque em:
  - consistência
  - ritmo
  - pontos fortes
  - erros
  - comparação de voltas
  - oportunidades de melhoria
  """
		
		let userPrompt = """
  Dados da sessão:
  
  \(sessionContext)
  """
		
		return try await streamPrompt(
			systemPrompt: systemPrompt,
			userPrompt: userPrompt
		)
	}
	
	func chatAboutSession(
		userMessage: String,
		sessionContext: String,
		history: [ChatMessage]
	) async throws -> AsyncThrowingStream<String, Error> {
		
		let systemPrompt = """
  Você é um engenheiro de performance da Fórmula 1.
  
  Responda perguntas sobre a sessão utilizando os dados fornecidos.
  
  Seja técnico, direto e contextual.
  """
		
		let userPrompt = """
  Dados da sessão:
  
  \(sessionContext)
  
  Pergunta do usuário:
  
  \(userMessage)
  """
		
		return try await streamPrompt(
			systemPrompt: systemPrompt,
			userPrompt: userPrompt,
			history: history
		)
	}
	
	private func streamPrompt(
		systemPrompt: String,
		userPrompt: String,
		history: [ChatMessage] = []
	) async throws -> AsyncThrowingStream<String, Error> {
		
		return try await streamMessage(
			userMessage: userPrompt,
			driver: nil,
			history: history,
			systemPrompt: systemPrompt,
			reasoning: .disabled
		)
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
		systemPrompt: String?,
		reasoning: ReasoningMode
	) -> OllamaRequest {
		
		let resolvedSystemPrompt =
		systemPrompt ?? buildSystemPrompt(
			driver: driver
		)
		
		var messages: [OllamaMessage] = []
		
		messages.append(
			OllamaMessage(
				role: "system",
				content: resolvedSystemPrompt
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
		
		if reasoning == .automatic {
			
			finalMessage = userMessage
			
		} else {
			
			finalMessage = """
	\(reasoning.command)
	
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
			model: "qwen3:latest",
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

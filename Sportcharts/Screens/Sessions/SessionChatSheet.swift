//
//  SessionChatSheet.swift
//  Sportcharts
//
//  Created by Pablo Dias on 12/05/26.
//

import SwiftUI

struct SessionChatSheet: View {
	@Environment(\.dismiss) var dismiss

	let sessionContext: String
	let smartQuestions: [String]
	let initialQuestion: String?
	let previousContext: String? = nil

	@State private var viewModel = ChatViewModel()
	@State private var screenLoaded = false

	init(
		sessionContext: String,
		smartQuestions: [String] = [],
		initialQuestion: String? = nil
	) {
		self.sessionContext = sessionContext
		self.smartQuestions = smartQuestions
		self.initialQuestion = initialQuestion
	}

	private var displayedSmartQuestions: [String] {
		let questions = smartQuestions.isEmpty
			? SessionSmartQuestionBuilder.questions(from: sessionContext)
			: smartQuestions

		return Array(questions.prefix(3))
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				LazyVStack {
					VStack {
						if viewModel.messages.isEmpty {
							Image(systemName: "tire")
								.font(.system(size: 42))
								.symbolEffect(
									.rotate.byLayer,
									options: .repeat(.periodic)
								)
							Text("Ask Vrum".uppercased())
								.fontWidth(.condensed)
								.font(.system(size: 46))
								.fontWeight(.black)

							VStack(spacing: 12) {
								ForEach(
									Array(displayedSmartQuestions.enumerated()),
									id: \.offset
								) { index, question in
									Button {
										viewModel.input = question
										Task {
											await viewModel.sendSessionMessage()
										}
									} label: {
										Text(question)
											.padding(4)
											.multilineTextAlignment(.center)
									}
									.offset(y: screenLoaded ? 0 : 64)
									.opacity(screenLoaded ? 1 : 0)
									.animation(
										.spring().delay(0.25 + Double(index) * 0.16),
										value: screenLoaded
									)
								}
							}
							.bold()
							.buttonStyle(.glass)
							.font(.subheadline)
						}
					}

					ForEach(viewModel.messages) { message in
						MessageBubble(message: message, accent: .gray)
					}
				}
				.padding(.horizontal)
				.padding(.bottom)
			}
				.onAppear {
					viewModel.sessionContext = sessionContext
					if let initialQuestion,
					   viewModel.input.isEmpty {
						viewModel.input = initialQuestion
					}

					DispatchQueue.main.async {
						screenLoaded = true
				}
			}
			.toolbar {
				if viewModel.isResponding {
					ToolbarItem(placement: .title) {
						Text("Ask Vrum".uppercased())
							.fontWidth(.condensed)
							.font(.title2)
							.bold()
					}
				}
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .close) {
						dismiss()
					}
				}
				}
				.safeAreaBar(edge: .bottom) {
					VStack(alignment: .leading, spacing: 8) {
						DriverMentionSuggestionsView(text: $viewModel.input)

						HStack {
							TextField("Pergunte ao Vrum", text: $viewModel.input)
							Button {
								Task {
									await viewModel.sendSessionMessage()
								}
							} label: {
								if viewModel.isResponding {
									ProgressView()
								} else {
									Label("Enviar", systemImage: "arrow.up")
										.labelStyle(.iconOnly)
										.bold()
								}
							}
							.disabled(viewModel.isResponding || viewModel.input.count < 3)
							.transition(.blurReplace)
							.padding(8)
							.background(.primary)
							.foregroundStyle(.foreground)
							.clipShape(Circle())
						}
						.padding(8)
						.padding(.leading, 12)
						.glassEffect(.regular.interactive(), in: .capsule)
					}
					.padding(.horizontal)
				}
		}
	}
}

extension SessionChatSheet {

	fileprivate static var mockSessionContext: String {
		"""
		Sessão de Fórmula 1

		Evento: Bahrain Grand Prix
		Circuito: Bahrain International Circuit
		Tipo: Race
		Data: 14/03/2026

		Resultados:

		Posição: 1
		Piloto: Max Verstappen
		Equipe: Red Bull Racing
		Número: 1
		Pontos: 25
		Voltas completadas: 57
		Duração: 1:32:11.532
		Gap para líder: Líder
		Status:
		- DNF: false
		- DSQ: false
		- DNS: false

		Posição: 2
		Piloto: Charles Leclerc
		Equipe: Ferrari
		Número: 16
		Pontos: 18
		Voltas completadas: 57
		Duração: 1:32:18.901
		Gap para líder: +7.369s
		Status:
		- DNF: false
		- DSQ: false
		- DNS: false

		Posição: 3
		Piloto: Lando Norris
		Equipe: McLaren
		Número: 4
		Pontos: 15
		Voltas completadas: 57
		Duração: 1:32:22.102
		Gap para líder: +10.570s
		Status:
		- DNF: false
		- DSQ: false
		- DNS: false
		"""
	}
}

#Preview {
	SessionChatSheet(sessionContext: SessionChatSheet.mockSessionContext)
}

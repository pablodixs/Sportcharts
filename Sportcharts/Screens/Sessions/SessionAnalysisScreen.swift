//
//  SessionAnalyseScreen.swift
//  Sportcharts
//
//  Created by Pablo Dias on 13/05/26.
//

import SwiftUI
import UIKit

enum AnalysisBackgroundState {
	case idle
	case isResponding
}

struct AnimatedMeshBackground: View {
	let state: AnalysisBackgroundState

	@State private var backgroundOpacity: Double = 0

	var body: some View {
		ZStack {
			TimelineView(.animation) { timeline in
				let time = timeline.date.timeIntervalSinceReferenceDate

				Canvas { context, size in
					let rect = CGRect(origin: .zero, size: size)

					context.fill(
						Path(rect),
						with: .linearGradient(
							Gradient(colors: backgroundColors),
							startPoint: CGPoint(x: 0, y: size.height),
							endPoint: CGPoint(x: size.width, y: 0)
						)
					)

					for blob in blobs(time: time, size: size) {
						context.addFilter(.blur(radius: 90))
						context.fill(
							Path(ellipseIn: blob.frame),
							with: .color(blob.color)
						)
					}
				}
			}
			.opacity(backgroundOpacity)
		}
		.ignoresSafeArea()
		.transition(.opacity)
		.animation(.easeInOut(duration: 0.5), value: backgroundOpacity)
		.onAppear {
			backgroundOpacity = state == .idle ? 0.15 : 1
		}
		.onChange(of: state) { _, newValue in
			withAnimation(.easeInOut(duration: 0.35)) {
				backgroundOpacity = 0
			}

			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				withAnimation(.easeInOut(duration: 0.5)) {
					backgroundOpacity = newValue == .idle ? 0.15 : 1
				}
			}
		}
	}

	private var backgroundColors: [Color] {
		switch state {
		case .idle:
			return [.clear, .clear]
		case .isResponding:
			return [.clear, .clear, .clear]
		}
	}

	private func blobs(time: Double, size: CGSize) -> [(
		frame: CGRect, color: Color
	)] {
		switch state {
		case .idle:
			return [
				(
					CGRect(
						x: size.width * 0.2,
						y: size.height * 0.7,
						width: 220,
						height: 220
					),
					.white.opacity(0.03)
				)
			]

		case .isResponding:
			let x1 = sin(time * 0.6) * 60
			let y1 = cos(time * 0.5) * 50

			let x2 = cos(time * 0.4) * 80
			let y2 = sin(time * 0.7) * 70

			let x3 = sin(time * 0.3) * 50
			let y3 = cos(time * 0.8) * 60

			return [
				(
					CGRect(
						x: size.width * 0.05 + x1,
						y: size.height * 0.15 + y1,
						width: 260,
						height: 260
					),
					.cyan.opacity(0.5)
				),
				(
					CGRect(
						x: size.width * 0.45 + x2,
						y: size.height * 0.55 + y2,
						width: 300,
						height: 300
					),
					.blue.opacity(0.25)
				),
				(
					CGRect(
						x: size.width * 0.65 + x3,
						y: size.height * 0.2 + y3,
						width: 240,
						height: 240
					),
					.blue.opacity(0.2)
				),
			]
		}
	}
}

struct SessionAnalysisScreen: View {
	let sessionContext: String
	private let bottomAnchorID = "session-analysis-bottom-anchor"

	@Environment(\.dismiss) var dismiss

	@State private var screenLoaded = false
	@State private var moveGradient = false
	@State private var isSessionChatPresented = false
	@State private var selectedPilotNumber: Int?
	@State private var showCopiedAlert = false
	@State private var showPilotButtons = false

	@StateObject private var viewModel = SessionAnalysisViewModel()

	var body: some View {
		NavigationStack {
			ScrollViewReader { proxy in
				ScrollView {
					messagesStack()
						.id("session-analysis-content")

					Color.clear
						.frame(height: 1)
						.id(bottomAnchorID)
				}
				.scrollClipDisabled()
				.onChange(of: viewModel.messages.last?.content) { _, _ in
					scrollToBottom(with: proxy)
				}
				.onChange(of: viewModel.messages.count) { _, _ in
					scrollToBottom(with: proxy)
				}
			}
			.background {
				AnimatedMeshBackground(
					state: viewModel.isResponding ? .isResponding : .idle
				)
			}
			.onAppear {
				DispatchQueue.main.async {
					screenLoaded = true
				}
			}
			.task {
				await viewModel.startSessionAnalysis(
					sessionContext: sessionContext
				)
			}
			.safeAreaBar(edge: .bottom) {
				if !viewModel.pilots.isEmpty {
					VStack(alignment: .leading, spacing: 8) {
						Text("Pilotos citados")
							.font(.caption)
							.bold()
							.foregroundStyle(.secondary)

						ScrollView(.horizontal) {
								HStack(spacing: 8) {
									ForEach(
										Array(viewModel.pilots.enumerated()),
										id: \.offset
									) { index, driver in
										pilotButton(driver, index: index)
									}
							}
						}
						.scrollClipDisabled()
						.scrollIndicators(.hidden)
					}
					.padding()
				}
			}
			.safeAreaBar(edge: .top) {
				if viewModel.isResponding {
					HStack(alignment: .center) {
						Image(systemName: "sparkles.2")
							.symbolEffect(
								.breathe.byLayer,
								options: .repeat(.continuous)
							)
						textGlow("Analisando sessão...")
							.animation(nil, value: screenLoaded)
							.fontWeight(.medium)
						Spacer()
					}
					.foregroundStyle(.secondary)
					.font(.title3)
					.padding()
				}
			}
			.navigationTitle("Análise da Sessão")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .close) {
						dismiss()
					}
				}

				if viewModel.isResponding {
					ToolbarItem {
						ProgressView()
					}
				}

				ToolbarItem {
					Menu {
						Button("Perguntar ao Vrum", systemImage: "tire") {
							isSessionChatPresented = true
						}
						
						Button("Copiar análise", systemImage: "doc.on.doc") {
							guard !viewModel.analysisText.isEmpty else {
								return
							}
							UIPasteboard.general.string = viewModel.analysisText
							showCopiedAlert = true
						}

						ShareLink(
							item: viewModel.analysisText,
							subject: Text("Análise da Sessão"),
							message: Text("Resumo gerado pelo Sportcharts")
						) {
							Label(
								"Compartilhar",
								systemImage: "square.and.arrow.up"
							)
						}
					} label: {
						Label("Opções", systemImage: "ellipsis")
					}
					.disabled(viewModel.analysisText.isEmpty)
				}
			}
			.alert("Análise copiada", isPresented: $showCopiedAlert) {
				Button("OK", role: .cancel) {}

			}
			.sheet(isPresented: $isSessionChatPresented) {
				SessionChatSheet(
					sessionContext: sessionContext,
					smartQuestions: viewModel.smartQuestions
				)
			}
			.onChange(of: viewModel.pilots.map(\.number)) { _, numbers in
				guard !numbers.isEmpty else {
					showPilotButtons = false
					return
				}

				showPilotButtons = false
				DispatchQueue.main.async {
					withAnimation(
						.spring(response: 0.45, dampingFraction: 0.78)
					) {
						showPilotButtons = true
					}
				}
			}
			.sheet(
				isPresented: Binding(
					get: { selectedPilotNumber != nil },
					set: { isPresented in
						if !isPresented {
							selectedPilotNumber = nil
						}
					}
				)
			) {
				if let selectedPilotNumber {
					LocalDriverDetail(driverNumber: selectedPilotNumber)
				} else {
					EmptyView()
				}
			}
		}
	}

	private func scrollToBottom(with proxy: ScrollViewProxy) {
		DispatchQueue.main.async {
			withAnimation(.easeOut(duration: 0.18)) {
				proxy.scrollTo(bottomAnchorID, anchor: .bottom)
			}
		}
	}

	@ViewBuilder
	func textGlow(_ text: String) -> some View {
		Text(text)
			.overlay {
				GeometryReader { proxy in
					LinearGradient(
						colors: [.clear, .white.opacity(0.85), .clear],
						startPoint: .leading,
						endPoint: .trailing
					)
					.frame(width: proxy.size.width * 0.8)
					.offset(
						x: moveGradient ? proxy.size.width : -proxy.size.width
					)
				}
				.mask {
					Text(text)
				}
			}
			.animation(
				.linear(duration: 2.5)
					.repeatForever(autoreverses: false)
					.delay(0.25),
				value: moveGradient
			)
			.fixedSize()
			.onAppear {
				DispatchQueue.main.async {
					withAnimation {
						moveGradient = true
					}
				}
			}
	}

	@ViewBuilder
	func messagesStack() -> some View {
		LazyVStack(alignment: .leading, spacing: 12) {
			ForEach(viewModel.messages) { message in
				MarkdownMessageText(message.content)
					.id(message.id)
					.lineHeight(.loose)
			}
		}
		.padding(.horizontal)
		.padding(.bottom)
	}

	@ViewBuilder
	func pilotButton(_ driver: F1Driver, index: Int) -> some View {
		Button {
			selectedPilotNumber = driver.number
		} label: {
			HStack(spacing: 6) {
				AsyncImage(url: driver.imageURL) { phase in
					switch phase {
					case .empty:
						ProgressView()
							.frame(width: 36, height: 36)
					case .failure:
						Color.secondary.opacity(0.15)
							.frame(width: 36, height: 36)
					case .success(let image):
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
							.padding(.top, 74)
							.frame(width: 36, height: 36)
							.background(driver.teamColors.primary)
							.clipShape(.circle)
					@unknown default:
						Color.clear
							.frame(width: 36, height: 36)
					}
				}

				VStack(alignment: .leading, spacing: 0) {
					Text(driver.lastName)
						.font(.subheadline)
						.bold()
					Text("#\(driver.number)")
						.font(.caption2)
						.foregroundStyle(.secondary)
				}
			}
		}
		.buttonStyle(.glass)
		.opacity(showPilotButtons ? 1 : 0)
		.scaleEffect(showPilotButtons ? 1 : 0.84)
		.offset(y: showPilotButtons ? 0 : 16)
		.animation(
			.spring(response: 0.45, dampingFraction: 0.72)
				.delay(Double(index) * 0.07),
			value: showPilotButtons
		)
	}
}

private struct MarkdownMessageText: View {
	let content: String

	init(_ content: String) {
		self.content = content
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			ForEach(
				Array(content.components(separatedBy: .newlines).enumerated()),
				id: \.offset
			) { entry in
				markdownLine(entry.element)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	@ViewBuilder
	private func markdownLine(_ line: String) -> some View {
		let trimmed = line.trimmingCharacters(in: .whitespaces)

		if trimmed.isEmpty {
			Spacer()
				.frame(height: 4)
		} else if trimmed.hasPrefix("### ") {
			inlineText(String(trimmed.dropFirst(4)))
				.font(.headline)
				.fontWeight(.bold)
				.padding(.top, 4)
		} else if trimmed.hasPrefix("## ") {
			inlineText(String(trimmed.dropFirst(3)))
				.font(.title3)
				.fontWeight(.black)
				.fontWidth(.condensed)
				.padding(.top, 8)
		} else if trimmed.hasPrefix("# ") {
			inlineText(String(trimmed.dropFirst(2)))
				.font(.title2)
				.fontWeight(.black)
				.fontWidth(.condensed)
				.padding(.top, 8)
		} else if trimmed.hasPrefix("- ") {
			HStack(alignment: .firstTextBaseline, spacing: 8) {
				Text("•")
					.fontWeight(.bold)
				inlineText(String(trimmed.dropFirst(2)))
			}
		} else if trimmed.hasPrefix("> ") {
			HStack(alignment: .top, spacing: 10) {
				Rectangle()
					.fill(.secondary.opacity(0.35))
					.frame(width: 3)
				inlineText(String(trimmed.dropFirst(2)))
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
			.padding(.vertical, 4)
		} else {
			inlineText(line)
		}
	}

	private func inlineText(_ text: String) -> Text {
		if let markdown = try? AttributedString(markdown: text) {
			return Text(markdown)
		}

		return Text(text)
	}
}

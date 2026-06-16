//
//  HomeView.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/03/26.
//

import SwiftUI

struct HomeView: View {
	@Environment(\.colorScheme) private var colorScheme

	@State private var viewModel = SessionsViewModel()
	@State private var briefViewModel = HomeBriefViewModel()
	@State private var showNextSessionView = false
	@State private var selectedHomeQuestion: String?
	@State private var isSessionChatPresented = false
	@State private var briefCompletionGlow = false

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 16) {
					VStack {
						if let session = viewModel.nextSession,
							showNextSessionView
						{
							nextSessionView(session)
								.transition(.opacity)
						} else {
							HStack {
								ProgressView()
								Text("Carregando próxima sessão...")
									.font(.callout)
									.fontWeight(.semibold)
									.foregroundStyle(.secondary)
							}
						}
					}
					.frame(maxWidth: .infinity)
					.padding()
					.background(.quinary)
					.clipShape(RoundedRectangle(cornerRadius: 12))

					if let session = viewModel.previousSession {
						homeBriefView(session)
					}

					if let session = viewModel.previousSession {
						DriversStandingView(sessionKey: session.sessionKey)
					}

					Spacer()
				}
				.padding(.horizontal)
			}
			.toolbar {
				ToolbarItem(placement: .title) {
					Image(.logo)
						.resizable()
						.scaledToFit()
						.frame(width: 164)
						.padding(8)
				}
			}
			.task {
				await viewModel.loadSessionsByYear(year: 2026)

				withAnimation {
					showNextSessionView = true
				}

				await loadHomeBriefIfNeeded()
			}
			.onChange(of: viewModel.previousSession?.sessionKey) { _, _ in
				Task {
					await loadHomeBriefIfNeeded()
				}
			}
			.onChange(of: briefViewModel.state) { _, state in
				guard case .success = state else {
					briefCompletionGlow = false
					return
				}

				withAnimation(.smooth(duration: 0.25)) {
					briefCompletionGlow = true
				}

				DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
					withAnimation(.smooth(duration: 0.45)) {
						briefCompletionGlow = false
					}
				}
			}
			.sheet(isPresented: $isSessionChatPresented) {
				SessionChatSheet(
					sessionContext: briefViewModel.sessionContext,
					smartQuestions: briefViewModel.brief?.smartQuestions ?? [],
					initialQuestion: selectedHomeQuestion
				)
			}
		}
	}

	@ViewBuilder
	private func homeBriefView(_ session: Session) -> some View {
		let isGenerating = briefViewModel.state == .idle
			|| briefViewModel.state == .loading
		let shouldGlow = isGenerating || briefCompletionGlow

		VStack(alignment: .leading, spacing: 14) {
			HStack {
				Label("Brief da última sessão", systemImage: "sparkles.2")
					.font(.callout)
					.fontWeight(.bold)
					.foregroundStyle(.secondary)

				Spacer()

				Text(LocalizedStringKey(session.sessionType.uppercased()))
					.font(.caption)
					.fontWeight(.black)
					.fontWidth(.condensed)
					.padding(.vertical, 4)
					.padding(.horizontal, 8)
					.background(.secondary.opacity(0.12))
					.clipShape(Capsule())
			}

			switch briefViewModel.state {
			case .idle, .loading:
				homeBriefLoadingView()
					.transition(.opacity.combined(with: .scale(scale: 0.98)))
				.task {
					await loadHomeBriefIfNeeded()
				}
			case .empty:
				Text("Ainda não há dados recentes suficientes para o brief.")
					.font(.callout)
					.foregroundStyle(.secondary)
			case .failure:
				Text("Não foi possível carregar o brief da última sessão.")
					.font(.callout)
					.foregroundStyle(.secondary)
			case .success:
				if let brief = briefViewModel.brief {
					VStack(alignment: .leading, spacing: 10) {
						homeBriefHeadline(brief.headline)

						Text(brief.summary)
							.font(.callout)
							.foregroundStyle(.secondary)

						VStack(alignment: .leading, spacing: 8) {
							ForEach(Array(brief.highlights.prefix(3)), id: \.self) { highlight in
								Label(highlight, systemImage: "checkmark.circle.fill")
									.foregroundStyle(.secondary)
									.font(.callout)
							}
						}

						if !brief.smartQuestions.isEmpty {
							smartQuestionsView(brief.smartQuestions)
						}
					}
					.transition(.opacity.combined(with: .scale(scale: 0.985)))
				}
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding()
		.background(.quinary)	
		.clipShape(RoundedRectangle(cornerRadius: 12))
		.appleIntelligenceGlow(isActive: shouldGlow)
		.animation(.smooth(duration: 0.35), value: shouldGlow)
		.animation(.smooth(duration: 0.35), value: briefViewModel.state)
	}

	private func homeBriefLoadingView() -> some View {
		HStack(spacing: 10) {
			Image(systemName: "sparkles.2")
				.symbolEffect(
					.breathe.byLayer,
					options: .repeat(.continuous)
				)
				.foregroundStyle(briefGlowGradient)

			Text("Gerando briefing...")
				.font(.callout)
				.fontWeight(.semibold)
				.foregroundStyle(.secondary)
				.textGlow(
					glowColor: colorScheme == .light
						? .white.opacity(0.95)
						: .cyan.opacity(0.9),
					animationDuration: 1.45,
					gradientWidth: 0.7
				)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.vertical, 4)
	}

	@ViewBuilder
	private func homeBriefHeadline(_ headline: String) -> some View {
		let title = Text(headline)
			.font(.title)
			.fontWeight(.bold)
			.fontWidth(.condensed)

		if briefCompletionGlow {
			title
				.textGlow(
					glowColor: colorScheme == .light
						? .white
						: .cyan.opacity(0.85),
					animationDuration: 1.15,
					gradientWidth: 0.6
				)
		} else {
			title
		}
	}

	private var briefGlowGradient: LinearGradient {
		LinearGradient(
			colors: [
				.cyan.opacity(0.55),
				.blue.opacity(0.45),
				.purple.opacity(0.42),
				.pink.opacity(0.38)
			],
			startPoint: .leading,
			endPoint: .trailing
		)
	}

	@ViewBuilder
	private func smartQuestionsView(_ questions: [String]) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Smart Questions da semana")
				.font(.caption)
				.fontWeight(.bold)
				.foregroundStyle(.secondary)

			ForEach(Array(questions.prefix(3)), id: \.self) { question in
				Button {
					selectedHomeQuestion = question
					isSessionChatPresented = true
				} label: {
					HStack(spacing: 8) {
						Image(systemName: "tire")
						Text(question)
							.frame(maxWidth: .infinity, alignment: .leading)
						Image(systemName: "arrow.up.right")
							.font(.caption)
							.foregroundStyle(.secondary)
					}
					.font(.caption)
					.fontWeight(.semibold)
					.padding(.vertical, 8)
					.padding(.horizontal, 10)
					.glassEffect(.clear)
				}
				.buttonStyle(.plain)
			}
		}
	}

	private func loadHomeBriefIfNeeded() async {
		guard let session = viewModel.previousSession else {
			return
		}

		await briefViewModel.loadBrief(for: session)
	}

	@ViewBuilder
	private func nextSessionView(_ session: Session) -> some View {
		HStack {
			VStack(alignment: .leading) {
				Text("Próxima Sessão")
					.bold()
					.foregroundStyle(.secondary)
					.font(.callout)
				Text(LocalizedStringKey(session.sessionType.uppercased()))
					.font(.title)
					.fontWeight(.black)
					.fontWidth(.condensed)

				Text(LocalizedStringKey(session.sessionName))
					.font(.callout)
					.fontWeight(.semibold)

				Text("\(session.location), \(session.countryName)")
					.font(.callout)
			}

			Spacer()

			VStack(alignment: .trailing) {
				Spacer()
				if let date = isoFormatter.date(from: session.dateStart) {
					countdownView(to: date)
				}
				Spacer()
				NavigationLink(
					destination: SessionDetailScreen(
						sessionKey: session.sessionKey
					)
				) {
					HStack {
						Text("Ver mais")
						Image(systemName: "arrow.right")
					}
					.bold()
					.padding(8)
					.padding(.horizontal, 8)
				}
				.font(.callout)
				.foregroundStyle(.background)
				.background(.primary)
				.clipShape(.capsule)
			}
		}
	}

	@ViewBuilder
	private func countdownView(to date: Date) -> some View {
		TimelineView(.periodic(from: .now, by: 1)) { context in
			let remaining = max(0, Int(date.timeIntervalSince(context.date)))
			let days = remaining / 86_400
			let hours = (remaining % 86_400) / 3_600
			let minutes = (remaining % 3_600) / 60
			let seconds = remaining % 60
			Text(
				String(
					format: "%02dd %02dh %02dm %02ds",
					days,
					hours,
					minutes,
					seconds
				)
			)
			.font(.title2.monospacedDigit())
			.fontWidth(.condensed)
			.bold()
			.contentTransition(.numericText())
			.animation(.smooth(duration: 0.25), value: remaining)
		}
	}

	private let isoFormatter: ISO8601DateFormatter = {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [
			.withInternetDateTime
		]
		return formatter
	}()
}

private struct AppleIntelligenceGlow: ViewModifier {
	let isActive: Bool

	@State private var isRotating = false

	func body(content: Content) -> some View {
		content
			.overlay {
				ZStack {
					RoundedRectangle(cornerRadius: 12)
						.strokeBorder(
							glowGradient,
							lineWidth: 14
						)
						.blur(radius: 12)
						.opacity(isActive ? 0.28 : 0)

					RoundedRectangle(cornerRadius: 12)
						.strokeBorder(
							glowGradient,
							lineWidth: 4
						)
						.blur(radius: 4)
						.opacity(isActive ? 0.22 : 0)

					RoundedRectangle(cornerRadius: 12)
						.strokeBorder(
							.white.opacity(isActive ? 0.16 : 0),
							lineWidth: 0.8
						)
				}
				.clipShape(RoundedRectangle(cornerRadius: 12))
			}
			.shadow(
				color: .cyan.opacity(isActive ? 0.05 : 0),
				radius: 10
			)
			.shadow(
				color: .purple.opacity(isActive ? 0.04 : 0),
				radius: 8
			)
			.onAppear {
				withAnimation(
					.linear(duration: 3.4)
					.repeatForever(autoreverses: false)
				) {
					isRotating = true
				}
			}
	}

	private var glowGradient: AngularGradient {
		AngularGradient(
			gradient: Gradient(colors: [
				.cyan.opacity(0.40),
				.blue.opacity(0.30),
				.purple.opacity(0.32),
				.pink.opacity(0.26),
				.cyan.opacity(0.40)
			]),
			center: .center,
			angle: .degrees(isRotating ? 360 : 0)
		)
	}
}

private extension View {
	func appleIntelligenceGlow(isActive: Bool) -> some View {
		modifier(AppleIntelligenceGlow(isActive: isActive))
	}
}

#Preview {
	HomeView()
}

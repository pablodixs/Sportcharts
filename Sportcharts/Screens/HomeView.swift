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
	@State private var showNextSessionView = false

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 16) {
//					vrumOverviewView()

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
						.frame(width: 96)
						.padding(8)
				}
			}
			.task {
				await viewModel.loadSessionsByYear(year: 2026)

				withAnimation {
					showNextSessionView = true
				}
			}
		}
	}

	@ViewBuilder
	private func vrumOverviewView() -> some View {
		HStack {
			Image(systemName: "sparkles.2")
				.symbolEffect(
					.breathe.byLayer,
					options: .repeat(.continuous)
				)
			Text("Gerando visão geral da sessão anterior...")
				.modifier(
					TextGlow(
						glowColor: colorScheme == .light
							? .white.opacity(0.8) : .black.opacity(0.6)
					)
				)
		}
		.padding(.bottom)
		.font(.caption)
		.fontWeight(.semibold)
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

#Preview {
	HomeView()
}

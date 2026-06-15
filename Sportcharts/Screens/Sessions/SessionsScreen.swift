//
//  SessionsScreen.swift
//  Sportcharts
//
//  Created by Pablo Dias on 30/03/26.
//

import SwiftUI

struct SessionsScreen: View {
	@State private var viewModel = SessionsViewModel()
	@State private var year = 2026
	@State private var showPopover = false

	@State private var localTime: Bool = false
	@State private var selectedMeeting: MeetingGroup?
	@State private var didScrollToCurrentSession = false

	var body: some View {
		NavigationStack {
			VStack {
				if viewModel.state == .loading {
					ProgressView()
				} else {
					ScrollViewReader { proxy in
						ScrollView {
							HStack {
								Text(year.description)
									.font(.largeTitle)
									.fontWidth(.expanded)
									.bold()
									.onTapGesture {
										showPopover.toggle()
									}

								Spacer()

								VStack {
									Text("Horário local")
										.font(.caption)
										.fontWeight(.medium)

									Toggle(
										"Horário local",
										isOn: $localTime.animation()
									)
									.labelsHidden()
									.tint(.black)
								}
							}

							ForEach(viewModel.meetingGroups, id: \.id) {
								meeting in
								MeetingCardView(
									meeting: meeting,
									useTrackTime: localTime,
									currentSessionID: viewModel.currentSessionID
								)
								.onTapGesture {
									selectedMeeting = meeting
								}
							}
						}
						.onAppear {
							scrollToCurrentSession(
								with: proxy,
								animated: false
							)
						}
						.onChange(of: viewModel.state) { _, newState in
							guard newState == .success else {
								return
							}

							scrollToCurrentSession(with: proxy)
						}
						.contentMargins(.horizontal, 16)
					}
				}

				if case .failure(let message) = viewModel.state {
					Text(message)
				}
			}
			.navigationTitle("Sessões")
			.toolbarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem {
					Button("Buscar", systemImage: "magnifyingglass") {

					}
				}
				ToolbarItem {
					Menu("Opções", systemImage: "ellipsis") {
						Toggle(
							"Mostrar horário local",
							isOn: $localTime.animation()
						)
						.tint(.black)
					}
				}
			}
			.sheet(isPresented: $showPopover) {
				Picker("Ano", selection: $year) {
					ForEach(1950...2026, id: \.self) { y in
						Text(String(y)).tag(y)
					}
				}
				.pickerStyle(.wheel)
				.presentationDetents([.medium])
			}
			.sheet(item: $selectedMeeting) { session in
				VStack {
					Text(session.location)
				}
				.presentationDetents([.medium])
			}
			.task {
				await viewModel.loadSessionsByYear(year: year)
			}
			.onChange(of: year) {
				didScrollToCurrentSession = false

				Task {
					await viewModel.loadSessionsByYear(year: year)
				}
			}
		}
	}

	private func scrollToCurrentSession(
		with proxy: ScrollViewProxy,
		animated: Bool = true
	) {
		guard !didScrollToCurrentSession,
			  let targetID = viewModel.currentSessionID
		else {
			return
		}

		didScrollToCurrentSession = true

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			if animated {
				withAnimation(.easeInOut) {
					proxy.scrollTo(targetID, anchor: .center)
				}
			} else {
				proxy.scrollTo(targetID, anchor: .center)
			}
		}
	}
}

struct MeetingCardView: View {
	let meeting: MeetingGroup
	var useTrackTime: Bool = false
	var currentSessionID: Int?

	var body: some View {
		VStack(alignment: .leading) {
			Text(meeting.countryName.uppercased())
				.bold()
				.font(.title2)
				.fontWidth(.condensed)
			Text(meeting.location)
				.font(.headline)
				.foregroundStyle(.gray)

			ForEach(meeting.sessions) { session in
				NavigationLink(
					destination: SessionDetailScreen(
						sessionKey: session.sessionKey
					)
				) {
					HStack {
						VStack(alignment: .leading) {
							HStack {
								Label(
									session.isFuture ? "Em breve" : "Concluído",
									systemImage: session.isFuture
										? "calendar" : "checkmark.circle.fill"
								)
								.bold()
								.labelStyle(.iconOnly)
								.foregroundStyle(
									session.isFuture ? .gray : .green
								)

								Text(session.sessionName)
									.bold()
							}
						}
						Spacer()

						Text(
							session.formattedDateStart(
								useTrackTime: useTrackTime
							)
						)
						.fontWidth(.condensed)
						.bold()
						.contentTransition(.numericText())
					}
					.font(.subheadline)
					.padding(.vertical, 8)
					.opacity(session.isFuture ? 1 : 0.85)
				}
				.id(session.sessionKey)
				.background {
					if session.sessionKey == currentSessionID {
						RoundedRectangle(cornerRadius: 10)
							.fill(.primary.opacity(0.06))
					}
				}
			}
		}
		.id(meeting.id)
		.padding()
		.overlay(content: {
			RoundedRectangle(cornerRadius: 16)
				.stroke(lineWidth: 2)
				.foregroundStyle(.gray.quaternary)
		})
	}
}

#Preview {
	SessionsScreen()
}

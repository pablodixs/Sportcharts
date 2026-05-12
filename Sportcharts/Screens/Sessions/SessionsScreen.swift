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
									useTrackTime: localTime
								)
								.onTapGesture {
									selectedMeeting = meeting
								}
							}
						}
						.onChange(of: viewModel.state) { _, newState in
							guard newState == .success,
								let targetID = viewModel.currentMeetingID
							else { return }

							DispatchQueue.main.asyncAfter(
								deadline: .now() + 0.1
							) {
								withAnimation(.easeInOut) {
									proxy.scrollTo(targetID, anchor: .center)
								}
							}
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
				Task {
					await viewModel.loadSessionsByYear(year: year)
				}
			}
		}
	}
}

struct MeetingCardView: View {
	let meeting: MeetingGroup
	var useTrackTime: Bool = false

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

//
//  DriversStandingView.swift
//  Sportcharts
//
//  Created by Pablo Dias on 19/05/26.
//

import SwiftUI

struct DriversStandingView: View {
	var sessionKey: Int

	@State private var viewModel = StandingsViewModel()
	@State private var showAll = false

	private var displayedStandings: [DriverStanding] {
		if showAll {
			return viewModel.driversStadings
		}
		return Array(viewModel.driversStadings.prefix(5))
	}

	var body: some View {
		VStack {
			if viewModel.state == .loading {
				ProgressView()
			}

			if viewModel.state == .success {
				VStack(alignment: .leading) {
					Text("Classificação".uppercased())
						.font(.title2)
						.fontWidth(.condensed)
						.bold()

					VStack(spacing: 12) {
						ForEach(displayedStandings) { row in
							DriverRow(standing: row)
								.frame(maxWidth: .infinity, alignment: .leading)
						}

						if viewModel.driversStadings.count > 5 {
							Button {
								withAnimation(.smooth) {
									showAll.toggle()
								}
							} label: {
								Image(systemName:
									showAll ? "chevron.up" : "chevron.down"
								)
								.font(.callout)
								.fontWeight(.semibold)
								.frame(maxWidth: .infinity)
								.foregroundStyle(.gray)
							}
							.padding(.top, 8)
						}
					}

				}
				.padding()
				.overlay {
					RoundedRectangle(cornerRadius: 12)
						.stroke(lineWidth: 1)
						.foregroundStyle(.quinary)
				}
			}
		}
		.task {
			await viewModel.loadDriversStandings(sessionKey: sessionKey)
		}
	}
}

struct DriverRow: View {
	var standing: DriverStanding

	@State private var driver: F1Driver? = nil

	private var positionDif: Int {
		standing.positionCurrent - standing.positionStart
	}

	var body: some View {
		HStack(spacing: 12) {
			Text(standing.positionCurrent.description)
				.bold()
				.font(.title3)
				.fontWidth(.condensed)
				.frame(width: 20, alignment: .leading)

			positionVarIndicator()
				.frame(width: 8)

			NavigationLink(
				destination: LocalDriverDetail(driverNumber: driver?.number ?? 1)
			) {
				AsyncImage(url: driver?.imageURL) { phase in
					switch phase {
					case .empty:
						Color.clear
							.frame(width: 36, height: 36)
					case .failure:
						Color.clear
							.frame(width: 36, height: 36)
					case .success(let image):
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
							.padding(.top, 76)
							.frame(width: 36, height: 36)
							.background(driver?.teamColors.primary ?? .gray)
							.clipShape(.circle)
					@unknown default:
						Color.clear
							.frame(width: 36, height: 36)
					}
				}
				.frame(width: 36)

				Text(driver?.lastName.uppercased() ?? "")
					.bold()
					.fontWidth(.condensed)
					.frame(maxWidth: .infinity, alignment: .leading)
			}

			Text("\(standing.pointsCurrent.description)")
				.font(.callout)
				.fontWeight(.semibold)
				.monospacedDigit()
				.frame(width: 48, alignment: .trailing)
		}
		.onAppear {
			driver = F1Grid2026.driver(byNumber: standing.driverNumber)
		}
	}

	@ViewBuilder
	private func positionVarIndicator() -> some View {
		VStack {
			if positionDif == 0 {
				Text("-")
					.foregroundStyle(.gray)
			} else if positionDif > 0 {
				Image(systemName: "chevron.up")
					.foregroundStyle(.green)
			} else {
				Image(systemName: "chevron.down")
					.foregroundStyle(.red)
			}
		}
		.bold()
		.font(.caption)
	}
}

#Preview {
	DriversStandingView(sessionKey: 11280)
}

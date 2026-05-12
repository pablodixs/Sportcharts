//
//  Drivers.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/03/26.
//

import SwiftUI

struct DriversScreen: View {
	@State private var viewModel = DriversViewModel()

	var body: some View {
		NavigationStack {
			VStack {
				ScrollView {
					LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
						ForEach(viewModel.drivers, id: \.driver_number) { driver in
							driverCell(for: driver)
						}
					}
					.padding(.horizontal)
					.overlay {
						if case .loading = viewModel.state {
							ProgressView()
						}
						if case .failure(let message) = viewModel.state {
							Text(message).foregroundStyle(.red)
						}
					}
				}
				.contentMargins(.top, 16)
			}
			.task {
				await viewModel.loadDrivers(sessionKey: 11236)
			}
			.safeAreaBar(
				edge: .top,
				content: {
					HStack {
						Text("Pilotos".uppercased())
							.font(.largeTitle)
							.fontWidth(.compressed)
							.fontWeight(.bold)
						Spacer()
					}
					.padding(.horizontal)
				}
			)
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}

	@ViewBuilder
	private func driverCell(for driver: Driver) -> some View {
		NavigationLink(destination: DriverDetailScreen(driverNumber: driver.driver_number)) {
			VStack {
				AsyncImage(url: URL(string: driver.headshot_url ?? "")) { phase in
					switch phase {
					case .empty:
						ProgressView()
							.frame(width: 64, height: 64)
					case .success(let image):
						image
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(height: 80)
							.background(Color(hex: driver.team_colour))
							.clipShape(Circle())
					case .failure:
						Image(systemName: "photo")
							.frame(width: 64, height: 64)
					@unknown default:
						EmptyView()
					}
				}
				Text(driver.last_name)
					.fontWidth(.condensed)
					.fontWeight(.semibold)
					.multilineTextAlignment(.center)
					.lineLimit(2)
			}
		}
		.tint(.primary)
	}
}

#Preview {
	DriversScreen()
}

//
//  LocalDriversScreen.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/03/26.
//

import SwiftUI

struct LocalDriversScreen: View {
	@Namespace private var namespace

	@State private var searchQuery = ""

	var body: some View {
		NavigationStack {
			ScrollView {
				Text("Pilotos".uppercased())
					.font(.system(size: 72))
					.fontWeight(.black)
					.fontWidth(.compressed)
				
				LazyVGrid(
					columns: Array(repeating: GridItem(.flexible()), count: 2),
					spacing: 8
				) {
					ForEach(F1Grid2026.drivers) { driver in
						NavigationLink(
							destination: LocalDriverDetail(
								driverNumber: driver.id
							)
							.navigationTransition(
								.zoom(
									sourceID: "pilot\(driver.id)",
									in: namespace
								)
							)
						) {
							driverCardView(driver)
						}
					}
				}
			}
			.scrollIndicators(.hidden)
			.contentMargins(.horizontal, 16)
		}
	}

	@ViewBuilder
	private func driverCardView(_ driver: F1Driver) -> some View {
		ZStack {
			Text("\(driver.abbreviation)")
				.font(.system(size: 96))
				.fontWidth(.compressed)
				.bold()
				.foregroundStyle(
					LinearGradient(
						colors: [
							driver.teamColors.secondary.opacity(0.5),
							driver.teamColors.secondary.opacity(0),
						],
						startPoint: .top,
						endPoint: .bottom
					)
				)

			AsyncImage(url: driver.imageURL) { phase in
				switch phase {
				case .empty:
					EmptyView()
				case .success(let image):
					image
						.resizable()
						.aspectRatio(contentMode: .fill)
						.padding(.top, 350)
						//.frame(width: 100, height: 200)
						.clipped()

				case .failure:
					Image(systemName: "photo")
						.frame(width: 64, height: 64)
				@unknown default:
					EmptyView()
				}
			}
		}
		.frame(maxWidth: .infinity)
		.frame(height: 200)
		.background(driver.teamColors.primary)
		.overlay(
			alignment: .bottom,
			content: {
				VStack {
					Text("\(driver.lastName)".uppercased())
						.fontWidth(.compressed)
						.font(.title)
						.bold()
						.foregroundStyle(
							driver.teamColors.secondary
						)
						.lineLimit(1)
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 8)
				.background {
					LinearGradient(
						colors: [
							driver.teamColors.primary, .clear,
						],
						startPoint: .bottom,
						endPoint: .top
					)
				}
			}
		)
		.clipShape(RoundedRectangle(cornerRadius: 12))
		.matchedTransitionSource(id: "pilot\(driver.id)", in: namespace)
	}
}

#Preview {
	LocalDriversScreen()
}

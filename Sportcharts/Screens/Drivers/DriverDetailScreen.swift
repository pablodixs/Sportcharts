//
//  DriverDetailScreen.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/03/26.
//

import SwiftUI

struct DriverDetailScreen: View {
	@State private var viewModel = DriversViewModel()

	let driverNumber: Int

	var body: some View {
		VStack(alignment: .leading) {
			if viewModel.state == .loading {
				ProgressView()
			} else {
				headerView()
				
				Spacer()
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
		.background(Color.black.ignoresSafeArea())
		.foregroundStyle(.white)
		.task {
				await viewModel.loadDriver(
					driverNumber: driverNumber,
					sessionKey: 11236
				)
		}
	}

	@ViewBuilder
	private func headerView() -> some View {
		VStack(alignment: .center) {
			AsyncImage(url: URL(string: viewModel.selectedDriver?.headshot_url ?? "")) {
				phase in
				switch phase {
				case .empty:
					ProgressView()
						.frame(width: 93, height: 93)
				case .success(let image):
					image
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(height: 100)
				case .failure:
					Image(systemName: "photo")
				@unknown default:
					EmptyView()
				}
			}
			
			Text(viewModel.selectedDriver?.full_name ?? "Loading...")
				.font(.largeTitle)
				.fontWeight(.semibold)
				.fontWidth(.condensed)
			
			Text(viewModel.selectedDriver?.team_name ?? "")
				.bold()
		}
		.padding(.horizontal)
		.frame(maxWidth: .infinity, alignment: .center)
		.background(alignment: .top) {
			Text(viewModel.selectedDriver?.driver_number.description ?? "00")
				.fontWidth(.expanded)
				.bold()
				.font(.system(size: 128))
				.foregroundStyle(.white.opacity(0.2))
		}
		.background(
			LinearGradient(colors: [Color(hex: viewModel.selectedDriver?.team_colour ?? ""), .clear], startPoint: .top, endPoint: .bottom)
		)
	}
}

#Preview {
	DriverDetailScreen(driverNumber: 16)
}

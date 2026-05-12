//
//  SessionResultScreen.swift
//  Sportcharts
//
//  Created by Pablo Dias on 30/03/26.
//

import SwiftUI

struct SessionResultScreen: View {
	@State private var viewModel = SessionsViewModel()

	let sessionKey: Int

	var body: some View {
		VStack {
			if viewModel.state == .loading {
				ProgressView()
			} else {
				standingsView()
			}
		}
		.task {
			await viewModel.loadSessionResults(sessionKey: sessionKey)
		}
	}

	@ViewBuilder
	private func standingsView() -> some View {
		ForEach(viewModel.results, id: \.meetingKey) { result in
			DriverRow(result: result)
		}
	}

	struct DriverRow: View {
		let result: SessionResult

		@State private var driver: F1Driver? = nil

		var body: some View {
			VStack {
				Text(driver?.abbreviation ?? "—")
				Text(result.position?.description ?? "")
			}
			.onAppear {
				driver = F1Grid2026.driver(byNumber: result.driverNumber)
			}
		}
	}
}

#Preview {
	SessionResultScreen(sessionKey: 1281)
}

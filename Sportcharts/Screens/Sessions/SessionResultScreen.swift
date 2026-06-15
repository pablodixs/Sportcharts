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
			
			Divider()
				.padding(.vertical)
		}
		.task {
			await viewModel.loadSessionResults(sessionKey: sessionKey)
		}
	}
	
	@ViewBuilder
	private func standingsView() -> some View {
		ScrollView {
			LazyVStack(spacing: 12) {
				ForEach(viewModel.results, id: \.meetingKey) { result in
					DriverRow(result: result)
				}
			}
		}
	}
	
	struct DriverRow: View {
		let result: SessionResult
		
		@State private var driver: F1Driver? = nil
		
		var body: some View {
			HStack {
				
				Text(result.position?.description ?? "—")
					.font(.headline)
					.frame(width: 40)
				
				VStack(alignment: .leading) {
					Text(driver?.fullName ?? "Piloto")
						.font(.headline)
					
					Text(driver?.team.rawValue ?? "")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				
				Spacer()
				
				Text(driver?.abbreviation ?? "—")
					.font(.caption.bold())
			}
			.padding()
			.background(.ultraThinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 16))
			.padding(.horizontal)
			.onAppear {
				driver = F1Grid2026.driver(byNumber: result.driverNumber)
			}
		}
	}
}

#Preview {
	SessionResultScreen(sessionKey: 1281)
}

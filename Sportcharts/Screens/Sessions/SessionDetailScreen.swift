//
//  SessionDetailScreen.swift
//  Sportcharts
//
//  Created by Pablo Dias on 31/03/26.
//

import SwiftUI

struct SessionDetailScreen: View {
	let sessionKey: Int
	
	@State private var viewModel = SessionsViewModel()
	
	@State private var isChatPresented: Bool = false
	@State private var isAnalysisSheetPresented = false
	
	
	var body: some View {
		VStack {
			if case .loading = viewModel.state {
				ProgressView()
			}
			
			if case .success = viewModel.state {
				ZStack {
					ScrollView {
						Text("Resultado".uppercased())
							.font(.system(size: 48))
							.fontWeight(.black)
							.fontWidth(.compressed)
						
						Text(
							viewModel.session.first?.countryName.uppercased()
							?? ""
						)
						.fontWeight(.bold)
						.fontWidth(.condensed)
						
						HStack {
							VStack(alignment: .leading) {
								Text(viewModel.session.first?.sessionType ?? "")
									.font(.subheadline)
									.bold()
								Text(
									"\(viewModel.session.first?.circuitShortName ?? ""), \(viewModel.session.first?.countryName ?? "") "
								)
								.font(.subheadline)
							}
							
							Spacer()
							Text(
								viewModel.session.first?.formattedDateStart(
									useTrackTime: false
								) ?? ""
							)
							.font(.subheadline)
						}
						.padding(.vertical, 8)
						.padding(.horizontal)
						
						VStack(spacing: 0) {
							ForEach(viewModel.results, id: \.hashValue) {
								result in
								DriverRowView(result: result)
							}
						}
					}
					
				}
			}
			
			if case .failure(let message) = viewModel.state {
				Text(message)
					.foregroundStyle(.red)
			}
		}
		.safeAreaBar(edge: .bottom) {
			if case .success = viewModel.state {
				Button {
					isAnalysisSheetPresented.toggle()
				} label: {
					Label("Analizar sessão", systemImage: "sparkles.2")
						.padding(8)
						.bold()
				}
				.buttonStyle(.glass)
				.padding(.bottom)
			}
		}
		.toolbar {
			ToolbarItem(placement: .automatic) {
				Button("Ask Vrum", systemImage: "tire") {
					isChatPresented.toggle()
				}
			}
		}
		.fullScreenCover(
			isPresented: $isAnalysisSheetPresented,
			content: {
				SessionAnalysisScreen(
					sessionContext: buildSessionContext()
				)
				.interactiveDismissDisabled()
			}
		)
		.sheet(
			isPresented: $isChatPresented,
			content: {
				SessionChatSheet(
					sessionContext: buildSessionContext()
				)
			}
		)
		.task {
			await viewModel.loadSessionResults(sessionKey: sessionKey)
			await viewModel.loadSessionByKey(key: sessionKey)
		}
		.onDisappear {
			viewModel.reset()
		}
	}
	
	private func buildSessionContext(
		question: String? = nil
	) -> String {
		
		let sessionInfo = viewModel.session.first
		
		let header = """
   Sessão de Fórmula 1
   
   Evento: \(sessionInfo?.countryName ?? "")
   Circuito: \(sessionInfo?.circuitShortName ?? "")
   Tipo: \(sessionInfo?.sessionType ?? "")
   Data: \(sessionInfo?.formattedDateStart(useTrackTime: false) ?? "")
   """
		
		let results = viewModel.results.enumerated().map { index, result in
			
			let driver = F1Grid2026.driver(
				byNumber: result.driverNumber
			)
			
			let gapText: String
			
			switch result.gapToLeader {
			case .seconds(let seconds):
				gapText =
				seconds == 0
				? "Líder"
				: "+\(String(format: "%.3f", seconds))s"
				
			case .laps(let laps):
				gapText = laps
				
			case nil:
				gapText = "DNF"
			}
			
			return """
	Posição: \(result.position?.description ?? "--")
	Piloto: \(driver?.fullName ?? "Desconhecido")
	Equipe: \(driver?.team.rawValue ?? "")
	Número: \(result.driverNumber)
	Pontos: \(result.points)
	Voltas completadas: \(result.numberOfLaps)
	Duração: \(result.formattedDuration ?? "--")
	Gap para líder: \(gapText)
	Status:
	- DNF: \(result.dnf)
	- DSQ: \(result.dsq)
	- DNS: \(result.dns)
	"""
		}
			.joined(separator: "\n\n")
		
		var context = """
   \(header)
   
   Resultados:
   
   \(results)
   """
		
		if let question {
			context += """
	
	Pergunta do usuário:
	\(question)
	"""
		}
		
		return context
	}
}

struct DriverRowView: View {
	let result: SessionResult
	var driver: F1Driver? {
		F1Grid2026.driver(byNumber: result.driverNumber)
	}
	
	@State private var showDetails = false
	
	var body: some View {
		VStack {
			HStack {
				Text(
					result.position == nil
					? "--" : result.position?.description ?? ""
				)
				.fontWidth(.compressed)
				.bold()
				
				AsyncImage(url: driver?.imageURL) { phase in
					switch phase {
					case .empty:
						EmptyView()
							.frame(width: 64, height: 48)
					case .failure:
						EmptyView()
							.frame(width: 64, height: 48)
					case .success(let image):
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
							.padding(.top, 140)
							.frame(width: 64, height: 48)
							.clipped()
					@unknown default:
						EmptyView()
							.frame(width: 64, height: 48)
					}
				}
				
				Text(driver?.lastName.uppercased() ?? "")
					.fontWidth(.condensed)
					.font(.title3)
					.bold()
				
				Spacer()
				
				if result.points > 0 {
					Text("+\(result.points.description) p.")
						.bold()
						.font(.caption)
						.fontWidth(.condensed)
						.padding(.vertical, 2)
						.padding(.horizontal, 4)
						.foregroundStyle(
							driver?.team.colors.secondary ?? .accent
						)
						.background(
							driver?.teamColors.primary ?? .primary.opacity(0.1)
						)
						.clipShape(Capsule())
				}
				
				switch result.gapToLeader {
				case .seconds(let s):
					if s == 0 {
						Text("Líder")
							.bold()
							.font(.subheadline)
					} else {
						Text("+\(s, specifier: "%.3f")s")
							.bold()
							.font(.subheadline)
					}
				case .laps(let l):
					Text(l)
						.bold()
						.font(.subheadline)
				case nil:
					Text("DNF")
						.bold()
						.font(.subheadline)
				}
			}
			if showDetails {
				HStack(spacing: 24) {
					
					VStack(alignment: .leading) {
						Text("Nº \(result.driverNumber.description)")
							.fontWidth(.condensed)
							.bold()
							.font(.subheadline)
						
						Text("\(driver?.team.rawValue ?? "")")
							.fontWidth(.condensed)
							.bold()
							.font(.subheadline)
					}
					
					Spacer()
					
					VStack {
						Text("Duração".uppercased())
							.fontWidth(.condensed)
							.bold()
							.font(.subheadline)
						
						Text(result.formattedDuration ?? "--")
							.fontWidth(.compressed)
							.bold()
							.font(.system(size: 26))
					}
					
					VStack {
						Text("Voltas".uppercased())
							.fontWidth(.condensed)
							.bold()
							.font(.subheadline)
						Text(result.numberOfLaps.description)
							.fontWidth(.compressed)
							.bold()
							.font(.system(size: 26))
					}
				}
				.padding(.bottom)
			}
		}
		.onTapGesture {
			withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
				showDetails.toggle()
			}
		}
		.padding(.horizontal)
		.padding(.top, 4)
		.background {
			result.position == 1
			? LinearGradient(
				colors: [
					driver?.teamColors.primary ?? .clear,
					driver?.teamColors.primary ?? .clear,
				],
				startPoint: .bottom,
				endPoint: .top
			)
			: LinearGradient(
				colors: [.gray.opacity(0.05), .clear],
				startPoint: .bottom,
				endPoint: .center
			)
		}
		.foregroundStyle(
			(result.position == 1
			 ? driver?.teamColors.secondary : Color.primary) ?? .primary
		)
		.opacity(result.dnf ? 0.5 : 1)
		.opacity(result.dsq ? 0.5 : 1)
		.opacity(result.dns ? 0.5 : 1)
		.clipped()
	}
}

//#Preview {
//	SessionDetailScreen(sessionKey: 11253)
//}

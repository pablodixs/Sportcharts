//
//  LocalDriverDetail.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/03/26.
//

import SwiftUI

struct LocalDriverDetail: View {
	let driverNumber: Int

	@State private var viewModel = ChatViewModel()
	@State private var briefViewModel = DriverBriefViewModel()

	@State private var driver: F1Driver? = nil
	@State private var isFavourite: Bool = false

	@State private var screenLoaded = false
	@State private var isConstructorSheetPresented: Bool = false
	@State private var scrollOffset: CGFloat = 0
	@State private var askDialogOpen = false
	@State private var showFullBio = false
	@State private var isAskSheetOpen = false
	@State private var isBriefSheetPresented = false

	var isResponding = false

	@FocusState var focus

	var context: String {
		let first = driver?.firstName ?? ""
		let last = driver?.lastName ?? ""
		let team = driver?.team.rawValue ?? ""
		let number = driver?.number ?? 0
		return """
			Piloto:
			- Nome: \(first) \(last)
			- Equipe: \(team)
			- Número: \(number)

			Você é um engenheiro de Fórmula 1.
			Responda como um analista técnico.
			"""
	}

	let blurStart: CGFloat = 0
	let blurEnd: CGFloat = 200

	var blurRadius: CGFloat {
		let progress = (scrollOffset - blurStart) / (blurEnd - blurStart)
		return max(0, min(progress, 1)) * 20
	}

	var body: some View {
		ZStack {
			ScrollView {
				headerView()

				infoChipsView()
					.padding(.top, 4)

				if let driver {
					statsGridView(driver)
						.padding(.horizontal)
						.padding(.top, 8)
					
					driverBriefCard(driver)
						.padding(.horizontal)
						.padding(.top, 16)

					bioSectionView(driver)
						.padding(.horizontal)
						.padding(.top, 16)
				}

				Spacer(minLength: 120)
			}
			.onScrollGeometryChange(for: CGFloat.self) { geo in
				geo.contentOffset.y
			} action: { oldValue, newValue in
				scrollOffset = max(0, newValue)
			}

			if askDialogOpen {
				askDialog()
			}
		}
		.safeAreaBar(
			edge: .bottom,
			content: {
				GlassEffectContainer(spacing: 4) {
					HStack {

						Button(
							"Pergunte ao Vrum",
							systemImage: "sparkles.2"
						) {
							isAskSheetOpen.toggle()
						}
						.labelStyle(.titleAndIcon)
						.foregroundStyle(.foreground)
						.padding()
						.bold()
						.glassEffect(
							.regular.interactive(),
							in: askDialogOpen
								? AnyShape(Circle()) : AnyShape(Capsule())
						)
					}
					.padding()
				}
			}
		)
		.frame(maxWidth: .infinity)
		.foregroundStyle(driver?.team.colors.secondary ?? .primary)
		.background(driver?.teamColors.primary.ignoresSafeArea())
		.sheet(isPresented: $isConstructorSheetPresented) {
			ConstructorDetailScreen(
				constructor: F1Team(rawValue: (driver?.team)!.rawValue)
					?? .alpine
			)
		}
		.sheet(isPresented: $isAskSheetOpen) {
			AskDriverScreen(driver: driver)
				.interactiveDismissDisabled()
		}
		.sheet(isPresented: $isBriefSheetPresented) {
			if let driver {
				DriverBriefSheet(
					driver: driver,
					brief: briefViewModel.brief,
					state: briefViewModel.state
				)
			}
		}
		.onAppear {
			driver = F1Grid2026.driver(byNumber: driverNumber)

			withAnimation {
				screenLoaded.toggle()
			}
		}
		.task(id: driverNumber) {
			guard let driver = F1Grid2026.driver(byNumber: driverNumber) else {
				return
			}
			
			await briefViewModel.loadBrief(for: driver)
		}
	}

	@ViewBuilder
	private func headerView() -> some View {
		ZStack(alignment: .bottom) {
			AsyncImage(url: driver?.imageURL) { phase in
				switch phase {
				case .empty:
					ProgressView()
						.frame(maxWidth: .infinity, minHeight: 400)
				case .success(let image):
					image
						.resizable()
						.aspectRatio(contentMode: .fill)
						.padding(.top, 480)
						.frame(maxWidth: 300, maxHeight: 500)
						.clipped()
						.overlay(alignment: .bottom) {
							LinearGradient(
								colors: [
									driver?.teamColors.primary ?? .clear,
									.clear,
								],
								startPoint: .bottom,
								endPoint: .center
							)
						}
						.blur(radius: blurRadius)

				case .failure:
					Image(systemName: "person.fill")
						.font(.system(size: 80))
						.foregroundStyle(.tertiary)
						.frame(maxWidth: 300, maxHeight: 500)
				@unknown default:
					EmptyView()
						.frame(maxWidth: .infinity)
				}
			}
			.background(alignment: .top) {
				VStack {
					Text(driver?.firstName ?? "")
						.fontWidth(.expanded)
						.font(.title3)
						.bold()
						.foregroundStyle(
							driver?.teamColors.secondary ?? Color.accentColor
						)
						.lineHeight(.tight)
						.opacity(screenLoaded ? 1 : 0)
						.animation(.spring.delay(0.5), value: screenLoaded)

					Text(driver?.lastName.uppercased() ?? "")
						.font(.system(size: 64))
						.fontWidth(.compressed)
						.fontWeight(.heavy)
						.foregroundStyle(
							driver?.teamColors.secondary ?? Color.accentColor
						)
						.offset(y: screenLoaded ? 0 : 50)
						.opacity(screenLoaded ? 1 : 0)
						.animation(.spring.delay(0.25), value: screenLoaded)
				}
			}

			Button {
				withAnimation {
					isFavourite.toggle()
				}
			} label: {
				Label(
					isFavourite ? "Seguindo" : "Seguir",
					systemImage: isFavourite ? "star.fill" : "star"
				)
				.padding(4)
				.foregroundStyle(driver?.teamColors.secondary ?? Color.primary)
				.bold()
			}
			.buttonStyle(.glass(.clear))
		}
		.padding(.horizontal)
	}

	@ViewBuilder
	private func infoChipsView() -> some View {
		HStack(spacing: 12) {
			// Number chip
			Text("#\(driver?.number.description ?? "")")
				.font(.title3)
				.fontWidth(.condensed)
				.fontWeight(.heavy)

			// Nationality chip
			HStack(spacing: 4) {
				Text(driver?.flagEmoji ?? "")
				Text(driver?.nationalityName ?? "")
					.font(.subheadline)
			}
			.fontWeight(.semibold)

			// Team chip
			Button {
				isConstructorSheetPresented.toggle()
			} label: {
				HStack(spacing: 6) {
					AsyncImage(url: driver?.teamLogoURL) { phase in
						switch phase {
						case .success(let image):
							image
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(width: 24, height: 24)
						default:
							EmptyView()
								.frame(width: 24, height: 24)
						}
					}
					Text(driver?.team.rawValue ?? "")
						.font(.subheadline)
				}
				.fontWeight(.semibold)
			}
		}
		.fontWidth(.condensed)
		.padding(.vertical, 8)
	}

	@ViewBuilder
	private func statsGridView(_ driver: F1Driver) -> some View {
		let columns = Array(
			repeating: GridItem(.flexible(), spacing: 12),
			count: 2
		)

		LazyVGrid(columns: columns, spacing: 12) {
			statCard(
				title: "Equipe",
				value: driver.team.rawValue,
				icon: "flag.checkered"
			)
			statCard(
				title: "Motor",
				value: driver.constructor.motorFornecedor,
				icon: "engine.combustion"
			)
			statCard(
				title: "Status",
				value: driver.isRookie ? "Rookeiro" : "Titular",
				icon: driver.isRookie ? "sparkle" : "trophy"
			)
			statCard(
				title: "Construtores",
				value: "\(driver.constructor.titulos) titulo(s)",
				icon: "medal"
			)
		}
	}

	@ViewBuilder
	private func statCard(title: String, value: String, icon: String)
		-> some View
	{
		VStack(alignment: .leading, spacing: 6) {
			Image(systemName: icon)
				.font(.title3)
				.foregroundStyle(
					driver?.teamColors.secondary.opacity(0.7) ?? .secondary
				)

			Text(title)
				.font(.caption)
				.foregroundStyle(
					driver?.teamColors.secondary.opacity(0.6) ?? .secondary
				)
				.fontWidth(.condensed)

			Text(value)
				.font(.subheadline)
				.fontWeight(.bold)
				.fontWidth(.condensed)
				.lineLimit(1)
				.minimumScaleFactor(0.8)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(12)
		.background(
			driver?.teamColors.secondary.opacity(0.08)
				?? Color.secondary.opacity(0.08)
		)
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}
	
	@ViewBuilder
	private func driverBriefCard(_ driver: F1Driver) -> some View {
		Button {
			isBriefSheetPresented = true
		} label: {
			VStack(alignment: .leading, spacing: 12) {
				HStack(spacing: 8) {
					Image(systemName: "chart.line.uptrend.xyaxis")
						.font(.headline)
					
					Text("Brief de performance")
						.font(.headline)
						.fontWidth(.condensed)
						.bold()
					
					Spacer()
					
					Image(systemName: "chevron.right")
						.font(.caption)
						.fontWeight(.bold)
						.foregroundStyle(driver.teamColors.secondary.opacity(0.55))
				}
				
				switch briefViewModel.state {
				case .idle, .loading:
					HStack(spacing: 10) {
						ProgressView()
						Text("Lendo dados recentes...")
							.font(.subheadline)
							.foregroundStyle(driver.teamColors.secondary.opacity(0.7))
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.vertical, 8)
					
				case .success:
					if let brief = briefViewModel.brief {
						Text(brief.headline)
							.font(.title3)
							.fontWidth(.condensed)
							.fontWeight(.heavy)
							.multilineTextAlignment(.leading)
							.frame(maxWidth: .infinity, alignment: .leading)
						
						VStack(alignment: .leading, spacing: 6) {
							ForEach(Array(brief.strengths.prefix(2)), id: \.self) { item in
								briefBullet(item, icon: "plus.circle.fill")
							}
							
							if let watchout = brief.watchouts.first {
								briefBullet(watchout, icon: "exclamationmark.circle.fill")
							}
						}
					} else {
						Text("Ainda não há dados recentes suficientes para um brief.")
							.font(.subheadline)
							.foregroundStyle(driver.teamColors.secondary.opacity(0.75))
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					
				case .failure:
					Text("Não foi possível carregar os dados recentes agora.")
						.font(.subheadline)
						.foregroundStyle(driver.teamColors.secondary.opacity(0.75))
						.frame(maxWidth: .infinity, alignment: .leading)
				}
			}
			.padding(14)
			.foregroundStyle(driver.teamColors.secondary)
			.background(driver.teamColors.secondary.opacity(0.08))
			.clipShape(RoundedRectangle(cornerRadius: 12))
		}
		.buttonStyle(.plain)
	}
	
	@ViewBuilder
	private func briefBullet(_ text: String, icon: String) -> some View {
		HStack(alignment: .top, spacing: 8) {
			Image(systemName: icon)
				.font(.caption)
				.padding(.top, 2)
			
			Text(text)
				.font(.caption)
				.fontWeight(.semibold)
				.lineLimit(2)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
		.foregroundStyle(driver?.teamColors.secondary.opacity(0.76) ?? .secondary)
	}

	@ViewBuilder
	private func bioSectionView(_ driver: F1Driver) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Bio")
				.bold()
				.fontWidth(.expanded)
				.font(.headline)

			Text(driver.bio)
				.font(.subheadline)
				.lineLimit(showFullBio ? nil : 4)
				.foregroundStyle(driver.teamColors.secondary.opacity(0.8))

			Button {
				withAnimation(.easeInOut(duration: 0.3)) {
					showFullBio.toggle()
				}
			} label: {
				Text(showFullBio ? "Mostrar menos" : "Ler mais")
					.font(.caption)
					.fontWeight(.semibold)
					.foregroundStyle(driver.teamColors.secondary.opacity(0.6))
			}
		}
	}

	@ViewBuilder
	private func askDialog() -> some View {
		VStack(alignment: .leading) {
			Text("Ask Vrum".uppercased())
				.font(.largeTitle)
				.bold()
				.fontWidth(.condensed)
			HStack {
				AsyncImage(url: driver?.imageURL ?? nil) { phase in
					switch phase {
					case .empty:
						EmptyView()
					case .failure:
						EmptyView()
					case .success(let image):
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
							.padding(.top, 100)
							.frame(width: 48, height: 48)
							.background(
								driver?.teamColors.primary
							)
							.clipShape(Circle())
					@unknown default:
						EmptyView()
					}
				}
				Text("\(driver?.firstName ?? "") \(driver?.lastName ?? "")")
					.bold()
			}
			ScrollViewReader { proxy in

				ScrollView {

					LazyVStack(spacing: 12) {

						ForEach(viewModel.messages) { message in

							MessageBubble(
								message: message,
								accent: driver?.teamColors.accent ?? .blue
							)
							.id(message.id)
						}
					}
				}
				.onChange(of: viewModel.messages) {

					guard let last = viewModel.messages.last else {
						return
					}

					withAnimation(.smooth) {

						proxy.scrollTo(
							last.id,
							anchor: .bottom
						)
					}
				}
			}
		}
		.padding()
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(.background)
		.ignoresSafeArea(.keyboard)
		.foregroundStyle(.foreground)
		.onTapGesture {
			focus = false
		}
		.onAppear {
			focus = true
		}
		.onDisappear {
			focus = false
		}
	}

	@ViewBuilder
	private func messageDialog(_ message: String) -> some View {
		HStack {
			Spacer()
			VStack {
				Text(message)
			}
			.padding(.horizontal)
			.padding(.vertical, 8)
			.background(driver?.teamColors.primary ?? Color.gray.opacity(0.1))
			.clipShape(Capsule())
		}
	}
}

private struct DriverBriefSheet: View {
	@Environment(\.dismiss) private var dismiss
	
	let driver: F1Driver
	let brief: DriverBrief?
	let state: DriverBriefViewModel.State
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 20) {
					header
					
					switch state {
					case .idle, .loading:
						HStack(spacing: 12) {
							ProgressView()
							Text("Montando brief de performance...")
								.font(.subheadline)
								.foregroundStyle(.secondary)
						}
						.padding(.vertical, 24)
						
					case .success:
						if let brief {
							briefContent(brief)
						} else {
							emptyState
						}
						
					case .failure:
						Text("Não foi possível carregar os dados recentes agora.")
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
				}
				.padding()
			}
			.background(driver.teamColors.primary.ignoresSafeArea())
			.foregroundStyle(driver.teamColors.secondary)
			.navigationTitle("Brief")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .close) {
						dismiss()
					}
				}
			}
		}
	}
	
	private var header: some View {
		HStack(spacing: 12) {
			AsyncImage(url: driver.imageURL) { phase in
				switch phase {
				case .success(let image):
					image
						.resizable()
						.aspectRatio(contentMode: .fill)
						.padding(.top, 100)
						.frame(width: 54, height: 54)
						.background(driver.teamColors.primary)
						.clipShape(Circle())
				default:
					Image(systemName: "person.fill")
						.frame(width: 54, height: 54)
						.background(driver.teamColors.secondary.opacity(0.12))
						.clipShape(Circle())
				}
			}
			
			VStack(alignment: .leading, spacing: 2) {
				Text(driver.fullName)
					.font(.title3)
					.fontWidth(.condensed)
					.bold()
				
				Text("#\(driver.number) • \(driver.team.rawValue)")
					.font(.caption)
					.foregroundStyle(driver.teamColors.secondary.opacity(0.7))
			}
			
			Spacer()
		}
	}
	
	@ViewBuilder
	private func briefContent(_ brief: DriverBrief) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(brief.headline)
				.font(.largeTitle)
				.fontWidth(.condensed)
				.fontWeight(.heavy)
				.lineLimit(3)
			
			Text(brief.formSummary)
				.font(.subheadline)
				.foregroundStyle(driver.teamColors.secondary.opacity(0.78))
		}
		
		briefSection(
			title: "Pontos fortes",
			icon: "plus.circle.fill",
			items: brief.strengths
		)
		
		briefSection(
			title: "Pontos de atenção",
			icon: "exclamationmark.circle.fill",
			items: brief.watchouts
		)
	}
	
	private var emptyState: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Dados recentes insuficientes")
				.font(.title2)
				.fontWidth(.condensed)
				.bold()
			
			Text("A OpenF1 ainda não retornou resultados recentes suficientes para montar um brief confiável deste piloto.")
				.font(.subheadline)
				.foregroundStyle(driver.teamColors.secondary.opacity(0.75))
		}
	}
	
	@ViewBuilder
	private func briefSection(
		title: String,
		icon: String,
		items: [String]
	) -> some View {
		if !items.isEmpty {
			VStack(alignment: .leading, spacing: 10) {
				Label(title, systemImage: icon)
					.font(.headline)
					.fontWidth(.condensed)
					.bold()
				
				VStack(alignment: .leading, spacing: 8) {
					ForEach(items, id: \.self) { item in
						HStack(alignment: .top, spacing: 8) {
							Circle()
								.frame(width: 5, height: 5)
								.padding(.top, 7)
							
							Text(item)
								.font(.subheadline)
								.frame(maxWidth: .infinity, alignment: .leading)
						}
						.foregroundStyle(driver.teamColors.secondary.opacity(0.78))
					}
				}
			}
			.padding(14)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(driver.teamColors.secondary.opacity(0.08))
			.clipShape(RoundedRectangle(cornerRadius: 12))
		}
	}
}

#Preview {
	LocalDriverDetail(driverNumber: 12)
}

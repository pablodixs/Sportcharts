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

	@State private var driver: F1Driver? = nil
	@State private var isFavourite: Bool = false

	@State private var screenLoaded = false
	@State private var isConstructorSheetPresented: Bool = false
	@State private var scrollOffset: CGFloat = 0
	@State private var askDialogOpen = false
	@State private var showFullBio = false
	@State private var isAskSheetOpen = false

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
		.onAppear {
			driver = F1Grid2026.driver(byNumber: driverNumber)

			withAnimation {
				screenLoaded.toggle()
			}
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

#Preview {
	LocalDriverDetail(driverNumber: 12)
}

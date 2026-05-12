//
//  ConstructorDetailScreen.swift
//  Sportcharts
//
//  Created by Pablo Dias on 30/03/26.
//

import SwiftUI

struct ConstructorDetailScreen: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.colorScheme) private var colorScheme: ColorScheme

	let constructor: F1Team

	@State private var drivers: [F1Driver] = []
	@State private var showBio: Bool = false

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading) {
					VStack {
						AsyncImage(url: constructor.logoURL) { phase in
							switch phase {
							case .empty:
								EmptyView()
							case .failure:
								EmptyView()
							case .success(let image):
								image
									.resizable()
									.aspectRatio(contentMode: .fit)
									.frame(width: 72)
									.padding()
									.background(constructor.colors.primary)
									.clipShape(Circle())
							@unknown default:
								EmptyView()
							}
							
							Text(constructor.rawValue)
								.font(.title)
								.fontWeight(.bold)
								.fontWidth(.expanded)
						}
						.frame(maxWidth: .infinity)
						
						HStack {
							Button {
							} label: {
								Label("Seguir", systemImage: "star")
									.padding(4)
							}
							.buttonStyle(.glass)
							
							Button {
							} label: {
								Label("Saiba mais", systemImage: "info.circle")
									.labelStyle(.iconOnly)
									.padding(.vertical, 4)
							}
							.buttonStyle(.glass)
						}
					}
					
					VStack(alignment: .leading, spacing: 24) {
						Text("Pilotos")
							.font(.title3)
							.fontWidth(.expanded)
							.bold()
							.padding(.top)
						
						HStack(spacing: 24) {
							ForEach(drivers) { driver in
								VStack {
									AsyncImage(url: driver.imageURL) { phase in
										switch phase {
										case .empty:
											EmptyView()
										case .failure:
											EmptyView()
										case .success(let image):
											image
												.resizable()
												.aspectRatio(contentMode: .fill)
												.padding(.top, 220)
												.frame(width: 100, height: 100)
												.background(
													constructor.colors.primary
												)
												.clipShape(Circle())
												.overlay(alignment: .bottomTrailing)
											{
												Text(driver.flagEmoji)
													.padding(6)
													.background(
														Circle()
															.stroke(lineWidth: 1)
															.foregroundStyle(
																.gray.quaternary
															)
													)
													.background(.background)
													.clipShape(Circle())
											}
										@unknown default:
											EmptyView()
										}
									}
									
									VStack {
										Text(driver.fullName)
										
										Text(driver.number.description)
											.fontWidth(.expanded)
											.font(.caption)
											.foregroundStyle(.gray)
									}
									.bold()
									.font(.subheadline)
								}
							}
						}
						
						aboutSectionView()
					}
				}
				.padding(.horizontal)
			}
			.onAppear {
				drivers = F1Grid2026.drivers(for: constructor)
			}
			.toolbar {
				Button(role: .close) {
					dismiss()
				}
			}
		}
	}

	@ViewBuilder
	private func aboutSectionView() -> some View {
		VStack(alignment: .leading) {
			Text("Sobre a \(constructor.constructor.nome)")
				.font(.title3)
				.fontWidth(.expanded)
				.bold()
				.padding(.bottom, 2)

			Text(constructor.constructor.bio)
				.lineLimit(showBio ? nil : 3)
				.foregroundStyle(.secondary)
				.padding(.bottom, 4)
				.onTapGesture {
					withAnimation {
						showBio.toggle()
					}
				}

			
			VStack(alignment: .leading, spacing: 8) {
				Text("Ano de estreia na F1: **\(constructor.constructor.estreiaF1.description)**")
				Text("País sede: **\(constructor.constructor.pais)**")
				Text("Fornecedor de motores: **\(constructor.constructor.motorFornecedor)**")
				Text("Fundação: **\(constructor.constructor.fundacao.description)**")
				Text("Sede: **\(constructor.constructor.sede)**")
			}
		}
	}
}

#Preview {
	ConstructorDetailScreen(constructor: .mclaren)
}

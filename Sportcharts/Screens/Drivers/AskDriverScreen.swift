//
//  AskDriver.swift
//  Sportcharts
//
//  Created by Pablo Dias on 11/05/26.
//

import SwiftUI

struct AskDriverScreen: View {
	@Environment(\.dismiss) var dismiss

	let driver: F1Driver?

	@State private var viewModel = ChatViewModel()

	@FocusState private var isFocused: Bool

	var body: some View {
		NavigationStack {
			VStack(alignment: .leading) {
				ScrollViewReader { proxy in
					if viewModel.messages.count == 0 {
						VStack {
							Image(systemName: "tire")
								.font(.system(size: 42))
								.foregroundStyle(driver?.teamColors.accent ?? .accent)
								.symbolEffect(.rotate.byLayer, options: .repeat(.continuous))
							Text("Pergunte ao Vrum")
								.bold()
								.font(.title)
							Text("Pergunte sobre estratégia, pneus, desempenho, telemetria e tudo que acontece dentro e fora da pista.")
								.multilineTextAlignment(.center)
								.font(.subheadline)
								.foregroundStyle(.gray)
						}
						.frame(maxHeight: .infinity)
						.padding()
					} else {
						ScrollView {
							LazyVStack(spacing: 12) {


								ForEach(viewModel.messages) { message in

									MessageBubble(
										message: message,
										accent: driver?.teamColors.primary ?? .blue
									)
									.id(message.id)
								}
							}
							.padding(.horizontal)
							.padding(.bottom)
						}
						.defaultScrollAnchor(.top)
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
				}
				.safeAreaBar(edge: .bottom) {
					GlassEffectContainer {
						VStack(alignment: .leading, spacing: 8) {
							DriverMentionSuggestionsView(text: $viewModel.input)

							HStack {
								TextField(
									"Pergunte ao Vrum",
									text: $viewModel.input
								)
								.focused($isFocused)
								.scrollDismissesKeyboard(.automatic)
								.padding()
								.foregroundStyle(.foreground)
								.clipShape(Capsule())
								.glassEffect(.regular.interactive(), in: .capsule)

								Button {
									isFocused = false
									Task {
										await viewModel.sendMessage(
											driver: driver
										)
									}
								} label: {
									if viewModel.isResponding {
										ProgressView()
									} else {
										Label("Enviar", systemImage: "arrow.up")
									}
								}
								.disabled(
									viewModel.input.isEmpty || viewModel.isResponding
								)
								.padding(16)
								.labelStyle(.iconOnly)
								.background(
									driver?.teamColors.accent ?? .accent
								)
								.foregroundStyle(
									driver?.teamColors.secondary ?? .accent
								)
								.clipShape(Circle())
								.glassEffect(.regular.interactive(), in: .circle)
								.bold()
							}
						}
					}
					.padding(.horizontal)
				.padding(.bottom, 8)
			}
			.toolbar {
				ToolbarItem(placement: .title) {
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
									.padding(.top, 90)
									.frame(width: 42, height: 42)
									.background(
										driver?.teamColors.primary
									)
									.clipShape(Circle())
							@unknown default:
								EmptyView()
							}
						}
						VStack {
							Text(
								"\(driver?.lastName.uppercased() ?? "")"
							)
							.fontWidth(.condensed)
							.font(.title3)
							.bold()
						}
					}				}

				ToolbarItem(placement: .cancellationAction) {
					Button(role: .close) {
						dismiss()
					}
				}

				ToolbarItem(placement: .automatic) {
					Menu("Menu", systemImage: "ellipsis") {
						Button("Saiba mais...", systemImage: "questionmark.circle") {}
					}
				}
			}
			.onAppear {
				isFocused = true
			}
		}
	}
}

//
//  SessionAnalyseScreen.swift
//  Sportcharts
//
//  Created by Pablo Dias on 13/05/26.
//

import SwiftUI
import UIKit

enum AnalysisBackgroundState {
	case idle
	case isResponding
}

struct AnimatedMeshBackground: View {
	let state: AnalysisBackgroundState

	@State private var backgroundOpacity: Double = 0

	var body: some View {
		ZStack {
			TimelineView(.animation) { timeline in
				let time = timeline.date.timeIntervalSinceReferenceDate

				Canvas { context, size in
					let rect = CGRect(origin: .zero, size: size)

					context.fill(
						Path(rect),
						with: .linearGradient(
							Gradient(colors: backgroundColors),
							startPoint: CGPoint(x: 0, y: size.height),
							endPoint: CGPoint(x: size.width, y: 0)
						)
					)

					for blob in blobs(time: time, size: size) {
						context.addFilter(.blur(radius: 90))
						context.fill(
							Path(ellipseIn: blob.frame),
							with: .color(blob.color)
						)
					}
				}
			}
			.opacity(backgroundOpacity)
		}
		.ignoresSafeArea()
		.transition(.opacity)
		.animation(.easeInOut(duration: 0.5), value: backgroundOpacity)
		.onAppear {
			backgroundOpacity = state == .idle ? 0.15 : 1
		}
		.onChange(of: state) { _, newValue in
			withAnimation(.easeInOut(duration: 0.35)) {
				backgroundOpacity = 0
			}

			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				withAnimation(.easeInOut(duration: 0.5)) {
					backgroundOpacity = newValue == .idle ? 0.15 : 1
				}
			}
		}
	}

	private var backgroundColors: [Color] {
		switch state {
		case .idle:
			return [.clear, .clear]
		case .isResponding:
			return [.clear, .clear, .clear]
		}
	}

	private func blobs(time: Double, size: CGSize) -> [(
		frame: CGRect, color: Color
	)] {
		switch state {
		case .idle:
			return [
				(
					CGRect(
						x: size.width * 0.2,
						y: size.height * 0.7,
						width: 220,
						height: 220
					),
					.white.opacity(0.03)
				)
			]

		case .isResponding:
			let x1 = sin(time * 0.6) * 60
			let y1 = cos(time * 0.5) * 50

			let x2 = cos(time * 0.4) * 80
			let y2 = sin(time * 0.7) * 70

			let x3 = sin(time * 0.3) * 50
			let y3 = cos(time * 0.8) * 60

			return [
				(
					CGRect(
						x: size.width * 0.05 + x1,
						y: size.height * 0.15 + y1,
						width: 260,
						height: 260
					),
					.cyan.opacity(0.5)
				),
				(
					CGRect(
						x: size.width * 0.45 + x2,
						y: size.height * 0.55 + y2,
						width: 300,
						height: 300
					),
					.blue.opacity(0.25)
				),
				(
					CGRect(
						x: size.width * 0.65 + x3,
						y: size.height * 0.2 + y3,
						width: 240,
						height: 240
					),
					.blue.opacity(0.2)
				),
			]
		}
	}
}

struct SessionAnalysisScreen: View {
	let sessionContext: String
	private let bottomAnchorID = "session-analysis-bottom-anchor"

	@Environment(\.dismiss) var dismiss

	@State private var screenLoaded = false
	@State private var moveGradient = false
	@State private var isSessionChatPresented = false
	@State private var selectedPilotNumber: Int?
	@State private var showCopiedAlert = false

	@StateObject private var viewModel = SessionAnalysisViewModel()

	var body: some View {
		NavigationStack {
			ScrollViewReader { proxy in
				ScrollView {
					messagesStack()
						.id("session-analysis-content")

					Color.clear
						.frame(height: 1)
						.id(bottomAnchorID)
				}
				.scrollClipDisabled()
				.onChange(of: viewModel.messages.last?.content) { _, _ in
					scrollToBottom(with: proxy)
				}
				.onChange(of: viewModel.messages.count) { _, _ in
					scrollToBottom(with: proxy)
				}
			}
			.background {
				ZStack {
					AnimatedMeshBackground(state: .idle)

					SessionAnalysisAmbientLight(
						isActive: viewModel.isResponding,
						tint: .cyan
					)
				}
			}
			.overlay(alignment: .bottom) {
				if viewModel.isResponding {
					analysisStatusBadge()
						.padding(.bottom, 18)
						.transition(.move(edge: .bottom).combined(with: .opacity))
				}
			}
			.onAppear {
				DispatchQueue.main.async {
					screenLoaded = true
				}
			}
			.task {
				await viewModel.startSessionAnalysis(
					sessionContext: sessionContext
				)
			}
			.navigationTitle("Análise da Sessão")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .close) {
						dismiss()
					}
				}

				if viewModel.isResponding {
					ToolbarItem {
						ProgressView()
					}
				}

				ToolbarItem {
					Menu {
						Button("Perguntar ao Vrum", systemImage: "tire") {
							isSessionChatPresented = true
						}

						Button("Copiar análise", systemImage: "doc.on.doc") {
							guard !viewModel.analysisText.isEmpty else {
								return
							}
							UIPasteboard.general.string = viewModel.analysisText
							showCopiedAlert = true
						}

						ShareLink(
							item: viewModel.analysisText,
							subject: Text("Análise da Sessão"),
							message: Text("Resumo gerado pelo Sportcharts")
						) {
							Label(
								"Compartilhar",
								systemImage: "square.and.arrow.up"
							)
						}
					} label: {
						Label("Opções", systemImage: "ellipsis")
					}
					.disabled(viewModel.analysisText.isEmpty)
				}
			}
			.alert("Análise copiada", isPresented: $showCopiedAlert) {
				Button("OK", role: .cancel) {}

			}
			.sheet(isPresented: $isSessionChatPresented) {
				SessionChatSheet(
					sessionContext: sessionContext,
					smartQuestions: viewModel.smartQuestions
				)
			}
			.sheet(
				isPresented: Binding(
					get: { selectedPilotNumber != nil },
					set: { isPresented in
						if !isPresented {
							selectedPilotNumber = nil
						}
					}
				)
			) {
				if let selectedPilotNumber {
					LocalDriverDetail(driverNumber: selectedPilotNumber)
				} else {
					EmptyView()
				}
			}
		}
	}

	private func scrollToBottom(with proxy: ScrollViewProxy) {
		DispatchQueue.main.async {
			withAnimation(.easeOut(duration: 0.18)) {
				proxy.scrollTo(bottomAnchorID, anchor: .bottom)
			}
		}
	}

	@ViewBuilder
	func textGlow(_ text: String) -> some View {
		Text(text)
			.overlay {
				GeometryReader { proxy in
					LinearGradient(
						colors: [.clear, .white.opacity(0.85), .clear],
						startPoint: .leading,
						endPoint: .trailing
					)
					.frame(width: proxy.size.width * 0.8)
					.offset(
						x: moveGradient ? proxy.size.width : -proxy.size.width
					)
				}
				.mask {
					Text(text)
				}
			}
			.animation(
				.linear(duration: 2.5)
					.repeatForever(autoreverses: false)
					.delay(0.25),
				value: moveGradient
			)
			.fixedSize()
			.onAppear {
				DispatchQueue.main.async {
					withAnimation {
						moveGradient = true
					}
				}
			}
	}

	@ViewBuilder
	func analysisStatusBadge() -> some View {
		HStack(spacing: 8) {
			Image(systemName: "sparkles.2")
				.symbolEffect(
					.breathe.byLayer,
					options: .repeat(.continuous)
				)

			textGlow("Lendo dados da sessão")
				.animation(nil, value: screenLoaded)
				.fontWeight(.semibold)
		}
		.font(.subheadline)
		.foregroundStyle(.primary)
		.padding(.vertical, 9)
		.padding(.horizontal, 14)
		.background(.ultraThinMaterial)
		.clipShape(Capsule())
		.shadow(color: .cyan.opacity(0.18), radius: 18, y: 8)
	}

	@ViewBuilder
	func messagesStack() -> some View {
		LazyVStack(alignment: .leading, spacing: 12) {
			ForEach(viewModel.messages) { message in
				MarkdownMessageText(
					message.content,
					pilots: viewModel.pilots
				) { driver in
					selectedPilotNumber = driver.number
				}
					.id(message.id)
					.lineHeight(.loose)
			}
		}
		.padding(.horizontal)
		.padding(.bottom)
	}

}

private struct MarkdownMessageText: View {
	let content: String
	let pilots: [F1Driver]
	let onSelectPilot: (F1Driver) -> Void

	init(
		_ content: String,
		pilots: [F1Driver] = [],
		onSelectPilot: @escaping (F1Driver) -> Void = { _ in }
	) {
		self.content = content
		self.pilots = pilots
		self.onSelectPilot = onSelectPilot
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			ForEach(markdownBlocks) { block in
				markdownBlock(block)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	private var markdownBlocks: [MarkdownBlock] {
		let lines = content.components(separatedBy: .newlines)
		var blocks: [MarkdownBlock] = []
		var index = 0

		while index < lines.count {
			let line = lines[index]

			if isTableLine(line) {
				var tableLines: [String] = []
				let blockID = index

				while index < lines.count && isTableLine(lines[index]) {
					tableLines.append(lines[index])
					index += 1
				}

				let rows = tableLines
					.map(tableCells)
					.filter { !$0.isEmpty }
					.filter { !isTableSeparator($0) }

				if rows.count > 1 {
					blocks.append(.table(id: blockID, rows: rows))
				} else {
					for tableLine in tableLines {
						blocks.append(.line(id: blocks.count, text: tableLine))
					}
				}

				continue
			}

			blocks.append(.line(id: index, text: line))
			index += 1
		}

		return blocks
	}

	@ViewBuilder
	private func markdownBlock(_ block: MarkdownBlock) -> some View {
		switch block {
		case .line(_, let text):
			markdownLine(text)
		case .table(_, let rows):
			markdownTable(rows)
		}
	}

	@ViewBuilder
	private func markdownLine(_ line: String) -> some View {
		let trimmed = line.trimmingCharacters(in: .whitespaces)

		if trimmed.isEmpty {
			Spacer()
				.frame(height: 4)
		} else if trimmed.hasPrefix("### ") {
			lineWithPilotChips(
				text: String(trimmed.dropFirst(4)),
				font: .headline,
				weight: .bold
			)
			.padding(.top, 4)
		} else if trimmed.hasPrefix("## ") {
			lineWithPilotChips(
				text: String(trimmed.dropFirst(3)),
				font: .title3,
				weight: .black,
				fontWidth: .condensed
			)
			.padding(.top, 8)
		} else if trimmed.hasPrefix("# ") {
			lineWithPilotChips(
				text: String(trimmed.dropFirst(2)),
				font: .title2,
				weight: .black,
				fontWidth: .condensed
			)
			.padding(.top, 8)
		} else if trimmed.hasPrefix("- ") {
			HStack(alignment: .top, spacing: 8) {
				Text("•")
					.fontWeight(.bold)
					.padding(.top, 1)
				lineWithPilotChips(text: String(trimmed.dropFirst(2)))
			}
		} else if trimmed.hasPrefix("> ") {
			HStack(alignment: .top, spacing: 10) {
				Rectangle()
					.fill(.secondary.opacity(0.35))
					.frame(width: 3)
				lineWithPilotChips(
					text: String(trimmed.dropFirst(2)),
					font: .footnote,
					foregroundStyle: .secondary
				)
			}
			.padding(.vertical, 4)
		} else {
			lineWithPilotChips(text: line)
		}
	}

	@ViewBuilder
	private func lineWithPilotChips(
		text: String,
		font: Font = .body,
		weight: Font.Weight? = nil,
		fontWidth: Font.Width = .standard,
		foregroundStyle: Color = .primary
	) -> some View {
		let tokens = inlineTokens(for: text)

		if tokens.allSatisfy(\.isText) {
			inlineText(text)
				.font(font)
				.fontWeight(weight)
				.fontWidth(fontWidth)
				.foregroundStyle(foregroundStyle)
				.frame(maxWidth: .infinity, alignment: .leading)
		} else {
				PilotInlineFlow(horizontalSpacing: 1, verticalSpacing: 5) {
				ForEach(tokens) { token in
					switch token.kind {
					case .text(let value):
						inlineText(value)
							.font(font)
							.fontWeight(weight)
							.fontWidth(fontWidth)
							.foregroundStyle(foregroundStyle)
					case .pilot(let driver):
						inlinePilotButton(driver)
							.alignmentGuide(.firstTextBaseline) { dimensions in
								dimensions[VerticalAlignment.center]
							}
					}
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}

	@ViewBuilder
	private func markdownTable(_ rows: [[String]]) -> some View {
		ScrollView(.horizontal) {
			Grid(horizontalSpacing: 0, verticalSpacing: 0) {
				ForEach(rows.indices, id: \.self) { rowIndex in
					GridRow {
						ForEach(rows[rowIndex].indices, id: \.self) { columnIndex in
							let value = rows[rowIndex][columnIndex]

							tableCell(
								value,
								isHeader: rowIndex == 0,
								mentionedPilots: pilotsMentioned(in: value)
							)
						}
					}
				}
			}
			.clipShape(RoundedRectangle(cornerRadius: 10))
			.overlay {
				RoundedRectangle(cornerRadius: 10)
					.stroke(.secondary.opacity(0.18), lineWidth: 1)
			}
		}
		.scrollClipDisabled()
		.scrollIndicators(.hidden)
	}

	@ViewBuilder
	private func tableCell(
		_ value: String,
		isHeader: Bool,
		mentionedPilots: [F1Driver]
	) -> some View {
		VStack(alignment: .leading, spacing: 6) {
			inlineText(value)
				.font(isHeader ? .caption.bold() : .caption)
				.foregroundStyle(isHeader ? Color.primary : Color.secondary)
				.lineLimit(3)

			if let driver = mentionedPilots.first {
				inlinePilotButton(driver)
			}
		}
		.padding(8)
		.border(.secondary.opacity(0.12), width: 0.5)
	}

	private func inlinePilotButton(_ driver: F1Driver) -> some View {
		Button {
			onSelectPilot(driver)
		} label: {
			HStack(spacing: 4) {
				Text(driver.abbreviation)
					.font(.caption2)
					.fontWeight(.black)
					.fontWidth(.condensed)
				Text("#\(driver.number)")
					.font(.caption2)
					.foregroundStyle(.secondary)
			}
			.padding(.vertical, 1)
			.padding(.horizontal, 5)
			.background(driver.teamColors.primary.opacity(0.18))
			.foregroundStyle(.primary)
			.clipShape(Capsule())
		}
		.buttonStyle(.plain)
	}

	private func inlineTokens(for text: String) -> [InlineToken] {
		let words = text.split(
			separator: " ",
			omittingEmptySubsequences: false
		)
		.map(String.init)
		var tokens: [InlineToken] = []
		var insertedPilotNumbers = Set<Int>()

			for index in words.indices {
				let word = words[index]
				let driver = fullNameMentioned(
					in: words,
					endingAt: index
				)
				let renderedWord = driver == nil && index == words.count - 1
					? word
					: "\(word) "
				tokens.append(.text(renderedWord))

				guard
					let driver,
					insertedPilotNumbers.insert(driver.number).inserted
				else {
					continue
				}

				tokens.append(.pilot(driver))
				if index < words.count - 1 {
					tokens.append(.text(" "))
				}
			}

		return tokens
	}

	private func fullNameMentioned(
		in words: [String],
		endingAt index: Int
	) -> F1Driver? {
		pilots.first { driver in
			let nameParts = driver.fullName
				.split(separator: " ")
				.map { normalizedDriverText(String($0)) }

			guard
				!nameParts.isEmpty,
				index >= nameParts.count - 1
			else {
				return false
			}

			let startIndex = index - nameParts.count + 1
			let candidate = words[startIndex...index].map(normalizedDriverText)
			return candidate == nameParts
		}
	}

	private func pilotsMentioned(in text: String) -> [F1Driver] {
		let normalized = normalizedDriverText(text)

		return pilots.filter { driver in
			normalized.contains(normalizedDriverText(driver.fullName))
		}
	}

	private func normalizedDriverText(_ text: String) -> String {
		text
			.trimmingCharacters(in: .punctuationCharacters)
			.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
			.lowercased()
	}

	private func isTableLine(_ line: String) -> Bool {
		let trimmed = line.trimmingCharacters(in: .whitespaces)
		return trimmed.hasPrefix("|")
			&& trimmed.hasSuffix("|")
			&& trimmed.filter { $0 == "|" }.count >= 2
	}

	private func tableCells(_ line: String) -> [String] {
		line
			.split(separator: "|", omittingEmptySubsequences: false)
			.dropFirst()
			.dropLast()
			.map { cell in
				cell.trimmingCharacters(in: .whitespacesAndNewlines)
			}
	}

	private func isTableSeparator(_ cells: [String]) -> Bool {
		!cells.isEmpty && cells.allSatisfy { cell in
			let cleaned = cell.replacingOccurrences(of: ":", with: "")
			return !cleaned.isEmpty && cleaned.allSatisfy { $0 == "-" }
		}
	}

	private func inlineText(_ text: String) -> Text {
		if let markdown = try? AttributedString(markdown: text) {
			return Text(markdown)
		}

		return Text(text)
	}

	private enum MarkdownBlock: Identifiable {
		case line(id: Int, text: String)
		case table(id: Int, rows: [[String]])

		var id: Int {
			switch self {
			case .line(let id, _), .table(let id, _):
				id
			}
		}
	}

	private struct InlineToken: Identifiable {
		let id = UUID()
		let kind: Kind

		var isText: Bool {
			if case .text = kind {
				return true
			}

			return false
		}

		static func text(_ value: String) -> InlineToken {
			InlineToken(kind: .text(value))
		}

		static func pilot(_ driver: F1Driver) -> InlineToken {
			InlineToken(kind: .pilot(driver))
		}

		enum Kind {
			case text(String)
			case pilot(F1Driver)
		}
	}
}

private struct PilotInlineFlow: Layout {
	var horizontalSpacing: CGFloat = 4
	var verticalSpacing: CGFloat = 4

	func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout ()
	) -> CGSize {
		let maxWidth = proposal.width ?? .infinity
		let rows = rows(
			for: subviews,
			maxWidth: maxWidth.isFinite ? maxWidth : .greatestFiniteMagnitude
		)

		let width = rows.map(\.width).max() ?? 0
		let height = rows.reduce(CGFloat.zero) { partialResult, row in
			partialResult + row.height
		} + CGFloat(max(rows.count - 1, 0)) * verticalSpacing

		return CGSize(width: width, height: height)
	}

	func placeSubviews(
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout ()
	) {
		let rows = rows(for: subviews, maxWidth: bounds.width)
		var y = bounds.minY

		for row in rows {
			var x = bounds.minX

			for item in row.items {
				subviews[item.index].place(
					at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
					proposal: ProposedViewSize(
						width: item.size.width,
						height: item.size.height
					)
				)
				x += item.size.width + horizontalSpacing
			}

			y += row.height + verticalSpacing
		}
	}

	private func rows(
		for subviews: Subviews,
		maxWidth: CGFloat
	) -> [FlowRow] {
		var rows: [FlowRow] = []
		var currentItems: [FlowItem] = []
		var currentWidth: CGFloat = 0
		var currentHeight: CGFloat = 0

		for index in subviews.indices {
			let size = subviews[index].sizeThatFits(.unspecified)
			let spacing = currentItems.isEmpty ? 0 : horizontalSpacing
			let proposedWidth = currentWidth + spacing + size.width

			if proposedWidth > maxWidth,
			   !currentItems.isEmpty {
				rows.append(
					FlowRow(
						items: currentItems,
						width: currentWidth,
						height: currentHeight
					)
				)
				currentItems = []
				currentWidth = 0
				currentHeight = 0
			}

			let itemSpacing = currentItems.isEmpty ? 0 : horizontalSpacing
			currentItems.append(FlowItem(index: index, size: size))
			currentWidth += itemSpacing + size.width
			currentHeight = max(currentHeight, size.height)
		}

		if !currentItems.isEmpty {
			rows.append(
				FlowRow(
					items: currentItems,
					width: currentWidth,
					height: currentHeight
				)
			)
		}

		return rows
	}

	private struct FlowItem {
		let index: Int
		let size: CGSize
	}

	private struct FlowRow {
		let items: [FlowItem]
		let width: CGFloat
		let height: CGFloat
	}
}

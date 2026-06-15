//
//  DriverMentionSuggestionsView.swift
//  Sportcharts
//
//  Created by Codex on 15/06/26.
//

import SwiftUI

struct DriverMentionSuggestionsView: View {
	@Binding var text: String

	var drivers: [F1Driver] = F1Grid2026.drivers
	var limit: Int = 4

	private var suggestions: [F1Driver] {
		guard let candidate = currentCandidate else {
			return []
		}

		let normalizedFragment = normalized(candidate.fragment)
		guard normalizedFragment.count >= 2 else {
			return []
		}

		let matches = drivers.filter { driver in
			mentionTerms(for: driver).contains { term in
				term.hasPrefix(normalizedFragment)
					|| term.contains(normalizedFragment)
			}
		}

		return Array(matches.prefix(limit))
	}

	var body: some View {
		if !suggestions.isEmpty {
			ScrollView(.horizontal) {
				HStack(spacing: 8) {
					ForEach(suggestions) { driver in
						Button {
							insert(driver)
						} label: {
							driverSuggestion(driver)
						}
						.buttonStyle(.plain)
					}
				}
				.padding(.horizontal, 4)
			}
			.scrollClipDisabled()
			.scrollIndicators(.hidden)
			.transition(.move(edge: .bottom).combined(with: .opacity))
		}
	}

	@ViewBuilder
	private func driverSuggestion(_ driver: F1Driver) -> some View {
		HStack(spacing: 8) {
			AsyncImage(url: driver.imageURL) { phase in
				switch phase {
				case .empty:
					ProgressView()
						.frame(width: 30, height: 30)
				case .failure:
					Circle()
						.fill(driver.teamColors.primary.opacity(0.24))
						.frame(width: 30, height: 30)
						.overlay {
							Text(driver.abbreviation)
								.font(.caption2)
								.fontWeight(.black)
						}
				case .success(let image):
					image
						.resizable()
						.aspectRatio(contentMode: .fill)
						.padding(.top, 62)
						.frame(width: 30, height: 30)
						.background(driver.teamColors.primary)
						.clipShape(Circle())
				@unknown default:
					Color.clear
						.frame(width: 30, height: 30)
				}
			}

			VStack(alignment: .leading, spacing: 0) {
				Text(driver.fullName)
					.font(.caption)
					.fontWeight(.bold)
				Text(driver.team.rawValue)
					.font(.caption2)
					.foregroundStyle(.secondary)
					.lineLimit(1)
			}
		}
		.padding(.vertical, 6)
		.padding(.horizontal, 8)
		.background(.ultraThinMaterial)
		.clipShape(Capsule())
		.overlay {
			Capsule()
				.stroke(driver.teamColors.primary.opacity(0.32), lineWidth: 1)
		}
	}

	private var currentCandidate: MentionCandidate? {
		let candidates = suffixCandidates(maxWords: 3)
		guard !candidates.isEmpty else {
			return nil
		}

		let currentText = normalized(text)
		let alreadyEndsWithFullName = drivers.contains { driver in
			currentText.hasSuffix(normalized(driver.fullName))
		}

		guard !alreadyEndsWithFullName else {
			return nil
		}

		return candidates.first { candidate in
			let normalizedCandidate = normalized(candidate.fragment)
			guard normalizedCandidate.count >= 2 else {
				return false
			}

			return drivers.contains { driver in
				mentionTerms(for: driver).contains { term in
					term.hasPrefix(normalizedCandidate)
						|| term.contains(normalizedCandidate)
				}
			}
		}
	}

	private func insert(_ driver: F1Driver) {
		guard let candidate = currentCandidate else {
			append(driver)
			return
		}

		text.replaceSubrange(candidate.range, with: driver.fullName)

		if !text.hasSuffix(" ") {
			text += " "
		}
	}

	private func append(_ driver: F1Driver) {
		if !text.isEmpty, !text.hasSuffix(" ") {
			text += " "
		}

		text += "\(driver.fullName) "
	}

	private func mentionTerms(for driver: F1Driver) -> [String] {
		var terms = [
			driver.fullName,
			driver.firstName,
			driver.lastName,
			driver.abbreviation,
			"#\(driver.number)",
			"\(driver.number)"
		]

		terms.append(contentsOf: driver.firstName.split(separator: " ").map(String.init))
		return terms.map(normalized)
	}

	private func normalized(_ value: String) -> String {
		value
			.trimmingCharacters(in: .punctuationCharacters)
			.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
			.lowercased()
	}

	private func suffixCandidates(maxWords: Int) -> [MentionCandidate] {
		let tokens = text.split(
			whereSeparator: { character in
				character.isWhitespace || character.isNewline
			}
		)

		guard !tokens.isEmpty else {
			return []
		}

		var candidates: [MentionCandidate] = []
		let lowerBound = max(tokens.count - maxWords, 0)

		for start in lowerBound..<tokens.count {
			let rangeStart = tokens[start].startIndex
			let rangeEnd = tokens[tokens.count - 1].endIndex
			let fragment = text[rangeStart..<rangeEnd]
				.trimmingCharacters(in: .punctuationCharacters)

			guard !fragment.isEmpty else {
				continue
			}

			candidates.append(
				MentionCandidate(
					fragment: fragment,
					range: rangeStart..<rangeEnd
				)
			)
		}

		return candidates
	}

	private struct MentionCandidate {
		let fragment: String
		let range: Range<String.Index>
	}
}

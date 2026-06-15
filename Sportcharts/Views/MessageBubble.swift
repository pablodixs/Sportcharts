//
//  MessageBubble.swift
//  Sportcharts
//
//  Created by Pablo Dias on 11/05/26.
//

import SwiftUI

struct MessageBubble: View {
	let message: ChatMessage
	let accent: Color

	var isAssistant: Bool {
		message.role == .assistant
	}
	
	@State private var isPresented = false

	var body: some View {
		HStack {

			if isAssistant {

				assistantBubble

				Spacer()

			} else {

				Spacer(minLength: 40)

				userBubble
					.onAppear {
						isPresented = true
					}
					.offset(y: isPresented ? 0 : 400)
					.opacity(isPresented ? 1 : 0)
					.animation(.spring, value: isPresented)
			}
		}
		.animation(
			.smooth(duration: 0.2),
			value: message.content
		)
	}
}

extension MessageBubble {

	fileprivate var assistantBubble: some View {

		VStack(
			alignment: .leading,
			spacing: 8
		) {

			if message.state == .typing && message.content.isEmpty {
				Image(systemName: "tire")
					.font(.title)
					.foregroundStyle(accent)
					.symbolEffect(
						.rotate.byLayer,
						options: .repeat(.continuous)
					)
			} else {
				Text(.init(message.content))
					.textSelection(.enabled)
					.lineHeight(.loose)
			}

			if message.state == .typing && !message.content.isEmpty {
				blinkingCursor
			}
		}
		.padding(.vertical)
	}
}

extension MessageBubble {
	fileprivate var userBubble: some View {
		Text(message.content)
			.fontWeight(.medium)
			.padding(.horizontal, 14)
			.padding(.vertical, 10)
			.foregroundStyle(.white)
			.background(accent)
			.clipShape(
				RoundedRectangle(
					cornerRadius: 24
				)
			)
	}
}

extension MessageBubble {

	fileprivate var blinkingCursor: some View {
		TimelineView(.animation) { context in

			let visible =
				Int(context.date.timeIntervalSince1970 * 2)
				.isMultiple(of: 2)

			Circle()
				.fill(accent)
				.frame(width: 16, height: 16)
				.opacity(visible ? 1 : 0)

		}
	}
}

//
//  TextGlow.swift
//  Sportcharts
//
//  Created by Pablo Dias on 19/05/26.
//

import SwiftUI

struct TextGlow: ViewModifier {
	var glowColor: Color = .white
	var animationDuration: Double = 2.5
	var gradientWidth: CGFloat = 0.8
	
	@State private var moveGradient: Bool = false
	
	func body(content: Content) -> some View {
		content
			.overlay {
				GeometryReader { proxy in
					LinearGradient(
						colors: [
							.clear,
							glowColor.opacity(0.85),
							.clear
						],
						startPoint: .leading,
						endPoint: .trailing
					)
					.frame(width: proxy.size.width * gradientWidth)
					.offset(
						x: moveGradient
						? proxy.size.width
						: -proxy.size.width
					)
				}
				.mask {
					content
				}
			}
			.animation(
				.linear(duration: animationDuration)
				.repeatForever(autoreverses: false),
				value: moveGradient
			)
			.onAppear {
				moveGradient = true
			}
	}
}

extension View {
	func textGlow(
		glowColor: Color = .white,
		animationDuration: Double = 2.5,
		gradientWidth: CGFloat = 0.8
	) -> some View {
		modifier(
			TextGlow(
				glowColor: glowColor,
				animationDuration: animationDuration,
				gradientWidth: gradientWidth
			)
		)
	}
}

#Preview {
	Text("Teste")
		.font(.largeTitle.bold())
		.textGlow()
}

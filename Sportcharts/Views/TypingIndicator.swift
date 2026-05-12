//
//  TypingIndicator.swift
//  Sportcharts
//
//  Created by Pablo Dias on 11/05/26.
//

import SwiftUI

struct TypingIndicator: View {
	
	@State private var animate = false
	
	let accent: Color
	
	var body: some View {
		
		HStack(spacing: 4) {
			
			ForEach(0..<3) { index in
				
				Circle()
					.fill(accent)
					.frame(width: 16, height: 16)
					.scaleEffect(
						animate ? 1 : 0.75
					)
					.animation(
						.easeInOut(duration: 0.6)
						.repeatForever()
						.delay(Double(index) * 0.2),
						value: animate
					)
			}
		}
		.padding(12)
		.background(accent.quinary)
		.clipShape(Capsule())
		.onAppear {
			animate = true
		}
	}
}


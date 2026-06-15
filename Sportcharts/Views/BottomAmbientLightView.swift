//
//  BottomAmbientLightView.swift
//  Sportcharts
//
//  Adapted from BottomGradientShader on 15/06/26.
//

import SwiftUI

struct BottomAmbientLightView: View {
	var tint: Color = .cyan
	var progress: CGFloat = 1

	var body: some View {
		TimelineView(.animation) { timeline in
			GeometryReader { geometry in
				Rectangle()
					.fill(.white)
					.layerEffect(
						ShaderLibrary.bottomAmbientLighting(
							.float2(
								Float(geometry.size.width),
								Float(geometry.size.height)
							),
							.float(
								timeline.date.timeIntervalSinceReferenceDate
									.truncatingRemainder(dividingBy: 100_000)
							),
							.float(Float(progress)),
							.color(tint)
						),
						maxSampleOffset: .zero
					)
			}
		}
	}
}

struct SessionAnalysisAmbientLight: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	
	let isActive: Bool
	let tint: Color
	
	@State private var reveal: CGFloat = 0
	@State private var opacity: Double = 0
	
	var body: some View {
		BottomAmbientLightView(tint: tint, progress: reveal)
			.opacity(opacity)
			.ignoresSafeArea()
			.allowsHitTesting(false)
			.task(id: isActive) {
				await updateEffect()
			}
	}
	
	@MainActor
	private func updateEffect() async {
		if isActive {
			guard !reduceMotion else {
				reveal = 1
				opacity = 0.8
				return
			}
			
			reveal = 0
			opacity = 0
			
			try? await Task.sleep(for: .milliseconds(80))
			guard !Task.isCancelled else { return }
			
			withAnimation(.easeOut(duration: 1.1)) {
				reveal = 1
				opacity = 1
			}
			
			try? await Task.sleep(for: .milliseconds(700))
			guard !Task.isCancelled else { return }
			
			withAnimation(.easeOut(duration: 0.8)) {
				opacity = 0.78
			}
		} else {
			withAnimation(.easeOut(duration: 0.45)) {
				reveal = 0
				opacity = 0
			}
		}
	}
}

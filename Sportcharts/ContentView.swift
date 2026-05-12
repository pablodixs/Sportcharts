//
//  ContentView.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/03/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
		TabView {
			Tab("Início", systemImage: "house") {
				HomeView()
			}
			Tab("Sessões", systemImage: "calendar") {
				SessionsScreen()
			}
			Tab("Pilotos", systemImage: "person") {
				LocalDriversScreen()
			}
		}
		.tint(.primary)
    }
}

#Preview {
    ContentView()
}

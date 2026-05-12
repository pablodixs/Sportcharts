//
//  HomeView.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/03/26.
//

import SwiftUI

struct HomeView: View {
	var body: some View {
		NavigationStack {
			VStack {
				NavigationLink(destination: LocalDriversScreen()) {
					Text("Pilotos".uppercased())
						.bold()
						.fontWidth(.condensed)
				}
			}
		}
	}
}

#Preview {
	HomeView()
}

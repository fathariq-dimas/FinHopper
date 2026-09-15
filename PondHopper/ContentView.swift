//
//  ContentView.swift
//  FinHopper
//
//  Created by Fathariq Dimas on 08/09/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sessionModel = GameSessionModel()

    var body: some View {
        RootGameView(model: sessionModel)
    }
}

#Preview {
    ContentView()
}

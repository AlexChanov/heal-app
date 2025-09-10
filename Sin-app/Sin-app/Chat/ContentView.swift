//
//  ContentView.swift
//  Sin-app
//
//  Created by Alexey Chanov on 30.08.2025.
//

import Foundation
// ContentView.swift
import SwiftUI
import Supabase // <--- ДОБАВЛЕНО ЗДЕСЬ
// ContentView.swift
// ContentView.swift
import SwiftUI
import Supabase

struct ContentView: View {
    @State var session: Session?

    var body: some View {
        // Единственный NavigationStack, управляющий всем
        NavigationStack {
            VStack {
                if let session = session {
                    UserListView(session: session)
                } else {
                    AuthView()
                }
            }
        }
        .onAppear {
            Task {
                self.session = try? await supabase.auth.session

                for await (_, session) in await supabase.auth.authStateChanges {
                    // Явно обновляем UI в главном потоке для надежности
                    await MainActor.run {
                        self.session = session
                    }
                }
            }
        }
    }
}

//
//  ContentView.swift
//  Sin-app
//
//  Created by Alexey Chanov on 30.08.2025.
//

//
// ContentView.swift
// Sin-app
//
// Created by Alexey Chanov on 30.08.2025.
//

//
// ContentView.swift
// Sin-app
//
// Created by Alexey Chanov on 30.08.2025.
//

import Foundation
import SwiftUI
import Supabase

struct ContentView: View {
    @State var session: Session?

    var body: some View {
        // Единственный NavigationStack, управляющий всем приложением
        NavigationStack {
            if let session = session {
                MainTabView(session: session)
            } else {
                AuthView()
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

/// Основной TabView для авторизованного пользователя
struct MainTabView: View {
    let session: Session

    var body: some View {
        TabView {
            UserListView(session: session)
                .tabItem {
                    Image(systemName: "message")
                    Text("Чаты")
                }

            ProfileTabView(session: session)
                .tabItem {
                    Image(systemName: "person")
                    Text("Профиль")
                }
        }
        .navigationDestination(for: Profile.self) { profile in
            ChatView(recipient: profile, currentUserId: session.user.id)
        }
    }
}

/// Экран профиля пользователя
struct ProfileTabView: View {
    let session: Session

    var body: some View {
        VStack(spacing: 20) {
            Text("Профиль")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("ID: \(session.user.id.uuidString)")
                .font(.caption)
                .foregroundColor(.secondary)

            if let email = session.user.email {
                Text("Email: \(email)")
                    .font(.body)
            }

            Spacer()

            Button("Выйти") {
                Task {
                    try? await supabase.auth.signOut()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}


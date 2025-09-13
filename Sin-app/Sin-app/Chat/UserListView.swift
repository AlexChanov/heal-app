//
//  UserListView.swift
//  Sin-app
//
//  Created by Alexey Chanov on 30.08.2025.
//

import Foundation
import SwiftUI
import Supabase

struct UserListView: View {
    let session: Session
    @State private var profiles: [Profile] = []
    @State private var error: Error?
    @State private var showAlert = false

    var body: some View {
        List(profiles) { profile in
            // Обычный NavigationLink с value - работает с iOS 16+
            NavigationLink(value: profile) {
                Text(profile.username)
            }
        }
        .navigationTitle("Пользователи")
        .task {
            await fetchProfiles()
        }
        .alert("Ошибка", isPresented: $showAlert, presenting: error) { _ in
            Button("OK") {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    func fetchProfiles() async {
        do {
            let currentUserId = session.user.id
            let fetchedProfiles: [Profile] = try await supabase.database
                .from("profiles")
                .select()
                .not("id", operator: .eq, value: currentUserId.uuidString)
                .execute()
                .value
            self.profiles = fetchedProfiles
        } catch {
            self.error = error
            self.showAlert = true
        }
    }
}

#Preview {
    UserListView(session: Session(
        accessToken: "fake_token",
        tokenType: "bearer",
        expiresIn: 3600,
        expiresAt: 30, refreshToken: "fake_refresh",
        user: User(
            id: UUID(),
            appMetadata: [:],
            userMetadata: [:],
            aud: "authenticated",
            createdAt: Date(),
            updatedAt: Date()
        )
    ))
}

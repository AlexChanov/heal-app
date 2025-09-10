//
//  UserListView.swift
//  Sin-app
//
//  Created by Alexey Chanov on 30.08.2025.
//

import Foundation

// UserListView.swift
import SwiftUI
import Supabase

struct UserListView: View {
    let session: Session
    @State private var profiles: [Profile] = []
    @State private var error: Error?
    @State private var showAlert = false

    var body: some View {
        // NavigationStack убран
        List(profiles) { profile in
            NavigationLink(value: profile) {
                Text(profile.username)
            }
        }
        .navigationTitle("Пользователи")
        .navigationDestination(for: Profile.self) { profile in
            ChatView(recipient: profile, currentUserId: session.user.id)
        }
        .task {
            await fetchProfiles()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Выйти") {
                    Task {
                        try? await supabase.auth.signOut()
                    }
                }
            }
        }
        .alert("Ошибка", isPresented: $showAlert, presenting: error) { _ in
            Button("OK") {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    // Функция fetchProfiles() остается без изменений
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

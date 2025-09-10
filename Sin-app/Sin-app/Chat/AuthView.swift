//
//  AuthView.swift
//  Sin-app
//
//  Created by Alexey Chanov on 30.08.2025.
//

import Foundation
// AuthView.swift
import SwiftUI

struct AuthView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var authError: Error?
    @State private var showAlert = false

    var body: some View {
        // NavigationStack убран
        VStack(spacing: 20) {
            Text("Вход")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Логин", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)

            SecureField("Пароль", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if isLoading {
                ProgressView()
            } else {
                Button("Войти") {
                    signIn()
                }
                .buttonStyle(.borderedProminent)

                Button("Зарегистрироваться") {
                    signUp()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        // .navigationTitle убран, т.к. нет NavigationStack
        .alert("Ошибка", isPresented: $showAlert, presenting: authError) { error in
            Button("OK") {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    // Функции signIn() и signUp() остаются без изменений
    func signIn() {
        isLoading = true
        Task {
            do {
                let email = "\(username)@yourapp.com"
                try await supabase.auth.signIn(email: email, password: password)
            } catch {
                self.authError = error
                self.showAlert = true
            }
            isLoading = false
        }
    }

    func signUp() {
        // Проверяем, что поля не пустые
        guard !username.isEmpty, !password.isEmpty else {
            print("Username and password cannot be empty.")
            return
        }
        isLoading = true
        Task {
            do {
                // Создаем фиктивный email
                let email = "\(username)@yourapp.com"

                // Вызываем signUp, передавая метаданные напрямую через параметр `data`.
                // Параметр `options` больше не нужен.
                try await supabase.auth.signUp(
                    email: email,
                    password: password,
                    data: ["username": .string(username)]
                )

            } catch {
                // Обработка ошибок
                self.authError = error
                self.showAlert = true
            }

            isLoading = false
        }
    }
}

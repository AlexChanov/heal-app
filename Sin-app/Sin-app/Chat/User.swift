//
//  User.swift
//  Sin-app
//
//  Created by Alexey Chanov on 30.08.2025.
//

// Models.swift
import Foundation

// Models.swift
// Models.swift
import Foundation

struct Profile: Identifiable, Decodable, Hashable { // Добавлено Hashable
    let id: UUID
    let username: String

    enum CodingKeys: String, CodingKey {
        case id
        case username
    }
}

struct Message: Identifiable, Decodable, Equatable {
    let id: Int
    let content: String
    let senderId: UUID
    let receiverId: UUID // <--- ДОБАВЛЕНО НЕДОСТАЮЩЕЕ ПОЛЕ
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case senderId = "sender_id"
        case receiverId = "receiver_id" // <--- ДОБАВЛЕНО СООТВЕТСТВИЕ ДЛЯ КЛЮЧА
        case createdAt = "created_at"
    }
}

//
//  ChatView.swift
//  Sin-app
//
//  Created by Alexey Chanov on 30.08.2025.
//

// ChatView.swift
import SwiftUI
import Supabase

struct ChatView: View {
    let recipient: Profile
    let currentUserId: UUID

    @State private var messages: [Message] = []
    @State private var newMessageText = ""
    @State private var channel: RealtimeChannelV2?

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageView(message: message, isCurrentUser: message.senderId == currentUserId)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }

            HStack {
                TextField("Сообщение...", text: $newMessageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.largeTitle)
                }
                .disabled(newMessageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle(recipient.username)
        .onAppear {
            Task {
                await fetchMessages()
                await subscribeToNewMessages()
            }
        }
        .onDisappear {
            if let channel = channel {
                Task {
                    try? await channel.unsubscribe()
                }
            }
        }
    }

    // Загрузка истории сообщений
    // В файле ChatView.swift

    func fetchMessages() async {
        do {
            // Создаем тот же кастомный декодер
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                let formatters = [
                    {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        return formatter
                    }(),
                    {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime]
                        return formatter
                    }()
                ]

                for formatter in formatters {
                    if let date = (formatter as AnyObject).date(from: dateString) {
                        return date
                    }
                }

                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date string \(dateString)"
                )
            }

            let fetchedMessages: [Message] = try await supabase.database
                .from("messages")
                .select()
                .or("and(sender_id.eq.\(currentUserId.uuidString),receiver_id.eq.\(recipient.id.uuidString)),and(sender_id.eq.\(recipient.id.uuidString),receiver_id.eq.\(currentUserId.uuidString))")
                .order("created_at", ascending: true)
                .execute()
                .value

            await MainActor.run {
                self.messages = fetchedMessages
            }
        } catch {
            print("Error fetching messages: \(error)")
        }
    }


    // Отправка нового сообщения с оптимистичным обновлением UI
    func sendMessage() {
        guard !newMessageText.isEmpty else { return }

        struct NewMessage: Encodable {
            let sender_id: UUID
            let receiver_id: UUID
            let content: String
        }

        let messageToSend = NewMessage(
            sender_id: currentUserId,
            receiver_id: recipient.id,
            content: newMessageText
        )

        // Создаем временное сообщение для немедленного отображения
        let tempMessage = Message(
            id: Int.random(in: 1_000_000...2_000_000),
            content: newMessageText,
            senderId: currentUserId,
            receiverId: recipient.id,
            createdAt: Date()
        )

        // Немедленно добавляем в UI
        messages.append(tempMessage)

        let tempText = newMessageText
        newMessageText = ""

        // Отправляем в базу данных асинхронно
        Task {
            do {
                try await supabase.database
                    .from("messages")
                    .insert(messageToSend)
                    .execute()
            } catch {
                print("Error sending message: \(error)")
                // В случае ошибки удаляем временное сообщение и возвращаем текст
                await MainActor.run {
                    messages.removeAll { $0.id == tempMessage.id }
                    newMessageText = tempText
                }
            }
        }
    }

    // В файле ChatView.swift

    func subscribeToNewMessages() async {
        self.channel = supabase.realtimeV2.channel("public:messages")

        let changes = channel!.postgresChange(
            Realtime.InsertAction.self,
            schema: "public",
            table: "messages"
        )

        Task {
            for await change in changes {
                do {
                    // ИСПРАВЛЕНИЕ: Создаем кастомный декодер для обработки дат с микросекундами
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .custom { decoder in
                        let container = try decoder.singleValueContainer()
                        let dateString = try container.decode(String.self)

                        // Пробуем несколько форматов, начиная с самого детального
                        let formatters = [
                            // Формат с микросекундами (как в Supabase)
                            {
                                let formatter = ISO8601DateFormatter()
                                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                                return formatter
                            }(),
                            // Стандартный ISO8601 без микросекунд
                            {
                                let formatter = ISO8601DateFormatter()
                                formatter.formatOptions = [.withInternetDateTime]
                                return formatter
                            }()
                        ]

                        for formatter in formatters {
                            if let date = (formatter as AnyObject).date(from: dateString) {
                                return date
                            }
                        }

                        // Если никакой формат не подошел
                        throw DecodingError.dataCorruptedError(
                            in: container,
                            debugDescription: "Cannot decode date string \(dateString)"
                        )
                    }

                    let newMessage: Message = try change.decodeRecord(decoder: decoder)

                    if (newMessage.senderId == currentUserId && newMessage.receiverId == recipient.id) ||
                       (newMessage.senderId == recipient.id && newMessage.receiverId == currentUserId) {

                        await MainActor.run {
                            messages.removeAll { $0.id >= 1_000_000 }

                            if !messages.contains(where: { $0.id == newMessage.id }) {
                                messages.append(newMessage)
                            }
                        }
                    }
                } catch {
                    print("Failed to decode new message:", error)
                }
            }
        }

        do {
            try await channel!.subscribe()
        } catch {
            print("Failed to subscribe to channel:", error)
        }
    }

}

// Компонент для отображения одного сообщения
struct MessageView: View {
    let message: Message
    let isCurrentUser: Bool


    var body: some View {
        HStack {
            if isCurrentUser {
                // Свои сообщения: отступ слева + сообщение справа (синие)
                Spacer(minLength: 50)

                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                // Чужие сообщения: сообщение слева + отступ справа (серые)
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGray5))
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer(minLength: 50)
            }
        }
    }
}

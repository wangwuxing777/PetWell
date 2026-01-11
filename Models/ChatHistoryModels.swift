//
//  ChatHistoryModels.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/30.
//

import Foundation
import SwiftData

// MARK: - SwiftData Chat History Models

/// A chat session is grouped by a stable pet key (or "none" when no pet is selected).
/// Supports multiple sessions per petKey and soft deletion.
@Model
final class ChatSession {
    // Multiple sessions support
    var id: UUID
    var title: String
    var isDeleted: Bool

    // Grouping
    var petKey: String

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    // Messages
    @Relationship(deleteRule: .cascade) var messages: [ChatMessageEntity]

    init(petKey: String) {
        self.id = UUID()
        self.title = "New chat"
        self.isDeleted = false

        self.petKey = petKey
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = []
    }

    convenience init(petKey: String, title: String) {
        self.init(petKey: petKey)
        self.title = title
    }
}

/// A single stored chat message.
@Model
final class ChatMessageEntity {
    var senderRaw: String
    var text: String
    var timestamp: Date
    var orderIndex: Int

    init(senderRaw: String, text: String, timestamp: Date, orderIndex: Int) {
        self.senderRaw = senderRaw
        self.text = text
        self.timestamp = timestamp
        self.orderIndex = orderIndex
    }
}

// MARK: - Helpers

enum ChatSender: String {
    case user
    case guardian
    case system
}

extension ChatSession {
    static func make(petKey: String) -> ChatSession {
        ChatSession(petKey: petKey, title: "New chat")
    }
}

extension PersistentIdentifier {
    /// Stable string key for grouping chat sessions.
    var chatSessionKey: String { String(describing: self) }
}

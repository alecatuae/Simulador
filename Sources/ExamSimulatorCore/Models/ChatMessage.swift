import Foundation

/// A single message in an AI conversation.
public struct ChatMessage: Identifiable, Equatable {
    public enum Role: String, Equatable {
        case system, user, assistant
    }

    public let id: UUID
    public let role: Role
    public let content: String

    public init(id: UUID = UUID(), role: Role, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }
}

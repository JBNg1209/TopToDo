import Foundation

public enum TodoHighlight: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case red
    case gray
    case blue
}

public struct TodoItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool
    public var highlight: TodoHighlight
    public var alarmAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public var isHighlighted: Bool {
        highlight != .none
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case isCompleted
        case highlight
        case isHighlighted
        case alarmAt
        case createdAt
        case updatedAt
    }

    public init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        highlight: TodoHighlight = .none,
        alarmAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.highlight = highlight
        self.alarmAt = alarmAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    public init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        isHighlighted: Bool,
        alarmAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.init(
            id: id,
            title: title,
            isCompleted: isCompleted,
            highlight: isHighlighted ? .red : .none,
            alarmAt: alarmAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        if let highlight = try container.decodeIfPresent(TodoHighlight.self, forKey: .highlight) {
            self.highlight = highlight
        } else {
            let legacyHighlight = try container.decodeIfPresent(Bool.self, forKey: .isHighlighted) ?? false
            self.highlight = legacyHighlight ? .red : .none
        }
        self.alarmAt = try container.decodeIfPresent(Date.self, forKey: .alarmAt)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(highlight, forKey: .highlight)
        try container.encodeIfPresent(alarmAt, forKey: .alarmAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

import Foundation

public struct TodoItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool
    public var isHighlighted: Bool
    public var alarmAt: Date?
    public let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case isCompleted
        case isHighlighted
        case alarmAt
        case createdAt
    }

    public init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        isHighlighted: Bool = false,
        alarmAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.isHighlighted = isHighlighted
        self.alarmAt = alarmAt
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        self.isHighlighted = try container.decodeIfPresent(Bool.self, forKey: .isHighlighted) ?? false
        self.alarmAt = try container.decodeIfPresent(Date.self, forKey: .alarmAt)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(isHighlighted, forKey: .isHighlighted)
        try container.encodeIfPresent(alarmAt, forKey: .alarmAt)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

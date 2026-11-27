import Foundation

enum Category: String, CaseIterable, Identifiable {
    case food, entertainment, utilities, shopping, transport, health, other

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .food: "fork.knife"
        case .entertainment: "play.tv"
        case .utilities: "bolt"
        case .shopping: "bag"
        case .transport: "car"
        case .health: "heart"
        case .other: "square.grid.2x2"
        }
    }
}

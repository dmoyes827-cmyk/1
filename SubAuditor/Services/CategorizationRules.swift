import Foundation

enum CategorizationRules {
    static func category(for name: String) -> Category {
        let text = name.lowercased()
        let rules: [(Category, [String])] = [
            (.food, ["coffee", "cafe", "restaurant", "grocery", "food"]),
            (.entertainment, ["netflix", "spotify", "disney", "hulu", "cinema"]),
            (.utilities, ["electric", "water bill", "internet", "phone bill"]),
            (.shopping, ["amazon", "store", "shop"]),
            (.transport, ["uber", "lyft", "transit", "fuel", "parking"]),
            (.health, ["pharmacy", "gym", "medical", "fitness"])
        ]
        return rules.first { _, keywords in keywords.contains { text.contains($0) } }?.0 ?? .other
    }
}

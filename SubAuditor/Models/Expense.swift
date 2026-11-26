import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID = UUID()
    var name: String = ""
    var amount: Double = 0
    var date: Date = Date()
    var categoryRaw: String = Category.other.rawValue
    var isRecurring: Bool = false

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(name: String, amount: Double, date: Date = .now, category: Category = .other, isRecurring: Bool = false) {
        self.name = name
        self.amount = amount
        self.date = date
        self.categoryRaw = category.rawValue
        self.isRecurring = isRecurring
    }
}

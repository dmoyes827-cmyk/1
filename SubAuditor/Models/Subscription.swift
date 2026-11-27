import Foundation
import SwiftData

enum BillingCycle: String, CaseIterable, Identifiable {
    case weekly, monthly, quarterly, yearly
    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var monthlyFactor: Double {
        switch self {
        case .weekly: 52.0 / 12.0
        case .monthly: 1
        case .quarterly: 1.0 / 3.0
        case .yearly: 1.0 / 12.0
        }
    }
}

@Model
final class Subscription {
    var id: UUID = UUID()
    var name: String = ""
    var amount: Double = 0
    var cycleRaw: String = BillingCycle.monthly.rawValue
    var renewalDate: Date = Date()
    var isActive: Bool = true
    var categoryRaw: String = Category.other.rawValue

    var cycle: BillingCycle {
        get { BillingCycle(rawValue: cycleRaw) ?? .monthly }
        set { cycleRaw = newValue.rawValue }
    }
    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    var monthlyCost: Double { amount * cycle.monthlyFactor }

    init(name: String, amount: Double, cycle: BillingCycle, renewalDate: Date, category: Category = .other) {
        self.name = name
        self.amount = amount
        self.cycleRaw = cycle.rawValue
        self.renewalDate = renewalDate
        self.categoryRaw = category.rawValue
    }
}

import Foundation

enum AuditEngine {
    static func duplicateExpenses(_ expenses: [Expense]) -> [Expense] {
        var seen = Set<String>()
        return expenses.filter { expense in
            let day = Calendar.current.startOfDay(for: expense.date).timeIntervalSince1970
            let key = "\(expense.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())|\(expense.amount.formatted(.number.precision(.fractionLength(2))))|\(day)"
            return !seen.insert(key).inserted
        }
    }

    static func duplicateSubscriptions(_ subscriptions: [Subscription]) -> [Subscription] {
        var seen = Set<String>()
        return subscriptions.filter { subscription in
            guard subscription.isActive else { return false }
            let key = subscription.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !seen.insert(key).inserted
        }
    }

    static func monthlyTotal(_ subscriptions: [Subscription]) -> Double {
        subscriptions.filter(\.isActive).reduce(0) { $0 + $1.monthlyCost }
    }

    static func upcoming(_ subscriptions: [Subscription], from date: Date = .now, days: Int = 7) -> [Subscription] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard days > 0, let end = calendar.date(byAdding: .day, value: days, to: start) else { return [] }
        return subscriptions.filter { $0.isActive && $0.renewalDate >= start && $0.renewalDate < end }
            .sorted { $0.renewalDate < $1.renewalDate }
    }
}

import Charts
import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \Subscription.renewalDate) private var subscriptions: [Subscription]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    private var breakdown: [(category: Category, amount: Double)] {
        Category.allCases.map { category in
            (category, subscriptions.filter { $0.isActive && $0.category == category }.reduce(0) { $0 + $1.monthlyCost })
        }.filter { $0.amount > 0 }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Monthly subscription cost") {
                    Text(AuditEngine.monthlyTotal(subscriptions), format: .currency(code: currencyCode))
                        .font(.largeTitle.bold())
                    if !breakdown.isEmpty {
                        Chart(breakdown, id: \.category) { item in
                            BarMark(x: .value("Category", item.category.title), y: .value("Monthly cost", item.amount))
                                .foregroundStyle(by: .value("Category", item.category.title))
                        }
                        .frame(height: 200)
                    }
                }
                Section("Upcoming renewals — next 7 days") {
                    let upcoming = AuditEngine.upcoming(subscriptions)
                    if upcoming.isEmpty {
                        Text("No upcoming renewals").foregroundStyle(.secondary)
                    }
                    ForEach(upcoming) { subscription in
                        HStack {
                            Label(subscription.name, systemImage: subscription.category.symbol)
                            Spacer()
                            Text(subscription.renewalDate, style: .date)
                        }
                    }
                }
                Section("Audit") {
                    Text("\(AuditEngine.duplicateSubscriptions(subscriptions).count) possible duplicate subscriptions")
                    Text("\(AuditEngine.duplicateExpenses(expenses).count) possible duplicate expenses")
                }
                Section("Recent expenses") {
                    if expenses.isEmpty { Text("No expenses yet").foregroundStyle(.secondary) }
                    ForEach(Array(expenses.prefix(10))) { expense in
                        HStack {
                            Label(expense.name, systemImage: expense.category.symbol)
                            Spacer()
                            Text(expense.amount, format: .currency(code: currencyCode))
                        }
                    }
                }
            }
            .navigationTitle("SubAuditor")
        }
    }
}

var currencyCode: String { Locale.current.currency?.identifier ?? "USD" }

import SwiftData
import SwiftUI

struct SubscriptionsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Subscription.renewalDate) private var subscriptions: [Subscription]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(subscriptions) { subscription in
                    SubscriptionRow(subscription: subscription)
                }
                .onDelete { offsets in
                    offsets.map { subscriptions[$0] }.forEach(context.delete)
                }
            }
            .overlay {
                if subscriptions.isEmpty {
                    ContentUnavailableView("No subscriptions", systemImage: "repeat", description: Text("Add a subscription to track its renewal."))
                }
            }
            .navigationTitle("Subscriptions")
            .toolbar { Button("Add", systemImage: "plus") { showingAdd = true } }
            .sheet(isPresented: $showingAdd) { AddSubscriptionView() }
        }
    }
}

private struct SubscriptionRow: View {
    @Bindable var subscription: Subscription

    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $subscription.isActive) {
                Label(subscription.name, systemImage: subscription.category.symbol)
                    .font(.headline)
            }
            Text("\(subscription.amount.formatted(.currency(code: currencyCode))) · \(subscription.cycle.title) · \(subscription.renewalDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct AddSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var amount = ""
    @State private var cycle = BillingCycle.monthly
    @State private var renewalDate = Date.now
    @State private var category = Category.other

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Amount", text: $amount).keyboardType(.decimalPad)
                Picker("Billing cycle", selection: $cycle) {
                    ForEach(BillingCycle.allCases) { Text($0.title).tag($0) }
                }
                DatePicker("Next renewal", selection: $renewalDate, displayedComponents: .date)
                Picker("Category", selection: $category) {
                    ForEach(Category.allCases) { Text($0.title).tag($0) }
                }
            }
            .navigationTitle("New subscription")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = Double(amount), value.isFinite, value > 0 else { return }
                        context.insert(Subscription(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                                    amount: value, cycle: cycle, renewalDate: renewalDate, category: category))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Double(amount) ?? 0) <= 0 || !(Double(amount)?.isFinite ?? false))
                }
            }
        }
    }
}

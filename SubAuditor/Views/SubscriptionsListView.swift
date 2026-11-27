import SwiftData
import SwiftUI

struct SubscriptionsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Subscription.renewalDate) private var subscriptions: [Subscription]
    @State private var showingAdd = false
    @State private var editing: Subscription?

    var body: some View {
        NavigationStack {
            List {
                ForEach(subscriptions) { subscription in
                    SubscriptionRow(subscription: subscription) { editing = subscription }
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
            .sheet(item: $editing) { AddSubscriptionView(subscription: $0) }
        }
    }
}

private struct SubscriptionRow: View {
    @Bindable var subscription: Subscription
    let edit: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $subscription.isActive) {
                Label(subscription.name, systemImage: subscription.category.symbol)
                    .font(.headline)
            }
            Text("\(subscription.amount.formatted(.currency(code: currencyCode))) · \(subscription.cycle.title) · \(subscription.renewalDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Edit", action: edit)
                .buttonStyle(.borderless)
        }
    }
}

private struct AddSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    private let subscription: Subscription?
    @State private var name: String
    @State private var amount: String
    @State private var cycle: BillingCycle
    @State private var renewalDate: Date
    @State private var category: Category

    init(subscription: Subscription? = nil) {
        self.subscription = subscription
        _name = State(initialValue: subscription?.name ?? "")
        _amount = State(initialValue: subscription.map {
            String($0.amount).replacingOccurrences(of: ".", with: Locale.current.decimalSeparator ?? ".")
        } ?? "")
        _cycle = State(initialValue: subscription?.cycle ?? .monthly)
        _renewalDate = State(initialValue: subscription?.renewalDate ?? .now)
        _category = State(initialValue: subscription?.category ?? .other)
    }

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
            .navigationTitle(subscription == nil ? "New subscription" : "Edit subscription")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = amountValue, value.isFinite, value > 0 else { return }
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let subscription {
                            subscription.name = trimmedName
                            subscription.amount = value
                            subscription.cycle = cycle
                            subscription.renewalDate = renewalDate
                            subscription.category = category
                        } else {
                            context.insert(Subscription(name: trimmedName, amount: value, cycle: cycle,
                                                        renewalDate: renewalDate, category: category))
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (amountValue ?? 0) <= 0 || !(amountValue?.isFinite ?? false))
                }
            }

        }
    }

    private var amountValue: Double? {
        Double(amount.replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: "."))
    }
}

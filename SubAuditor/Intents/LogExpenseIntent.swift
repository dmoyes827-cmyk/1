import AppIntents
import Foundation
import SwiftData

struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Expense"
    static var description = IntentDescription("Save an expense in SubAuditor.")

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Description")
    var name: String

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) for \(\.$name) in SubAuditor")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard amount.isFinite, amount > 0, !trimmedName.isEmpty else {
            throw IntentError.invalidExpense
        }
        let context = ModelContext(AppStore.container)
        context.insert(Expense(name: trimmedName, amount: amount, category: CategorizationRules.category(for: trimmedName)))
        try context.save()
        return .result(dialog: "Logged \(trimmedName) in SubAuditor.")
    }
}

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidExpense

    var localizedStringResource: LocalizedStringResource {
        "Enter a description and an amount greater than zero."
    }
}

struct SubAuditorShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: LogExpenseIntent(), phrases: ["Log an expense in \(.applicationName)"],
                    shortTitle: "Log Expense", systemImageName: "plus.circle")
        AppShortcut(intent: UpcomingBillsIntent(), phrases: ["Upcoming bills in \(.applicationName)"],
                    shortTitle: "Upcoming Bills", systemImageName: "calendar")
    }
}

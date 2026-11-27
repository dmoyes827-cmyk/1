import AppIntents
import Foundation
import SwiftData

struct UpcomingBillsIntent: AppIntent {
    static var title: LocalizedStringResource = "Upcoming Bills"
    static var description = IntentDescription("Find renewals in the next seven days.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = ModelContext(AppStore.container)
        let subscriptions = try context.fetch(FetchDescriptor<Subscription>())
        let upcoming = AuditEngine.upcoming(subscriptions)
        guard !upcoming.isEmpty else {
            return .result(dialog: "You have no renewals in the next seven days.")
        }
        let summary = upcoming.map {
            "\($0.name), \($0.amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))), \($0.renewalDate.formatted(date: .abbreviated, time: .omitted))"
        }.joined(separator: "; ")
        return .result(dialog: "Upcoming renewals: \(summary)")
    }
}

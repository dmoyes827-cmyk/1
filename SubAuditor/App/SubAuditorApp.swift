import SwiftUI
import SwiftData

enum AppStore {
    static let container: ModelContainer = {
        let schema = Schema([Expense.self, Subscription.self])
        // Enable CloudKit in the target's Signing & Capabilities before switching to .automatic.
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to open the SubAuditor store: \(error)")
        }
    }()
}

@main
struct SubAuditorApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView()
                    .tabItem { Label("Dashboard", systemImage: "chart.pie") }
                SubscriptionsListView()
                    .tabItem { Label("Subscriptions", systemImage: "repeat") }
                CSVImportView()
                    .tabItem { Label("Import", systemImage: "square.and.arrow.down") }
            }
        }
        .modelContainer(AppStore.container)
    }
}

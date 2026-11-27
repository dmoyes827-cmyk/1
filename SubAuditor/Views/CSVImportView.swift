import SwiftData
import SwiftUI
import UniformTypeIdentifiers

private struct CSVDocument: Identifiable {
    let id = UUID()
    let rows: [[String]]
}

struct CSVImportView: View {
    @State private var importing = false
    @State private var document: CSVDocument?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "doc.text").font(.largeTitle)
                Text("Import a bank CSV").font(.headline)
                Text("Choose the date, description and amount columns, then review transactions before importing.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Choose CSV") { importing = true }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Import")
            .fileImporter(isPresented: $importing, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
                do {
                    let url = try result.get()
                    let accessed = url.startAccessingSecurityScopedResource()
                    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                    document = CSVDocument(rows: try CSVParser.parse(Data(contentsOf: url)))
                } catch {
                    self.error = error.localizedDescription
                }
            }
            .sheet(item: $document) { document in
                CSVPreviewView(rows: document.rows)
            }
            .alert("Import failed", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
        }
    }
}

private struct CSVPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let rows: [[String]]
    @State private var mapping: CSVMapping
    @State private var error: String?
    @State private var transactions: [CSVTransaction] = []
    @State private var validationError: String?
    @State private var isParsing = true
    @State private var parsedMapping: CSVMapping?

    init(rows: [[String]]) {
        self.rows = rows
        _mapping = State(initialValue: CSVParser.suggestedMapping(headers: rows[0]))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Column mapping") {
                    columnPicker("Date", selection: $mapping.date)
                    columnPicker("Description", selection: $mapping.description)
                    columnPicker("Amount", selection: $mapping.amount)
                    Toggle("Expenses are negative amounts", isOn: $mapping.invertAmounts)
                }
                Section("Preview") {
                    if isParsing || parsedMapping != mapping {
                        ProgressView("Preparing preview")
                    } else if let message = validationError {
                        Text(message).foregroundStyle(.red)
                    } else {
                        Text("Only positive expense amounts will be imported; zero amounts and credits are skipped.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(transactions.prefix(20)) { transaction in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(transaction.name)
                                    Text(transaction.date, style: .date).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(transaction.amount, format: .currency(code: currencyCode))
                            }
                        }
                        if transactions.count > 20 {
                            Text("Showing 20 of \(transactions.count) transactions").font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Review import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") { importTransactions() }
                        .disabled(isParsing || parsedMapping != mapping || validationError != nil || !transactions.contains { $0.amount > 0 })
                }
            }
            .alert("Import failed", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
            .task(id: mapping) {
                isParsing = true
                let selectedMapping = mapping
                let inputRows = rows
                let result = await Task.detached(priority: .userInitiated) {
                    Result { try CSVParser.transactions(rows: inputRows, mapping: selectedMapping) }
                }.value
                guard !Task.isCancelled else { return }
                switch result {
                case .success(let parsed):
                    transactions = parsed
                    validationError = nil
                case .failure(let error):
                    transactions = []
                    validationError = error.localizedDescription
                }
                parsedMapping = selectedMapping
                isParsing = false
            }
        }
    }

    private func columnPicker(_ title: String, selection: Binding<Int>) -> some View {
        Picker(title, selection: selection) {
            ForEach(rows[0].indices, id: \.self) { index in
                Text("\(rows[0][index]) (\(index + 1))").tag(index)
            }
        }
    }

    private func importTransactions() {
        do {
            for transaction in transactions where transaction.amount > 0 {
                context.insert(Expense(name: transaction.name, amount: transaction.amount, date: transaction.date,
                                       category: CategorizationRules.category(for: transaction.name)))
            }
            try context.save()
            dismiss()
        } catch {
            context.rollback()
            self.error = error.localizedDescription
        }
    }
}

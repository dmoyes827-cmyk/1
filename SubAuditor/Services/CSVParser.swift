import Foundation

enum CSVError: LocalizedError {
    case invalidEncoding, malformedCSV, emptyFile, invalidMapping, invalidRow(Int)

    var errorDescription: String? {
        switch self {
        case .invalidEncoding: "The file must be UTF-8 encoded."
        case .malformedCSV: "The CSV contains an invalid quoted field."
        case .emptyFile: "The CSV must contain a header and at least one transaction."
        case .invalidMapping: "Choose different columns for the date, description, and amount."
        case .invalidRow(let row): "Check the date and amount on CSV row \(row)."
        }
    }
}

struct CSVMapping: Equatable {
    var date: Int
    var description: Int
    var amount: Int
    var invertAmounts = false
}

struct CSVTransaction: Identifiable {
    let id = UUID()
    let date: Date
    let name: String
    let amount: Double
}

enum CSVParser {
    static func parse(_ data: Data) throws -> [[String]] {
        guard let text = String(data: data, encoding: .utf8) else { throw CSVError.invalidEncoding }
        let characters = Array(text.hasPrefix("\u{feff}") ? String(text.dropFirst()) : text)
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var quoted = false
        var closedQuote = false
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if quoted {
                if character == "\"" {
                    if index + 1 < characters.count && characters[index + 1] == "\"" {
                        field.append("\"")
                        index += 1
                    } else {
                        quoted = false
                        closedQuote = true
                    }
                } else {
                    field.append(character)
                }
            } else if character == "\"" {
                guard field.isEmpty && !closedQuote else { throw CSVError.malformedCSV }
                quoted = true
            } else if character == "," {
                row.append(field)
                field = ""
                closedQuote = false
            } else if character == "\n" || character == "\r" || character == "\r\n" {
                row.append(field)
                if row.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                    rows.append(row)
                }
                row = []
                field = ""
                closedQuote = false
                if character == "\r" && index + 1 < characters.count && characters[index + 1] == "\n" {
                    index += 1
                }
            } else {
                guard !closedQuote else { throw CSVError.malformedCSV }
                field.append(character)
            }
            index += 1
        }
        guard !quoted else { throw CSVError.malformedCSV }
        if !field.isEmpty || !row.isEmpty || closedQuote {
            row.append(field)
            if row.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                rows.append(row)
            }
        }
        guard rows.count > 1 else { throw CSVError.emptyFile }
        return rows
    }

    static func suggestedMapping(headers: [String]) -> CSVMapping {
        func find(_ terms: [String], fallback: Int) -> Int {
            headers.firstIndex { header in terms.contains { header.lowercased().contains($0) } } ?? fallback
        }
        return CSVMapping(date: find(["date"], fallback: 0),
                          description: find(["description", "merchant", "name", "payee"], fallback: min(1, headers.count - 1)),
                          amount: find(["amount", "debit"], fallback: min(2, headers.count - 1)))
    }

    static func transactions(rows: [[String]], mapping: CSVMapping) throws -> [CSVTransaction] {
        guard let headers = rows.first,
              [mapping.date, mapping.description, mapping.amount].allSatisfy({ headers.indices.contains($0) }),
              Set([mapping.date, mapping.description, mapping.amount]).count == 3 else {
            throw CSVError.invalidMapping
        }
        return try rows.dropFirst().enumerated().map { index, row in
            guard [mapping.date, mapping.description, mapping.amount].allSatisfy({ row.indices.contains($0) }),
                  let date = parseDate(row[mapping.date]),
                  let amount = parseAmount(row[mapping.amount]),
                  !row[mapping.description].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CSVError.invalidRow(index + 2)
            }
            return CSVTransaction(date: date, name: row[mapping.description].trimmingCharacters(in: .whitespacesAndNewlines),
                                  amount: mapping.invertAmounts ? -amount : amount)
        }
    }

    private static func parseDate(_ text: String) -> Date? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let iso = value.contains("-")
        let parts = value.split(separator: iso ? "-" : "/", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy { $0 >= "0" && $0 <= "9" } }),
              let first = Int(parts[0]), let second = Int(parts[1]), let third = Int(parts[2]) else { return nil }
        let year: Int
        let month: Int
        let day: Int
        if iso {
            guard parts[0].count == 4, parts[1].count == 2, parts[2].count == 2 else { return nil }
            (year, month, day) = (first, second, third)
        } else {
            guard (1...2).contains(parts[0].count), (1...2).contains(parts[1].count),
                  parts[2].count == 2 || parts[2].count == 4 else { return nil }
            (year, month, day) = (parts[2].count == 2 ? 2000 + third : third, first, second)
        }
        guard year > 0 else { return nil }
        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return components.year == year && components.month == month && components.day == day ? date : nil
    }

    private static func parseAmount(_ text: String) -> Double? {
        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let negative = value.hasPrefix("(") && value.hasSuffix(")")
        if negative { value = String(value.dropFirst().dropLast()) }
        value = value.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        guard let amount = Double(value), amount.isFinite else { return nil }
        return negative ? -abs(amount) : amount
    }
}

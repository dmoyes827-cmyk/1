# SubAuditor

SubAuditor is an iOS 17+ app for tracking expenses and subscriptions. Open
`SubAuditor.xcodeproj` in Xcode 15 or later, select the SubAuditor scheme and
run it on an iOS simulator or device. For a device, select your signing team
and a unique bundle identifier.

Add subscriptions with their next renewal date and billing cycle. The dashboard
shows normalized monthly costs, renewals occurring today and the following six
days, and possible duplicates. Renewal dates are entered manually; update them
when a bill renews. Toggle inactive subscriptions off to exclude them from
costs and upcoming bills. Siri shortcuts can log an expense or list upcoming
bills.

The import screen accepts UTF-8 CSV files with a header row. Map date,
description, and amount columns and review the preview before importing.
Supported dates are `yyyy-MM-dd`, `MM/dd/yyyy`, and `MM/dd/yy`. Amounts may
include dollar signs, commas, or parentheses. Two-digit years are interpreted
as 2000–2099. By default positive amounts are
expenses; enable the negative-amount toggle for banks that export debits as
negative numbers. Zero amounts and credits are skipped. Imports are not
deduplicated automatically; the dashboard flags possible duplicates for review.
The app displays amounts in the device's current currency and does not perform
currency conversion.

Data is stored locally by default. The SwiftData models have default values and
no required relationships, so they can be used with CloudKit. To enable sync,
configure an iCloud container and the CloudKit capability for your own signing
team, then change `cloudKitDatabase: .none` to `.automatic` in
`SubAuditor/App/SubAuditorApp.swift`. Test CloudKit with your own container and
account before distributing the app.
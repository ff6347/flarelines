// ABOUTME: Displays health progress charts and journal entry history.
// ABOUTME: Shows time-range filtered data visualization and grouped entries.

import SwiftUI
import Charts
import CoreData

// MARK: - Time Range

enum TimeRange: String, CaseIterable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case ninetyDays = "90D"
    case oneEightyDays = "180D"
    case oneYear = "1Y"
    case all = "All"

    var days: Int? {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .oneEightyDays: return 180
        case .oneYear: return 365
        case .all: return nil
        }
    }
}

// MARK: - Health Progress Chart

private struct HealthProgressChart: View {
    let entries: [JournalEntry]
    let selectedEntryID: UUID?
    let selectedDateRange: ClosedRange<Date>?
    let xDomain: ClosedRange<Date>
    @Binding var selectedTimeRange: TimeRange
    var onSelectEntry: (JournalEntry?) -> Void
    var onSelectRange: (ClosedRange<Date>?) -> Void

    @State private var rawSelectedDate: Date?
    @State private var dragRange: ClosedRange<Date>?

    private var selectedEntry: JournalEntry? {
        entries.first { $0.id == selectedEntryID }
    }

    private var activeRange: ClosedRange<Date>? {
        dragRange ?? selectedDateRange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            chartHeader
            timeRangePicker
            chartContent
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }

    private var chartHeader: some View {
        HStack {
            Image(systemName: "cylinder.split.1x2")
            Text("Health Progress")
                .font(DesignTokens.Typography.subheading)
            Spacer()
            Text("\(entries.count) entries")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
        }
        .foregroundColor(.primary)
    }

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var chartContent: some View {
        if !entries.isEmpty {
            chart
        } else {
            Text("No data available for this time range")
                .foregroundColor(.secondary)
                .frame(height: DesignTokens.Dimensions.chartHeight)
                .frame(maxWidth: .infinity)
        }
    }

    private var chart: some View {
        Chart {
            // Range selection highlight
            if let range = activeRange {
                RectangleMark(
                    xStart: .value("Start", range.lowerBound),
                    xEnd: .value("End", range.upperBound)
                )
                .foregroundStyle(DesignTokens.Colors.accent.opacity(0.15))
            }

            ForEach(entries) { entry in
                LineMark(
                    x: .value("Date", entry.timestamp),
                    y: .value("Score", Double(entry.userScore))
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(DesignTokens.Colors.chartLine)

                PointMark(
                    x: .value("Date", entry.timestamp),
                    y: .value("Score", Double(entry.userScore))
                )
                .symbolSize(DesignTokens.Dimensions.chartPointSize * 2.5)
                .foregroundStyle(DesignTokens.Colors.chartPoint)
            }

            if let entry = selectedEntry {
                RuleMark(x: .value("Selected", entry.timestamp))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))

                PointMark(
                    x: .value("Date", entry.timestamp),
                    y: .value("Score", Double(entry.userScore))
                )
                .symbolSize(DesignTokens.Dimensions.chartPointSize * 4)
                .foregroundStyle(DesignTokens.Colors.accent)
            }
        }
        .frame(height: DesignTokens.Dimensions.chartHeight)
        .chartXScale(domain: xDomain)
        .chartYScale(domain: 0...3)
        .chartXSelection(value: $rawSelectedDate)
        .chartXSelection(range: $dragRange)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month().day())
                    .font(DesignTokens.Typography.caption)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 1, 2, 3]) { _ in
                AxisValueLabel()
                    .font(DesignTokens.Typography.caption)
            }
        }
        .chartGesture { chart in
            DragGesture(minimumDistance: 15)
                .onChanged { value in
                    chart.selectXRange(from: value.startLocation.x, to: value.location.x)
                }
                .onEnded { _ in
                    // Commit the drag range as selected range
                    if let range = dragRange {
                        onSelectRange(range)
                        onSelectEntry(nil)  // Clear single entry selection
                    }
                    dragRange = nil
                }
        }
        .onTapGesture { location in
            // Tap clears range selection, or selects nearest entry
            if selectedDateRange != nil {
                onSelectRange(nil)
            }
        }
        .onChange(of: rawSelectedDate) { _, newDate in
            if let newDate, selectedDateRange == nil {
                // Only do single entry selection if no range is active
                let nearest = entries.min(by: {
                    abs($0.timestamp.timeIntervalSince(newDate)) < abs($1.timestamp.timeIntervalSince(newDate))
                })
                onSelectEntry(nearest)
            }
            rawSelectedDate = nil
        }
    }
}

// MARK: - Journal Entries List

private struct JournalEntriesList: View {
    let entries: FetchedResults<JournalEntry>
    let groupedEntries: [GroupedEntry]
    let selectedEntryID: UUID?

    var body: some View {
        List {
            entriesContent
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var entriesContent: some View {
        if entries.isEmpty {
            Section {
                Text("No entries yet. Start logging your health journey!")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
        } else {
            ForEach(groupedEntries, id: \.date) { group in
                Section {
                    ForEach(group.entries) { entry in
                        JournalEntryCard(entry: entry, isHighlighted: selectedEntryID == entry.id)
                            .id(entry.id)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(
                                Rectangle().fill(
                                    selectedEntryID == entry.id
                                        ? DesignTokens.Colors.accent.opacity(0.15)
                                        : Color(UIColor.systemBackground)
                                )
                            )
                            .listRowSeparator(.visible)
                    }
                } header: {
                    Text(group.date, style: .date)
                        .font(DesignTokens.Typography.subheading)
                        .foregroundColor(.primary)
                        .textCase(nil)
                }
            }
        }
    }
}

// MARK: - Data View

struct DataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<JournalEntry>

    @State private var selectedTimeRange: TimeRange = .thirtyDays
    @State private var selectedEntryID: UUID?
    @State private var selectedDateRange: ClosedRange<Date>?

    var filteredEntries: [JournalEntry] {
        guard let days = selectedTimeRange.days else {
            return Array(entries)
        }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.timestamp >= cutoffDate }
    }

    /// Entries filtered by custom date range (if selected)
    var rangeFilteredEntries: [JournalEntry] {
        guard let range = selectedDateRange else {
            return filteredEntries
        }
        return filteredEntries.filter { $0.timestamp >= range.lowerBound && $0.timestamp <= range.upperBound }
    }

    var sortedFilteredEntries: [JournalEntry] {
        filteredEntries.sorted { $0.timestamp < $1.timestamp }
    }

    var chartXDomain: ClosedRange<Date> {
        let now = Date()
        if let days = selectedTimeRange.days {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
            return cutoffDate...now
        } else {
            // "All" - use earliest entry date or default to 1 year
            let earliest = entries.map(\.timestamp).min() ?? Calendar.current.date(byAdding: .year, value: -1, to: now)!
            return earliest...now
        }
    }

    var groupedEntries: [GroupedEntry] {
        let calendar = Calendar.current
        let entriesToGroup = selectedDateRange != nil ? rangeFilteredEntries : Array(entries)
        let grouped = Dictionary(grouping: entriesToGroup) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        return grouped.map { GroupedEntry(date: $0.key, entries: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            HealthProgressChart(
                entries: sortedFilteredEntries,
                selectedEntryID: selectedEntryID,
                selectedDateRange: selectedDateRange,
                xDomain: chartXDomain,
                selectedTimeRange: $selectedTimeRange,
                onSelectEntry: { entry in
                    selectedEntryID = entry?.id
                },
                onSelectRange: { range in
                    selectedDateRange = range
                }
            )

            Divider()

            // Fixed Journal Entries Header
            HStack {
                Image(systemName: "book")
                Text("Journal Entries")
                    .font(DesignTokens.Typography.subheading)

                if let range = selectedDateRange {
                    Text("(\(range.lowerBound, format: .dateTime.month().day()) - \(range.upperBound, format: .dateTime.month().day()))")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if selectedDateRange != nil {
                    Button {
                        selectedDateRange = nil
                    } label: {
                        Text("Clear")
                            .font(DesignTokens.Typography.caption)
                    }
                }
            }
            .foregroundColor(.primary)
            .padding(.horizontal)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(Color(UIColor.systemBackground))

            ScrollViewReader { proxy in
                JournalEntriesList(
                    entries: entries,
                    groupedEntries: groupedEntries,
                    selectedEntryID: selectedEntryID
                )
                .onChange(of: selectedEntryID) { _, newID in
                    if let newID {
                        withAnimation {
                            proxy.scrollTo(newID, anchor: .center)
                        }
                    }
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct GroupedEntry {
    let date: Date
    let entries: [JournalEntry]
}

struct JournalEntryCard: View {
    let entry: JournalEntry
    var isHighlighted: Bool = false
    @State private var showingEditSheet = false
    @Environment(\.managedObjectContext) private var viewContext

    private var scoreLabel: String {
        switch entry.userScore {
        case 0: return "Remission"
        case 1: return "Mild"
        case 2: return "Moderate"
        case 3: return "Severe"
        default: return "Unknown"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text(entry.timestamp, style: .time)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text("\(entry.userScore) - \(scoreLabel)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)

                    if entry.mlScore >= 0 && entry.mlScore != entry.userScore {
                        Text("(ML: \(entry.mlScore))")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            if let journalText = entry.journalText, !journalText.isEmpty {
                Text(journalText)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.md)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteEntry()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                showingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditEntryView(entry: entry)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private func deleteEntry() {
        viewContext.delete(entry)
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete entry: \(error)")
        }
    }
}

#Preview {
    DataView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

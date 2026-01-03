// ABOUTME: Displays health progress charts and journal entry history.
// ABOUTME: Shows time-range filtered data visualization and grouped entries.

import SwiftUI
import Charts
import CoreData

struct DataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<JournalEntry>
    
    @State private var selectedTimeRange: TimeRange = .thirtyDays
    
    enum TimeRange: String, CaseIterable {
        case sevenDays = "7D"
        case thirtyDays = "30D"
        case ninetyDays = "90D"
        case oneEightyDays = "180D"
        case oneYear = "1Y"
        
        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .ninetyDays: return 90
            case .oneEightyDays: return 180
            case .oneYear: return 365
            }
        }
    }
    
    var filteredEntries: [JournalEntry] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return entries.filter { $0.timestamp >= cutoffDate }
    }
    
    var sortedFilteredEntries: [JournalEntry] {
        filteredEntries.sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        List {
            // Health Progress Chart Section
            Section {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    HStack {
                        Image(systemName: "cylinder.split.1x2")
                        Text("Health Progress")
                            .font(DesignTokens.Typography.subheading)
                        Spacer()
                        Text("\(filteredEntries.count) entries")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)

                    // Time Range Selector
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(action: {
                                selectedTimeRange = range
                            }) {
                                Text(range.rawValue)
                                    .font(DesignTokens.Typography.caption)
                                    .fontWeight(selectedTimeRange == range ? .semibold : .regular)
                                    .foregroundColor(selectedTimeRange == range ? .white : .primary)
                                    .padding(.horizontal, DesignTokens.Spacing.md)
                                    .padding(.vertical, DesignTokens.Spacing.sm)
                                    .background(selectedTimeRange == range ? Color.black : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm, style: .continuous))
                            }
                        }
                    }

                    // Chart
                    if !filteredEntries.isEmpty {
                        Chart {
                            ForEach(sortedFilteredEntries) { entry in
                                LineMark(
                                    x: .value("Date", entry.timestamp),
                                    y: .value("Health", entry.healthScore)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(.primary)

                                PointMark(
                                    x: .value("Date", entry.timestamp),
                                    y: .value("Health", entry.healthScore)
                                )
                                .symbolSize(DesignTokens.Dimensions.chartPointSize)
                                .foregroundStyle(.primary)
                            }
                        }
                        .frame(height: DesignTokens.Dimensions.chartHeight)
                        .chartYScale(domain: 0...10)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisValueLabel(format: .dateTime.month().day())
                                    .font(DesignTokens.Typography.caption)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel()
                                    .font(DesignTokens.Typography.caption)
                            }
                        }
                    } else {
                        Text("No data available for this time range")
                            .foregroundColor(.secondary)
                            .frame(height: DesignTokens.Dimensions.chartHeight)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // Journal Entries Header
            Section {
                HStack {
                    Image(systemName: "book")
                    Text("Journal Entries")
                        .font(DesignTokens.Typography.subheading)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // Journal Entries grouped by date
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
                            JournalEntryCard(entry: entry)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Rectangle().fill(Color(UIColor.systemBackground)))
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
        .listStyle(.plain)
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
    
    var groupedEntries: [GroupedEntry] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        return grouped.map { GroupedEntry(date: $0.key, entries: $0.value) }
            .sorted { $0.date > $1.date }
    }
}

struct GroupedEntry {
    let date: Date
    let entries: [JournalEntry]
}

struct JournalEntryCard: View {
    let entry: JournalEntry
    @State private var showingEditSheet = false
    @Environment(\.managedObjectContext) private var viewContext

    private var activityScoreLabel: String {
        switch entry.painLevel {
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

                Text("\(entry.painLevel) - \(activityScoreLabel)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
            }

            if let feeling = entry.feeling, !feeling.isEmpty {
                Text(feeling)
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

//
//  DataView.swift
//  wolfsbit
//
//  Created by Fabian Moron Zirfas on 13.11.25.
//

import SwiftUI
import Charts
import CoreData

struct DataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
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
        ScrollView {
            VStack(spacing: 24) {
                // Health Progress Chart
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Health Progress")
                            .font(.headline)
                        Spacer()
                        Text("\(filteredEntries.count) entries")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                    
                    // Time Range Selector
                    HStack(spacing: 8) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(action: {
                                selectedTimeRange = range
                            }) {
                                Text(range.rawValue)
                                    .font(.caption)
                                    .fontWeight(selectedTimeRange == range ? .semibold : .regular)
                                    .foregroundColor(selectedTimeRange == range ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTimeRange == range ? Color.black : Color.clear)
                                    .cornerRadius(4)
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
                                .foregroundStyle(Color.blue)
                                
                                PointMark(
                                    x: .value("Date", entry.timestamp),
                                    y: .value("Health", entry.healthScore)
                                )
                                .symbolSize(60)
                                .foregroundStyle(Color.blue)
                            }
                        }
                        .frame(height: 200)
                        .chartYScale(domain: 0...10)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisValueLabel(format: .dateTime.month().day())
                                    .font(.caption2)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel()
                                    .font(.caption2)
                            }
                        }
                    } else {
                        Text("No data available for this time range")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                
                // Journal Entries
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "book")
                        Text("Journal Entries")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    if entries.isEmpty {
                        Text("No entries yet. Start logging your health journey!")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(groupedEntries, id: \.date) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                // Date Header
                                Text(group.date, style: .date)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.black)
                                
                                // Entries for this date
                                ForEach(group.entries) { entry in
                                    JournalEntryCard(entry: entry)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
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
    @State private var isExpanded = false
    @State private var showingEditSheet = false
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .sheet(isPresented: $showingEditSheet) {
                    EditEntryView(entry: entry)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            
            // Question 1: How are you feeling?
            VStack(alignment: .leading, spacing: 4) {
                Text("How are you feeling today?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(entry.feeling ?? "No response")
                    .font(.subheadline)
            }
            
            // Question 2: Pain level
            VStack(alignment: .leading, spacing: 4) {
                Text("Describe your pain level")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Pain level: \(entry.painLevel)/10")
                    .font(.subheadline)
            }
            
            // Question 3: Symptoms
            VStack(alignment: .leading, spacing: 4) {
                Text("Any symptoms you noticed?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(entry.symptoms ?? "No symptoms reported")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
}

#Preview {
    DataView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

//
//  JournalViewModel.swift
//  wolfsbit
//
//  Created by Fabian Moron Zirfas on 13.11.25.
//

import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class JournalViewModel: ObservableObject {
    @Published var currentQuestionIndex = 0
    @Published var answers: [Int: String] = [:]
    @Published var isRecording = false
    
    let questions = HealthQuestion.defaultQuestions
    private let viewContext: NSManagedObjectContext
    
    var currentQuestion: HealthQuestion {
        questions[currentQuestionIndex]
    }
    
    var progress: Double {
        Double(currentQuestionIndex + 1) / Double(questions.count)
    }
    
    var canGoNext: Bool {
        currentQuestionIndex < questions.count - 1
    }
    
    var canGoPrevious: Bool {
        currentQuestionIndex > 0
    }
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    func nextQuestion() {
        if canGoNext {
            withAnimation {
                currentQuestionIndex += 1
            }
        }
    }
    
    func previousQuestion() {
        if canGoPrevious {
            withAnimation {
                currentQuestionIndex -= 1
            }
        }
    }
    
    func updateAnswer(_ answer: String) {
        answers[currentQuestion.id] = answer
    }
    
    func getCurrentAnswer() -> String {
        answers[currentQuestion.id] ?? ""
    }
    
    func saveEntry() {
        let entry = JournalEntry(context: viewContext)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.feeling = answers[1]
        entry.symptoms = answers[3]

        // Parse pain level from answer 2
        if let painString = answers[2],
           let painValue = extractPainLevel(from: painString) {
            entry.painLevel = Int16(painValue)
        }

        // Calculate heuristic score (updated field name)
        entry.heuristicScore = calculateHeuristicScore(painLevel: entry.painLevel)

        // Initialize ML fields (no model yet)
        entry.mlScore = 0.0
        entry.scoreConfidence = 0.0
        entry.activeScore = entry.heuristicScore  // Use heuristic for now
        entry.needsReview = false

        // Initialize user flags
        entry.isFlaggedDay = false
        entry.notes = nil

        do {
            try viewContext.save()
            resetForm()
        } catch {
            print("Error saving entry: \(error)")
        }
    }
    
    func resetForm() {
        answers.removeAll()
        currentQuestionIndex = 0
    }
    
    private func extractPainLevel(from text: String) -> Int? {
        // Extract number from text like "7/10" or "around 3"
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
        return numbers.compactMap { Int($0) }.first
    }
    
    private func calculateHeuristicScore(painLevel: Int16) -> Double {
        // Convert pain level (0-10) to health score (0-10)
        // Lower pain = higher health score
        return 10.0 - Double(painLevel)
    }
    
    func toggleRecording() {
        isRecording.toggle()
        // Voice recording implementation would go here
        // You'll need to integrate Speech framework
    }
}

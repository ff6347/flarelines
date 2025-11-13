//
//  HealthQuestion.swift
//  wolfsbit
//
//  Created by Fabian Moron Zirfas on 13.11.25.
//

import Foundation

struct HealthQuestion: Identifiable {
    let id: Int
    let text: String
    let placeholder: String
    let type: QuestionType
    
    enum QuestionType {
        case text
        case painScale
        case symptoms
    }
}

extension HealthQuestion {
    static let defaultQuestions: [HealthQuestion] = [
        HealthQuestion(
            id: 1,
            text: "How are you feeling today?",
            placeholder: "Type your answer or use voice input...",
            type: .text
        ),
        HealthQuestion(
            id: 2,
            text: "Describe your pain level",
            placeholder: "Rate your pain from 0-10...",
            type: .painScale
        ),
        HealthQuestion(
            id: 3,
            text: "Any symptoms you noticed?",
            placeholder: "Describe any symptoms...",
            type: .symptoms
        )
    ]
}

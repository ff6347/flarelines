//
//  LogView.swift
//  wolfsbit
//
//  Created by Fabian Moron Zirfas on 13.11.25.
//

import SwiftUI
import Speech
import CoreData

struct LogView: View {
    @StateObject private var viewModel: JournalViewModel
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var currentAnswer = ""
    @State private var showingSavedAlert = false
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: JournalViewModel(context: context))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Section
            VStack(spacing: 12) {
                HStack {
                    Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questions.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: viewModel.progress)
                    .tint(.primary)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            Spacer()
            
            // Question Card
            VStack(spacing: 24) {
                Text(viewModel.currentQuestion.text)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color.black)
                    .cornerRadius(8)
                
                // Text Input Area
                TextEditor(text: $currentAnswer)
                    .frame(height: 200)
                    .padding(12)
                    .background(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if currentAnswer.isEmpty {
                            Text(viewModel.currentQuestion.placeholder)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }
                    .onChange(of: currentAnswer) { _, newValue in
                        viewModel.updateAnswer(newValue)
                    }
                    .onAppear {
                        currentAnswer = viewModel.getCurrentAnswer()
                    }
                
                // Voice Input Button
                Button(action: {
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                        currentAnswer += (currentAnswer.isEmpty ? "" : " ") + speechRecognizer.transcript
                        viewModel.updateAnswer(currentAnswer)
                    } else {
                        do {
                            try speechRecognizer.startRecording()
                        } catch {
                            print("Failed to start recording: \(error)")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                        Text(speechRecognizer.isRecording ? "Recording..." : "Voice Input")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(speechRecognizer.isRecording ? Color.red.opacity(0.1) : Color(UIColor.systemBackground))
                    .foregroundColor(speechRecognizer.isRecording ? .red : .primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(speechRecognizer.isRecording ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(speechRecognizer.authorizationStatus != .authorized)
                
                // Show live transcription while recording
                if speechRecognizer.isRecording && !speechRecognizer.transcript.isEmpty {
                    Text("Transcribing: \(speechRecognizer.transcript)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.previousQuestion()
                        currentAnswer = viewModel.getCurrentAnswer()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .foregroundColor(viewModel.canGoPrevious ? .primary : .gray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(!viewModel.canGoPrevious)
                    
                    Button(action: {
                        if viewModel.canGoNext {
                            viewModel.nextQuestion()
                            currentAnswer = viewModel.getCurrentAnswer()
                        } else {
                            // Last question - save entry
                            viewModel.saveEntry()
                            currentAnswer = ""
                            showingSavedAlert = true
                        }
                    }) {
                        HStack {
                            Text(viewModel.canGoNext ? "Next" : "Save")
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .alert("Entry Saved", isPresented: $showingSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your journal entry has been saved successfully.")
        }
    }
}

#Preview {
    LogView(context: PersistenceController.preview.container.viewContext)
}

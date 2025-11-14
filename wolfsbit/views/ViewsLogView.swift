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

    // Computed property for displaying text with live transcription
    private var displayText: String {
        if speechRecognizer.isRecording && !speechRecognizer.transcript.isEmpty {
            return currentAnswer + (currentAnswer.isEmpty ? "" : " ") + speechRecognizer.transcript
        }
        return currentAnswer
    }
    
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
                
                // Text Input Area with live transcription
                ZStack(alignment: .topLeading) {
                    // Base text editor (only editable when not recording)
                    TextEditor(text: $currentAnswer)
                        .frame(height: 200)
                        .padding(12)
                        .background(Color(UIColor.systemBackground))
                        .opacity(speechRecognizer.isRecording ? 0 : 1)
                        .onChange(of: currentAnswer) { _, newValue in
                            viewModel.updateAnswer(newValue)
                        }

                    // Display text with live transcription overlay
                    if speechRecognizer.isRecording {
                        VStack(alignment: .leading) {
                            // Existing text in black
                            if !currentAnswer.isEmpty {
                                Text(currentAnswer)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            // Live transcription in gray
                            if !speechRecognizer.transcript.isEmpty {
                                Text(speechRecognizer.transcript)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .font(.body)
                        .padding(16)
                        .frame(height: 200, alignment: .topLeading)
                    }

                    // Placeholder
                    if currentAnswer.isEmpty && !speechRecognizer.isRecording {
                        Text(viewModel.currentQuestion.placeholder)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
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

                // Navigation Buttons (locked while recording)
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
                        .foregroundColor(viewModel.canGoPrevious && !speechRecognizer.isRecording ? .primary : .gray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(!viewModel.canGoPrevious || speechRecognizer.isRecording)
                    
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
                        .background(speechRecognizer.isRecording ? Color.gray : Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(speechRecognizer.isRecording)
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

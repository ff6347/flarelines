// ABOUTME: Speech-to-text transcription using iOS Speech framework.
// ABOUTME: Uses the app's selected language for recognition locale.

import Foundation
import Speech
import SwiftUI
import AVFoundation
import Combine

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    /// Creates a speech recognizer for the currently selected app language.
    private var speechRecognizer: SFSpeechRecognizer? {
        SFSpeechRecognizer(locale: LanguagePreference.shared.locale)
    }

    init() {
        // Don't request authorization here - let views request it explicitly
        // when the user is ready (e.g., after seeing the onboarding explanation)
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }

    func requestAuthorization() async {
        authorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    func startRecording() throws {
        // Cancel any ongoing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw RecognizerError.nilRecognitionRequest
        }

        recognitionRequest.shouldReportPartialResults = true

        // Start recording
        let inputNode = audioEngine.inputNode

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            var isFinal = false

            if let result = result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                    isFinal = result.isFinal
                }
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                Task { @MainActor in
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    self.isRecording = false
                }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
        transcript = ""
    }

    func stopRecording() {
        // Stop audio engine
        audioEngine.stop()

        // Remove tap to prevent crash on next recording
        audioEngine.inputNode.removeTap(onBus: 0)

        // End recognition
        recognitionRequest?.endAudio()
        isRecording = false
    }

    enum RecognizerError: Error {
        case nilRecognitionRequest
        case notAuthorized
    }
}

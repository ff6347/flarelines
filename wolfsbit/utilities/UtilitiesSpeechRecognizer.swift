//
//  SpeechRecognizer.swift
//  wolfsbit
//
//  Created by Fabian Moron Zirfas on 13.11.25.
//

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
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    init() {
        Task {
            await requestAuthorization()
        }
    }
    
    func requestAuthorization() async {
        authorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    func startRecording() throws {
        // Reset any ongoing recording
        reset()

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        // Get input node
        let inputNode = audioEngine.inputNode

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if error != nil || result?.isFinal == true {
                Task { @MainActor in
                    self.reset()
                }
            }
        }

        // Install tap with nil format to use the input node's default format
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
        transcript = ""
    }

    func stopRecording() {
        recognitionRequest?.endAudio()
        reset()
    }

    private func reset() {
        // Stop recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        // Stop audio engine and remove tap
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        // Always try to remove the tap (it's safe to call even if no tap exists)
        let inputNode = audioEngine.inputNode
        if inputNode.numberOfInputs > 0 {
            inputNode.removeTap(onBus: 0)
        }

        isRecording = false
    }
    
    enum RecognizerError: Error {
        case nilRecognitionRequest
        case notAuthorized
    }
}

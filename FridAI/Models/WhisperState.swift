//
//  WhisperState.swift
//  FridAI
//
//  Created by Sushant Thyagaraj on 4/13/23.
//

import AVFoundation
import Foundation
import SwiftUI

@MainActor
class WhisperState: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isModelLoaded = false
    @Published var messageLog = ""
    @Published var canTranscribe = false
    @Published var isRecording = false

    private var whisperContext: WhisperContext?
    private var recordedFile: URL? = nil
    private let recorder = Recorder()
    private var audioPlayer: AVAudioPlayer?

    private var modelUrl: URL? {
        Bundle.main.url(forResource: "ggml-tiny.en", withExtension: "bin", subdirectory: "Data/models")
    }

    private var sampleUrl: URL? {
        Bundle.main.url(forResource: "jfk", withExtension: "wav", subdirectory: "Data/samples")
    }

    override init() {
        super.init()
        do {
            try loadModel()
            canTranscribe = true
        } catch {
            print(error.localizedDescription)
            messageLog += "\(error.localizedDescription)\n"
        }
    }

    private func loadModel() throws {
        messageLog += "Loading model...\n"
        if let modelUrl {
            if #available(macOS 13.0, *) {
                whisperContext = try WhisperContext.createContext(path: modelUrl.path())
            } else {
                whisperContext = try WhisperContext.createContext(path: modelUrl.path)
            }
            messageLog += "Model loaded \(modelUrl.lastPathComponent)\n"
        } else {
            messageLog += "Model not found\n"
        }
    }

    func transcribeSample() async {
        if let sampleUrl {
            await transcribeAudio(sampleUrl)
        } else {
            messageLog += "Sample not found\n"
        }
    }

    private func transcribeAudio(_ url: URL) async {
        if !canTranscribe {
            return
        }

        guard let whisperContext else {
            return
        }

        do {
            canTranscribe = false
            messageLog += "Reading wave samples\n"
            let data = try readAudioSamples(url)
            messageLog += "Transcribing...\n"
            await whisperContext.fullTranscribe(samples: data)
            let text = await whisperContext.getTranscription()
            messageLog += "Done: \(text)\n"
        } catch {
            print(error.localizedDescription)
            messageLog += "\(error.localizedDescription)\n"
        }
        canTranscribe = true
    }

    private func readAudioSamples(_ url: URL) throws -> [Float] {
        stopPlayback()
        try startPlayback(url)
        return try decodeWavFile(url)
    }

    func toggleRecord() async {
        if isRecording {
            await recorder.stopRecording()
            isRecording = false
            if let recordedFile {
                await transcribeAudio(recordedFile)
            }
        } else {
            requestRecordPermission { granted in
                if granted {
                    Task {
                        do {
                            self.stopPlayback()
                            let file: URL
                            if #available(macOS 13.0, *) {
                                file = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appending(path: "output.wav")
                            } else {
                                // Fallback on earlier versions
                                file = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("output.wav")
                            }
                            print(file)
                            try await self.recorder.startRecording(toOutputFile: file, delegate: self)
                            self.isRecording = true
                            self.recordedFile = file
                        } catch {
                            print(error.localizedDescription)
                            self.isRecording = false
                        }
                    }
                }
            }
        }
    }

    private func requestRecordPermission(response: @escaping (Bool) -> Void) {
        #if os(macOS)
            response(true)
        #else
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                response(granted)
            }
        #endif
    }

    private func startPlayback(_ url: URL) throws {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }

    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

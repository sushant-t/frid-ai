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
class WhisperState: NSObject, AVAudioRecorderDelegate {
    var isModelLoaded = false
    var canTranscribe = false
    var isRecording = false

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
    }

    public func prepare() {
        do {
            try loadModel()
            canTranscribe = true
        } catch {
            print(error.localizedDescription)
            Logger.shared.addLog(msg: "\(error.localizedDescription)\n")
        }
    }

    private func loadModel() throws {
        Logger.shared.addLog(msg: "Loading model...\n")
        if let modelUrl {
            if #available(macOS 13.0, *) {
                whisperContext = try WhisperContext.createContext(path: modelUrl.path())
            } else {
                whisperContext = try WhisperContext.createContext(path: modelUrl.path)
            }
            Logger.shared.addLog(msg: "Model loaded \(modelUrl.lastPathComponent)\n")
        } else {
            Logger.shared.addLog(msg: "Model not found\n")
        }
    }

    func transcribeSample() async {
        if let sampleUrl {
            _ = await transcribeAudio(sampleUrl)
        } else {
            Logger.shared.addLog(msg: "Sample not found\n")
        }
    }

    private func transcribeAudio(_ url: URL) async -> String {
        if !canTranscribe {
            return ""
        }

        guard let whisperContext else {
            return ""
        }

        var text = ""
        do {
            canTranscribe = false
            Logger.shared.addLog(msg: "Reading wave samples\n")
            let data = try readAudioSamples(url)
            Logger.shared.addLog(msg: "Transcribing...\n")
            await whisperContext.fullTranscribe(samples: data)
            text = await whisperContext.getTranscription()
            Logger.shared.addLog(msg: "Done: \(text)\n")
        } catch {
            print(error.localizedDescription)
            Logger.shared.addLog(msg: "\(error.localizedDescription)\n")
        }
        canTranscribe = true
        return text
    }

    private func readAudioSamples(_ url: URL) throws -> [Float] {
        return try decodeWavFile(url)
    }

    func stopAndProcessRecord() async -> String {
        await recorder.stopRecording()
        isRecording = false
        var text = ""
        if let recordedFile {
            text = await transcribeAudio(recordedFile)
        }
        return text
    }

    func startRecord() async {
        requestRecordPermission { granted in
            if granted {
                Task {
                    do {
                        let file: URL
                        if #available(macOS 13.0, *) {
                            file = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appending(path: "output.wav")
                        } else {
                            // Fallback on earlier versions
                            file = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("output.wav")
                        }
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

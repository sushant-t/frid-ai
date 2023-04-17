//
//  Recorder.swift
//  FridAI
//
//  Created by Sushant Thyagaraj on 4/13/23.
//

import AVFoundation
import Foundation

actor Recorder {
    private var recorder: AVAudioRecorder?

    enum RecorderError: Error {
        case couldNotStartRecording
    }

    func startRecording(toOutputFile url: URL, delegate: AVAudioRecorderDelegate?) throws {
        let recordSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        #if !os(macOS)
            let recordingSession = AVAudioSession.sharedInstance()
            try recordingSession.setCategory(.playAndRecord, mode: .default)
        #endif
        let recorder = try AVAudioRecorder(url: url, settings: recordSettings)
        recorder.delegate = delegate
        recorder.prepareToRecord()
        if recorder.record() == false {
            throw RecorderError.couldNotStartRecording
        }
        self.recorder = recorder
    }

    func stopRecording() {
        recorder?.stop()
        recorder = nil
    }
}

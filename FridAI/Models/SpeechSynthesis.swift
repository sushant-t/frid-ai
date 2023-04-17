//
//  SpeechSynthesis.swift
//  FridAI
//
//  Created by Sushant Thyagaraj on 4/16/23.
//

import AVFoundation
import Foundation

class SpeechSynthesis: NSObject {
    private var synthesizer: AVSpeechSynthesizer = .init()

    func dictate(text: String, locale: String = "en-US", rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } catch {
            print("Could not override audio port")
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: locale)
        utterance.rate = rate

        synthesizer.speak(utterance)
    }
}

//
//  SpeechSynthesis.swift
//  FridAI
//
//  Created by Sushant Thyagaraj on 4/16/23.
//

import AVFoundation
import Foundation
import PromiseKit

class SpeechSynthesis: NSObject, AVAudioPlayerDelegate {
    private var synthesizer: AVSpeechSynthesizer = .init()
    private var key = (Bundle.main.infoDictionary?["Google Cloud API Key"] as? String)!
    private var audioPlayer: AVAudioPlayer?

    private var audioHandler: (() -> Void)?
    private var audioDataQueue: [Data] = []
    private var audioPlaying: Bool = false

    func dictate(text: String, locale: String = "en-US", rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
        #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            } catch {
                print("Could not override audio port")
            }
        #endif
        print(AVSpeechSynthesisVoice.speechVoices())
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: locale)
        utterance.rate = rate
        synthesizer.speak(utterance)
    }

    func dictateFromAPI(text: String) throws {
        guard let url = URL(string: "https://texttospeech.googleapis.com/v1beta1/text:synthesize?key=\(key)") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        // Set HTTP Request Body
        let body = SynthesisBody(text: text, voiceCode: "en-US", voiceName: "en-US-Studio-M", voiceGender: "MALE")
        let jsonData = try JSONEncoder().encode(body)
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, _, error in

            if let error = error {
                print("Error took place \(error)")
                return
            }
            guard let data = data else {
                return
            }
            var audioContent = Data()
            do {
                let synthesisResponseModel = try JSONDecoder().decode(SynthesisResponse.self, from: data)
                audioContent = Data(base64Encoded: synthesisResponseModel.audioContent)!

            } catch let jsonErr {
                print(jsonErr)
                return
            }

            #if os(iOS)
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
                    try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
                    try audioSession.setActive(true)
                } catch {
                    print("Could not override audio port")
                }
            #endif
            self.audioDataQueue.append(audioContent)
            if !self.audioPlaying {
                self.audioPlaying = true
                do {
                    try self.playAudioContent()
                } catch {
                    print("Could not play audio")
                }
            }
        }
        task.resume()
    }

    func playAudioContent() throws {
        if audioDataQueue.isEmpty {
            audioPlaying = false
            return
        } else {
            let audioData = audioDataQueue.removeFirst()
            audioHandler = {
                Task {
                    try self.playAudioContent()
                }
            }
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        }
    }

    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully success: Bool) {
        if success, audioHandler != nil {
            audioHandler!()
        }
    }
}

struct SynthesisBody: Codable {
    private var input: SynthesisBodyInput
    private var voice: SynthesisBodyVoice
    private var audioConfig: SynthesisBodyAudioConfig

    init(text: String, voiceCode: String = "en-US", voiceName: String = "en-US-Standard-B", voiceGender: String = "MALE", audioEncoding: String = "LINEAR16") {
        input = SynthesisBodyInput(text: text)
        voice = SynthesisBodyVoice(languageCode: voiceCode, name: voiceName, ssmlGender: voiceGender)
        audioConfig = SynthesisBodyAudioConfig(audioEncoding: audioEncoding)
    }
}

struct SynthesisBodyInput: Codable {
    var text: String
}

struct SynthesisBodyVoice: Codable {
    var languageCode: String
    var name: String
    var ssmlGender: String
}

struct SynthesisBodyAudioConfig: Codable {
    var audioEncoding: String
}

struct SynthesisResponse: Decodable {
    var audioContent: String
}

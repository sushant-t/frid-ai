//
//  ConversationAgent.swift
//  FridAI
//
//  Created by Sushant Thyagaraj on 4/15/23.
//

import Foundation
import SwiftUI

enum ConversationStatus {
    case ready
    case listening
    case transcribing
    case responding
}

@MainActor
class ConversationAgent: NSObject, ObservableObject {
    private var openAIConnector: OpenAIConnector = .init()
    @Published var status: ConversationStatus = .ready
    @Published var currentResponse: String = ""

    private var lastResponses: [String] = []
    private var whisperState: WhisperState?
    private var speechSynthesis: SpeechSynthesis = .init()

    override init() {
        super.init()
        whisperState = WhisperState()
        whisperState!.prepare()
    }

    func startListening() async {
        updateStatus(status: ConversationStatus.listening)
        await whisperState!.startRecord()
    }

    func generateResponse(stream: Bool) async {
        updateStatus(status: ConversationStatus.transcribing)
        let text = await whisperState!.stopAndProcessRecord()
        var response = ""
        if !stream {
            response = await dictateChat(text: text)
        } else {
            currentResponse = ""
            response = await dictateChatStream(text: text)
        }
        addResponseToQueue(response: response)
    }

    func dictateChat(text: String) async -> String {
        var response = ""
        do {
            response = try await openAIConnector.completeChat(text, lastResponses)
            Logger.shared.addLog(msg: "\(response)\n")
            try speechSynthesis.dictateFromAPI(text: response)
        } catch {
            print(error.localizedDescription)
        }
        return response
    }

    func dictateChatStream(text: String) async -> String {
        var seenResponse = ""
        var recentSentence = ""

        do {
            let stream = try openAIConnector.completeChatStream(text, lastResponses)
            for await streamingMessage in stream {
                var mesg = streamingMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
                mesg = String(mesg[seenResponse.endIndex...])
                seenResponse += mesg
                if let firstIndex = mesg.firstIndex(where: { String($0).range(of: "[\\!\\?\\:\\;\\.\\—]", options: .regularExpression, range: nil, locale: nil) != nil })
                {
                    recentSentence += mesg[...firstIndex]
                    print(recentSentence)
                    currentResponse += recentSentence
                    queueDictation(currentDictation: recentSentence)
                    let lastChar = mesg.index(mesg.endIndex, offsetBy: -1, limitedBy: mesg.startIndex)!
                    if let charAfter = mesg.index(firstIndex, offsetBy: 1, limitedBy: lastChar) {
                        recentSentence = String(mesg[charAfter...])
                    } else {
                        recentSentence = ""
                    }
                } else {
                    recentSentence += mesg
                }
            }
            if !recentSentence.isEmpty { currentResponse += recentSentence
                queueDictation(currentDictation: recentSentence)
            }
        } catch {
            print(error.localizedDescription)
        }
        return seenResponse
    }

    func queueDictation(currentDictation: String) {
        do {
            _ = try speechSynthesis.dictateFromAPI(text: currentDictation)
        } catch {
            print(error.localizedDescription)
        }
    }

    func updateStatus(status: ConversationStatus) {
        self.status = status
    }

    func displayButtonText() -> String {
        let text = { switch self.status {
        case ConversationStatus.ready: return "RECORD"
        case ConversationStatus.listening: return "STOP"
        case ConversationStatus.transcribing: return "TRANSCRIBING"
        case ConversationStatus.responding: return "RESPONDING"
        }}()
        return text
    }

    func addResponseToQueue(response: String) {
        if lastResponses.count == 10 {
            lastResponses.removeFirst()
        }
        lastResponses.append(response)
    }
}

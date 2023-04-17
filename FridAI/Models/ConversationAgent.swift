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
    @Published var lastResponse: String = ""
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

    func generateResponse() async {
        updateStatus(status: ConversationStatus.transcribing)
        let text = await whisperState!.stopAndProcessRecord()
        var response = ""
        do {
            response = try await openAIConnector.completeChat(text)
        } catch {
            print(error.localizedDescription)
        }
        Logger.shared.addLog(msg: "\(response)\n")
        lastResponse = response
        speechSynthesis.dictate(text: response)
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
}

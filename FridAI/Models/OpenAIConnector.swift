//
//  OpenAIState.swift
//  FridAI
//
//  Created by Sushant Thyagaraj on 4/15/23.
//

import Foundation
import OpenAIStreamingCompletions
import SwiftUI

class OpenAIConnector: NSObject {
    @State private var prompt = ""
    @State private var completion: StreamingCompletion?
    @State private var completedText: String = ""
    private var key = (Bundle.main.infoDictionary?["OpenAI API Key"] as? String)!
    private var api: OpenAIAPI

    enum OpenAIAPIError: Error {
        case KeyNotFound
    }

    override init() {
        api = OpenAIAPI(apiKey: key)
    }

    public func completeChat(_ prompt: String, _ lastResponses: [String], _ model: String = "gpt-3.5-turbo",
                             _ maxTokens: Int = 1500,
                             _ temperature: Double = 0.7) async throws -> String
    {
        if key == "" { throw OpenAIAPIError.KeyNotFound }
        var messages: [OpenAIAPI.Message] = [
            .init(role: .system, content: "You are a helpful assistant. Make the conversation natural. Answer normally."),
        ]

        lastResponses.forEach { response in
            messages.append(.init(role: .assistant, content: response))
        }

        messages.append(.init(role: .user, content: prompt))

        let request = OpenAIAPI.ChatCompletionRequest(messages: messages, model: model, max_tokens: maxTokens, temperature: temperature)
        return try await api.completeChat(request)
    }

    public func completeChatStream(_ prompt: String, _ lastResponses: [String], _ model: String = "gpt-3.5-turbo",
                                   _ maxTokens: Int = 1500,
                                   _ temperature: Double = 0.7) throws -> AsyncStream<OpenAIAPI.Message>
    {
        if key == "" { throw OpenAIAPIError.KeyNotFound }
        var messages: [OpenAIAPI.Message] = [
            .init(role: .system, content: "You are a helpful assistant. Make the conversation natural. Answer normally."),
        ]

        lastResponses.forEach { response in
            messages.append(.init(role: .assistant, content: response))
        }

        messages.append(.init(role: .user, content: prompt))

        let request = OpenAIAPI.ChatCompletionRequest(messages: messages, model: model, max_tokens: maxTokens, temperature: temperature)
        return try api.completeChatStreaming(request)
    }
}

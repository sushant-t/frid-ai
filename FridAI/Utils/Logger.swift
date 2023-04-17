//
//  Logger.swift
//  FridAI
//
//  Created by Sushant Thyagaraj on 4/16/23.
//

import Foundation

class Logger: ObservableObject {
    static let shared = Logger()

    @Published var messageLog = ""
    private init() {}

    func addLog(msg: String) {
        messageLog += msg
    }
}

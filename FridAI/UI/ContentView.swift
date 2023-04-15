//
//  ContentView.swift
//  frid-ai
//
//  Created by Sushant Thyagaraj on 4/13/23.
//

import SwiftUI
import WebKit
#if os(iOS)
import UIKit
#endif

struct GrowingButton: ButtonStyle {
    @State private var animate = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity, alignment: .bottom)
            .background(configuration.isPressed ? Color.white.opacity(0.6) : Color.white.opacity(0.0))
            .border(Color.white.opacity(0.8))
            .foregroundColor(configuration.isPressed ? Color.blue : Color.white)
            .scaleEffect(configuration.isPressed ? 1.02 : 1)
    }
}

#if os(macOS)
struct NSDisplay: NSViewRepresentable {
    typealias NSViewType = WKWebView
    let webView: WKWebView
    
    init() {
        webView = WKWebView(frame: .zero)
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        guard let htmlUrl = Bundle.main.url(forResource: "soundwaves", withExtension: "html", subdirectory: "Data/static") else {
            print("could not read soundwave html file")
            return
        }
        webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
        let request = URLRequest(url: htmlUrl)
        webView.load(request)
        guard let cssPath = Bundle.main.url(forResource: "soundwaves", withExtension: "css", subdirectory: "Data/static") else {
            print("could not read soundwave css file")
            return
        }
        let cssFile: String
        do {
            cssFile = try String(contentsOf: cssPath, encoding: .utf8)
        } catch {
            print("Could not parse soundwave css file")
            return
        }
        let plainData = cssFile.data(using: .utf8)?.base64EncodedString(options: [])
        let cssStyle = """
                    javascript:(function() {
                    var parent = document.getElementsByTagName('head').item(0);
                    var style = document.createElement('style');
                    style.type = 'text/css';
                    style.innerHTML = window.atob('\(plainData!)');
                    parent.appendChild(style)})()
                """
        let cssScript = WKUserScript(source: cssStyle, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(cssScript)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        webView
    }
    func updateNSView(_ uiView: WKWebView, context: Context) {
    }
}
#elseif os(iOS)
struct UIDisplay: UIViewRepresentable {
    typealias UIViewType = WKWebView
    let webView: WKWebView
    
    init() {
        webView = WKWebView(frame: .zero)
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        guard let htmlUrl = Bundle.main.url(forResource: "soundwaves", withExtension: "html", subdirectory: "Data/static") else {
            print("could not read soundwave html file")
            return
        }
        webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
        let request = URLRequest(url: htmlUrl)
        webView.load(request)
        guard let cssPath = Bundle.main.url(forResource: "soundwaves", withExtension: "css", subdirectory: "Data/static") else {
            print("could not read soundwave css file")
            return
        }
        let cssFile: String
        do {
            cssFile = try String(contentsOf: cssPath, encoding: .utf8)
        } catch {
            print("Could not parse soundwave css file")
            return
        }
        let plainData = cssFile.data(using: .utf8)?.base64EncodedString(options: [])
        let cssStyle = """
                    javascript:(function() {
                    var parent = document.getElementsByTagName('head').item(0);
                    var style = document.createElement('style');
                    style.type = 'text/css';
                    style.innerHTML = window.atob('\(plainData!)');
                    parent.appendChild(style)})()
                """
        let cssScript = WKUserScript(source: cssStyle, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(cssScript)
    }
    func makeUIView(context: Context) -> WKWebView {
        webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}
#endif


struct ContentView: View {
    @StateObject var whisperState = WhisperState()
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                ScrollView {
                    Text(verbatim: whisperState.messageLog)
                        .foregroundColor(Color.white)
                    
                } .frame(maxWidth: .infinity,maxHeight: .infinity, alignment: .top )
                if whisperState.isRecording {
                    HStack {
                        Spacer().frame(width:30)
#if os(macOS)
                        NSDisplay().frame(maxWidth: .infinity, maxHeight:.infinity, alignment:.center)
#elseif os(iOS)
                        UIDisplay().frame(maxWidth: .infinity, maxHeight:.infinity, alignment:.center)
                            .transition(.opacity)
#endif
                        Spacer().frame(width:30)
                    }
                }
                Button(action: {
                    Task {
                        await whisperState.toggleRecord()
                    }
                }) {
                    Text(!whisperState.isRecording ? whisperState.canTranscribe ? "RECORD" : "TRANSCRIBING" : "STOP"
                    ).animation(.easeIn(duration: 0.1))
                }
                .buttonStyle(GrowingButton())
                .disabled(!whisperState.canTranscribe)
                Spacer().frame(height: 10)
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }.background(Color.blue)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

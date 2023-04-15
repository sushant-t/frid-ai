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

        func makeNSView(context _: Context) -> WKWebView {
            webView
        }

        func updateNSView(_: WKWebView, context _: Context) {}
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

        func makeUIView(context _: Context) -> WKWebView {
            webView
        }

        func updateUIView(_: WKWebView, context _: Context) {}
        
        func doAnimation() {
            webView.evaluateJavaScript("""
                                       if (document.querySelector('.loader').classList.contains('active')) {
                                             document.querySelectorAll('.line').forEach(el => {el.classList.remove('stroke'); el.classList.add('small')})
                                           setTimeout(()=>{
                                       var el = document.querySelector('.loader').classList
                                       el.remove('active')
                                       el.add('inactive')
                                       },500)
                                            } else {
                                             document.querySelectorAll('.line').forEach(el => {el.classList.remove('small'); el.classList.add('stroke')})
                                             var el = document.querySelector('.loader').classList
                                            el.remove('inactive')
                                            el.add('active')
                                            }
                                       """) { (result, error) in
                if error == nil {
                    print(result)
                }
            }
        }
    }
#endif

struct ContentView: View {
    @StateObject var whisperState = WhisperState()
    #if os(macOS)
    var display: NSDisplay = NSDisplay()
    #elseif os(iOS)
    var display: UIDisplay = UIDisplay()
    #endif
    var body: some View {
        GeometryReader { _ in
            VStack {
                ScrollView {
                    Text(verbatim: whisperState.messageLog)
                        .foregroundColor(Color.white)

                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                HStack {
                    Spacer().frame(width: 30)
                    display.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .transition(.opacity)
                    Spacer().frame(width: 30)
                }

                Button(action: {
                    display.doAnimation()
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

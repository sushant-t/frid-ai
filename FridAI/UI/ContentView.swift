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
            webView.enclosingScrollView?.hasVerticalScroller = false
            webView.enclosingScrollView?.verticalLineScroll = 0.0
            webView.setValue(false, forKey: "drawsBackground")
            guard let htmlUrl = Bundle.main.url(forResource: "webview", withExtension: "html", subdirectory: "Data/static") else {
                print("could not read soundwave html file")
                return
            }
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
            let request = URLRequest(url: htmlUrl)
            webView.load(request)
            guard let cssPath = Bundle.main.url(forResource: "webview", withExtension: "css", subdirectory: "Data/static") else {
                print("could not read webview css file")
                return
            }
            let cssFile: String
            do {
                cssFile = try String(contentsOf: cssPath, encoding: .utf8)
            } catch {
                print("Could not parse webview css file")
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

            guard let jsPath = Bundle.main.url(forResource: "webview", withExtension: "js", subdirectory: "Data/static") else {
                print("could not read webview js file")
                return
            }
            let jsFile: String
            do {
                jsFile = try String(contentsOf: jsPath, encoding: .utf8)
            } catch {
                print("Could not parse webview js file")
                return
            }
            let jsScript = WKUserScript(source: jsFile, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            webView.configuration.userContentController.addUserScript(jsScript)
        }

        func makeNSView(context _: Context) -> WKWebView {
            webView
        }

        func updateNSView(_: WKWebView, context _: Context) {}

        func doSoundwaveAnimation() {
            webView.evaluateJavaScript("window.soundwaveActions();") { _, error in
                if error == nil {}
            }
        }

        func removeLoader() {
            webView.evaluateJavaScript("""
                                    window.hideLoader = true;
                                    window.toggleTranscribeLoader(false);
            """) { _, error in
                if error == nil {}
            }
        }
    }

#elseif os(iOS)
    struct UIDisplay: UIViewRepresentable {
        typealias UIViewType = WKWebView
        let webView: WKWebView

        init() {
            webView = WKWebView(frame: .zero)
            webView.scrollView.isScrollEnabled = false
            webView.isOpaque = false
            webView.backgroundColor = UIColor.clear
            webView.scrollView.backgroundColor = UIColor.clear
            guard let htmlUrl = Bundle.main.url(forResource: "webview", withExtension: "html", subdirectory: "Data/static") else {
                print("could not read soundwave html file")
                return
            }
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
            let request = URLRequest(url: htmlUrl)
            webView.load(request)
            guard let cssPath = Bundle.main.url(forResource: "webview", withExtension: "css", subdirectory: "Data/static") else {
                print("could not read webview css file")
                return
            }
            let cssFile: String
            do {
                cssFile = try String(contentsOf: cssPath, encoding: .utf8)
            } catch {
                print("Could not parse webview css file")
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

            guard let jsPath = Bundle.main.url(forResource: "webview", withExtension: "js", subdirectory: "Data/static") else {
                print("could not read webview js file")
                return
            }
            let jsFile: String
            do {
                jsFile = try String(contentsOf: jsPath, encoding: .utf8)
            } catch {
                print("Could not parse webview js file")
                return
            }
            let jsScript = WKUserScript(source: jsFile, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            webView.configuration.userContentController.addUserScript(jsScript)
        }

        func makeUIView(context _: Context) -> WKWebView {
            webView
        }

        func updateUIView(_: WKWebView, context _: Context) {}

        func doSoundwaveAnimation() {
            webView.evaluateJavaScript("window.soundwaveActions();") { _, error in
                if error == nil {}
            }
        }

        func removeLoader() {
            webView.evaluateJavaScript("""
                                    window.hideLoader = true;
                                    window.toggleTranscribeLoader(false);
            """) { _, error in
                if error == nil {}
            }
        }
    }
#endif

struct ContentView: View {
    @StateObject var agent = ConversationAgent()
    @StateObject var logger = Logger.shared
    #if os(macOS)
        var display: NSDisplay = .init()
    #elseif os(iOS)
        var display: UIDisplay = .init()
    #endif
    var body: some View {
        #if os(macOS)
            let mainScreen = NSScreen.main
            let mainScreenVisibleFrame = mainScreen?.visibleFrame
            let minDim = min(mainScreenVisibleFrame!.height, mainScreenVisibleFrame!.width)
        #elseif os(iOS)
            let mainScreen = UIScreen.main
            let mainScreenVisibleFrame = mainScreen.bounds
            let minDim = min(mainScreenVisibleFrame.height, mainScreenVisibleFrame.width)
        #endif
        GeometryReader { geo in
            HStack { Spacer().frame(width: 0.1 * geo.size.width)
                display
                Spacer().frame(width: 0.1 * geo.size.width)
            }.frame(width: nil, height: 0.6 * geo.size.height)
                .position(x: 0.5 * geo.size.width, y: 0.5 * geo.size.height)
            VStack {
                ScrollView {
                    Text(verbatim: agent.currentResponse)
                        .foregroundColor(Color.white)

                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                Button(action: {
                    display.doSoundwaveAnimation()

                    if agent.status == .ready {
                        Task {
                            await agent.startListening()
                        }
                    } else if agent.status == .listening {
                        Task {
                            await agent.generateResponse(stream: true)
                            display.removeLoader()
                            agent.updateStatus(status: .ready)
                        }
                    }
                }) {
                    Text(agent.displayButtonText()
                    ).animation(.easeIn(duration: 0.1))
                        .padding(.vertical, geo.size.height * 0.01)
                        .frame(maxWidth: .infinity, alignment: .bottom)
                        .contentShape(Rectangle())
                }
                .buttonStyle(GrowingButton())
                .disabled([.transcribing, .responding].contains(agent.status))
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        #if os(iOS)
        .background(RadialGradient(gradient: Gradient(colors: [Color(uiColor: UIColor(red: 173 / 255, green: 216 / 255, blue: 230 / 255, alpha: 1)).opacity(0.8), .blue]), center: .center, startRadius: 0, endRadius: 1000)).frame(minWidth: 0.3 * minDim, minHeight: 0.4 * minDim)
        #elseif os(macOS)
        .background(RadialGradient(gradient: Gradient(colors: [Color(nsColor: NSColor(red: 173 / 255, green: 216 / 255, blue: 230 / 255, alpha: 1)).opacity(0.8), .blue]), center: .center, startRadius: 0, endRadius: 1000)).frame(minWidth: 0.3 * minDim, minHeight: 0.4 * minDim)
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

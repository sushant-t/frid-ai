//
//  SplashView.swift
//  FridAI
//
//  Created by Sushant Thyagaraj on 4/17/23.
//

import SwiftUI

struct SplashView: View {
    @State var isActive: Bool = false

    var body: some View {
        GeometryReader { geo in
            VStack {
                // 2.
                if self.isActive {
                    // 3.
                    ContentView()
                } else {
                    // 4.
                    HStack { Spacer().frame(width: 0.1 * geo.size.width)
                        Text("F.R.I.D.A.I").fontWeight(Font.Weight.heavy)
                            .font(Font.largeTitle).foregroundColor(Color.white.opacity(0.8))
                        Spacer().frame(width: 0.1 * geo.size.width)
                    }.frame(width: nil, height: 0.6 * geo.size.height)
                        .position(x: 0.5 * geo.size.width, y: 0.5 * geo.size.height)
                }
            }

            // 5.
            .onAppear {
                // 6.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    // 7.
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
        #if os(iOS)
        .background(RadialGradient(gradient: Gradient(colors: [Color(uiColor: UIColor(red: 170 / 255, green: 218 / 255, blue: 245 / 255, alpha: 1)).opacity(0.8), .blue]), center: .center, startRadius: 0, endRadius: 1000))
        #elseif os(macOS)
        .background(RadialGradient(gradient: Gradient(colors: [Color(nsColor: NSColor(red: 170 / 255, green: 218 / 255, blue: 245 / 255, alpha: 1)).opacity(0.8), .blue]), center: .center, startRadius: 0, endRadius: 1000))
        #endif
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}

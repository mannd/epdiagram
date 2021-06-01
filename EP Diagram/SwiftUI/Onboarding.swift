//
//  Onboarding.swift
//  EP Diagram
//
//  Created by David Mann on 4/8/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import SwiftUI
import WebKit

struct Onboarding: View {
    @State var text = "<html><body><h1>Hello World</h1></body></html>"
    @Binding var onboardText: String
    var url: URL? = nil

    let step1Text = isRunningOnMac() ? "Click on the ladder to create a mark." : "Single tap ladder to create a mark."
    let step2Text = isRunningOnMac() ? "Click on the mark to toggle the movement anchor point." : "Tap on the mark to toggle the movement anchor point."
    let step3Text = "Drag to move the mark."
    let step4Text = isRunningOnMac() ? "Double-click to delete the mark." : "Double tap to delete the mark."
    let step5Text = "Select EP Diagram Help from the menu and read the Quick Start section."
    let step5EndText = "Click the Done button to begin using EP Diagram."

    var body: some View {
        TabView {
            VStack {
                Text(step1Text)
                    .padding()
                Image(isRunningOnMac() ? "single-tap-1-mac" : "single-tap-1").resizable()
                    .aspectRatio(contentMode: .fit)

            }
            VStack {
                Text(step2Text)
                    .padding()
                Image(isRunningOnMac() ? "single-tap-2-mac" : "single-tap-2").resizable()
                    .aspectRatio(contentMode: .fit)

            }
            VStack {
                Text(step3Text)
                    .padding()
                Image(isRunningOnMac() ? "move-mark-mac" : "move-mark").resizable()
                    .aspectRatio(contentMode: .fit)

            }
            VStack {
                Text(step4Text)
                    .padding()
                Image(isRunningOnMac() ? "double-tap-mac" : "double-tap").resizable()
                    .aspectRatio(contentMode: .fit)
            }
            #if targetEnvironment(macCatalyst)
            VStack {
                Text(step5Text)
                    .padding()
                Image("help-menu").resizable()
                    .aspectRatio(contentMode: .fit)
                Text(step5EndText)
                    .padding()
            }
            #else
            WebView(text: $onboardText, url: url)
            #endif

        }
        .font(.largeTitle)
        .multilineTextAlignment(.center)

        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

struct WebView: UIViewRepresentable {
  @Binding var text: String
    var url: URL?

  func makeUIView(context: Context) -> WKWebView {
    return WKWebView()
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.loadHTMLString(text, baseURL: url?.deletingLastPathComponent())
  }
}

struct Onboarding_Previews: PreviewProvider {
    

    static var previews: some View {
        Onboarding(onboardText: .constant("<html><body><h1>Hello World</h1></body></html>"))
    }
}

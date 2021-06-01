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

    let step1Text = isRunningOnMac() ? "Single tap or click on ladder to create a vertical mark or to attach a cursor to a mark." : "Single tap ladder to create a vertical mark or to attach a cursor to a mark."
    let step2Text = isRunningOnMac() ? "Repeat single taps or clicks on mark or cursor to toggle the anchor point which affects how the mark can move." : "Repeat single taps on mark or cursor to toggle the anchor point which affects how the mark can move."
    let step3Text = "Drag the cursor to move the mark.  You can also drag in a region to create a new mark."
    let step4Text = isRunningOnMac() ? "Double tap or double click to delete a mark.  Double tap or click again to create a new mark." : "Double tap to delete a mark.  Double tap again to create a new mark."

    var body: some View {
        TabView {
            VStack {
                Text(step1Text)
                    .padding()
                Image("single-tap-1").resizable()
                    .aspectRatio(contentMode: .fit)

            }
            VStack {
                Text(step2Text)
                    .padding()
                Image("single-tap-2").resizable()
                    .aspectRatio(contentMode: .fit)

            }
            VStack {
                Text(step3Text)
                    .padding()
                Image("move-mark").resizable()
                    .aspectRatio(contentMode: .fit)

            }
            VStack {
                Text(step4Text)
                    .padding()
                Image("double-tap").resizable()
                    .aspectRatio(contentMode: .fit)
            }
            WebView(text: $onboardText, url: url)
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

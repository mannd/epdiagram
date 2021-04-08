//
//  Onboarding.swift
//  EP Diagram
//
//  Created by David Mann on 4/8/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import SwiftUI

struct Onboarding: View {
    var body: some View {
        TabView {
            VStack {
                Text("Onboarding Page One")
                Image("test-onboard-1")
            }
            VStack {
                Text("Onboarding Page Two")
                Image("test-onboard-2")
            }
            Text("page one")
            Text("page two")
            Text("page three")
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

struct Onboarding_Previews: PreviewProvider {
    static var previews: some View {
        Onboarding()
    }
}

//
//  PreferencesView.swift
//  EP Diagram
//
//  Created by David Mann on 6/24/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    @State var preferences: Preferences
    weak var delegate: ViewControllerDelegate?
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>


    var body: some View {
        NavigationView {
        VStack {
            Stepper(L("Mark line width = \(preferences.lineWidth)"), value: $preferences.lineWidth, in: 1...6, step: 1)
            Toggle(isOn: $preferences.showImpulseOrigin) {
                Text("Show impulse origin")
            }
            Toggle(isOn: $preferences.showBlock) {
                Text("Show block")
            }
            Toggle(isOn: $preferences.showIntervals) {
                Text("Show intervals")
            }
        }.padding()
            .navigationBarTitle("Preferences")
            .navigationBarItems(trailing: Button(action: { self.onSave() }, label: { Text("Save") }))
        }
    }

    func onSave() {
        delegate?.savePreferences(preferences: preferences)
        self.presentationMode.wrappedValue.dismiss()
    }
}

#if DEBUG
struct PreferencesView_Previews: PreviewProvider {
    static let preferences = Preferences()
    static var previews: some View {
        PreferencesView(preferences: preferences)
    }
}
#endif

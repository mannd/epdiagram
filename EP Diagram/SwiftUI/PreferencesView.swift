//
//  PreferencesView.swift
//  EP Diagram
//
//  Created by David Mann on 6/24/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    @State private var lineWidth = UserDefaults.standard.integer(forKey: Preferences.defaultLineWidthKey)
    @State private var showImpulseOrigin = UserDefaults.standard.bool(forKey: Preferences.defaultShowImpulseOriginKey)
    @State private var showBlock = UserDefaults.standard.bool(forKey: Preferences.defaultShowBlockKey)
    @State private var showIntervals = UserDefaults.standard.bool(forKey: Preferences.defaultShowIntervalsKey)
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    weak var delegate: DiagramViewControllerDelegate?

    var body: some View {
        NavigationView {
            VStack{
                Form {
                    Section(header: Text("Mark preferences")) {
                        Stepper(L("Mark line width = \(lineWidth)"), value: $lineWidth, in: 1...6, step: 1)
                        Toggle(isOn: $showImpulseOrigin) {
                            Text("Show impulse origin")
                        }
                        Toggle(isOn: $showBlock) {
                            Text("Show block")
                        }
                        Toggle(isOn: $showIntervals) {
                            Text("Show intervals")
                        }
                    }
                }
                SaveButton(action: self.onSave)
            }
            .navigationBarTitle("Preferences", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .userActivity("org.epstudios.epdiagram.mainActivity", isActive: true, {_ in })
    }

    func onSave() {
        UserDefaults.standard.setValue(lineWidth, forKey: Preferences.defaultLineWidthKey)
        print(lineWidth)
        UserDefaults.standard.setValue(showImpulseOrigin, forKey: Preferences.defaultShowImpulseOriginKey)
        UserDefaults.standard.setValue(showBlock, forKey: Preferences.defaultShowBlockKey)
        print(showBlock)
        UserDefaults.standard.setValue(showIntervals, forKey: Preferences.defaultShowIntervalsKey)
//        NotificationCenter.default.post(name: .preferencesChanged, object: self)
        delegate?.updatePreferences()
        self.presentationMode.wrappedValue.dismiss()
    }
}

#if DEBUG
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
#endif

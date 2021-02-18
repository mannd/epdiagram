//
//  PreferencesView.swift
//  EP Diagram
//
//  Created by David Mann on 6/24/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    @AppStorage(Preferences.defaultLineWidthKey) var lineWidth = UserDefaults.standard.integer(forKey: Preferences.defaultLineWidthKey)
    @AppStorage(Preferences.defaultCursorLineWidthKey) var cursorLineWidth = UserDefaults.standard.integer(forKey: Preferences.defaultCursorLineWidthKey)
    @AppStorage(Preferences.defaultShowImpulseOriginKey) var showImpulseOrigin: Bool = Preferences.showImpulseOrigin
    @AppStorage(Preferences.defaultShowBlockKey) var showBlock: Bool = Preferences.showBlock
    @AppStorage(Preferences.defaultShowIntervalsKey) var showIntervals: Bool = Preferences.showIntervals
    @AppStorage(Preferences.defaultShowConductionTimesKey) var showConductionTimes: Bool = Preferences.showConductionTimes
    @AppStorage(Preferences.defaultSnapMarksKey) var snapMarks: Bool = Preferences.snapMarks
    @AppStorage(Preferences.defaultMarkStyleKey) var markStyle = Preferences.markStyle
    @AppStorage(Preferences.defaultLabelDescriptionVisibilityKey) var labelDescriptionVisibility = Preferences.labelDescriptionVisibility
    @AppStorage(Preferences.defaultPlaySoundsKey) var playSounds = Preferences.playSounds
    @AppStorage(Preferences.defaultHideMarksKey) var hideMarks = Preferences.hideMarks
    @AppStorage(Preferences.defaultCaliperLineWidthKey) var caliperLineWidth = Preferences.caliperLineWidth

// Pass Diagram as binding to allow changing non-UserDefaults settings
    // @Binding var diagram: Diagram
    @ObservedObject var diagramController: DiagramModelController

    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("General")) {
                        Toggle(isOn: $playSounds) {
                            Text("Play sounds")
                        }
                    }
                    Section(header: Text("Ladder")) {
                        Picker(selection: $labelDescriptionVisibility, label: Text("Label description visibility"), content: {
                            Text("Invisible").tag(TextVisibility.invisible.rawValue)
                            Text("Visible").tag(TextVisibility.visibility.rawValue)
                            Text("Visible if fits").tag(TextVisibility.visibleIfFits.rawValue)
                        })
                        Toggle(isOn: $hideMarks) {
                            Text("Hide marks")
                        }
                    }
                    Section(header: Text("Region")) {}
                    Section(header: Text("Mark")) {
                        Stepper("Mark line width = \(lineWidth)", value: $lineWidth, in: 1...6, step: 1)
                        Stepper("Cursor line width = \(cursorLineWidth)", value: $cursorLineWidth, in: 1...6, step: 1)
                        Toggle(isOn: $showImpulseOrigin) {
                            Text("Show impulse origin")
                        }
                        Toggle(isOn: $showBlock) {
                            Text("Show block")
                        }
                        Toggle(isOn: $showIntervals) {
                            Text("Show intervals")
                        }
                        Toggle(isOn: $showConductionTimes) {
                            Text("Show conduction times")
                        }
                        Toggle(isOn: $snapMarks) {
                            Text("Snap marks")
                        }
                        Picker(selection: $markStyle, label: Text("Default style"), content: {
                            Text("Solid").tag(Mark.Style.solid.rawValue)
                            Text("Dashed").tag(Mark.Style.dashed.rawValue)
                            Text("Dotted").tag(Mark.Style.dotted.rawValue)
                        })
                    }
                    Section(header: Text("Caliper")) {
                        Stepper("Caliper line width = \(caliperLineWidth)", value: $caliperLineWidth, in: 1...6, step: 1)
                    }
                }
            }
            .navigationBarTitle("Preferences", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#if DEBUG
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(diagramController: DiagramModelController(diagram: Diagram.defaultDiagram()))
    }
}
#endif

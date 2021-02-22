//
//  PreferencesView.swift
//  EP Diagram
//
//  Created by David Mann on 6/24/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    @AppStorage(Preferences.defaultLineWidthKey) var markLineWidth = Preferences.markLineWidth
    @AppStorage(Preferences.defaultCursorLineWidthKey) var cursorLineWidth = Preferences.cursorLineWidth
    @AppStorage(Preferences.defaultNormalColorNameKey) var normalColorName = Preferences.normalColorName
    @AppStorage(Preferences.defaultCursorColorNameKey) var cursorColorName = Preferences.cursorColorName
    @AppStorage(Preferences.defaultAttachedColorNameKey) var attachedColorName = Preferences.attachedColorName
    @AppStorage(Preferences.defaultConnectedColorNameKey) var connectedColorName = Preferences.connectedColorName
    @AppStorage(Preferences.defaultSelectedColorNameKey) var selectedColorName = Preferences.selectedColorName
    @AppStorage(Preferences.defaultLinkedColorNameKey) var linkedColorName = Preferences.linkedColorName
    @AppStorage(Preferences.defaultActiveColorNameKey) var activeColorName = Preferences.activeColorName
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
    @AppStorage(Preferences.defaultCaliperColorNameKey) var caliperColorName = Preferences.caliperColorName

    // Pass Diagram as binding to allow changing non-UserDefaults settings
    // @Binding var diagram: Diagram
    @ObservedObject var diagramController: DiagramModelController

    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    // Note: At most 10 views in a Section.  Wrap views in Group{} if more than 10 views.  See https://stackoverflow.com/questions/61178868/swiftui-random-extra-argument-in-call-error.
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

                            Text("Visible").tag(TextVisibility.visibility.rawValue)
                            Text("Visible if fits").tag(TextVisibility.visibleIfFits.rawValue)
                            Text("Invisible").tag(TextVisibility.invisible.rawValue)
                        })
                        Toggle(isOn: $hideMarks) {
                            Text("Hide marks")
                        }
                        Toggle(isOn: $showIntervals) {
                            Text("Show intervals")
                        }
                        Toggle(isOn: $showConductionTimes) {
                            Text("Show conduction times")
                        }
                    }
                    Section(header: Text("Region")) {
                        ColorPicker(binding: $activeColorName, title: "Active region color")
                    }
                    Section(header: Text("Mark")) {
                        Group {
                            Stepper("Mark width = \(markLineWidth)", value: $markLineWidth, in: 1...6, step: 1)
                            ColorPicker(binding: $normalColorName, title: "Default mark color")
                            ColorPicker(binding: $attachedColorName, title: "Highlighted mark color")
                            ColorPicker(binding: $connectedColorName, title: "Connected mark color")
                            ColorPicker(binding: $selectedColorName, title: "Selected mark color")
                            ColorPicker(binding: $linkedColorName, title: "Linked mark color")
                            Toggle(isOn: $showImpulseOrigin) {
                                Text("Show impulse origin")
                            }
                            Toggle(isOn: $showBlock) {
                                Text("Show block")
                            }
                            Toggle(isOn: $snapMarks) {
                                Text("Snap marks")
                            }
                            Picker(selection: $markStyle, label: Text("Default mark style"), content: {
                                Text("Solid").tag(Mark.Style.solid.rawValue)
                                Text("Dashed").tag(Mark.Style.dashed.rawValue)
                                Text("Dotted").tag(Mark.Style.dotted.rawValue)
                            })
                        }
                    }
                    Section(header: Text("Cursor")) {
                        Stepper("Cursor width = \(cursorLineWidth)", value: $cursorLineWidth, in: 1...6, step: 1)
                        ColorPicker(binding: $cursorColorName, title: "Cursor color")
                    }
                    Section(header: Text("Caliper")) {
                        Stepper("Caliper width = \(caliperLineWidth)", value: $caliperLineWidth, in: 1...6, step: 1)
                        ColorPicker(binding: $caliperColorName, title: "Caliper color")
                    }

                }
            }
            .navigationBarTitle("Preferences", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


struct ColorPicker: View {
    @Binding var binding: Int
    var title: String
    var body: some View {
        Picker(selection: $binding, label: Text(title), content: {
            Text("Blue").tag(ColorName.blue.rawValue).foregroundColor(.blue)
            Text("Red").tag(ColorName.red.rawValue).foregroundColor(.red)
            Text("Green").tag(ColorName.green.rawValue).foregroundColor(.green)
            Text("Yellow").tag(ColorName.yellow.rawValue).foregroundColor(.yellow)
            Text("Purple").tag(ColorName.purple.rawValue).foregroundColor(.purple)
            Text("Orange").tag(ColorName.orange.rawValue).foregroundColor(.orange)
            Text("Pink").tag(ColorName.pink.rawValue).foregroundColor(.pink)
            Text("Default").tag(ColorName.normal.rawValue)
        })
    }
}

#if DEBUG
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PreferencesView(diagramController: DiagramModelController(diagram: Diagram.defaultDiagram()))
            PreferencesView(diagramController: DiagramModelController(diagram: Diagram.defaultDiagram()))
                .preferredColorScheme(.dark)
        }
    }
}
#endif


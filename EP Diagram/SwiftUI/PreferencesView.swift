//
//  PreferencesView.swift
//  EP Diagram
//
//  Created by David Mann on 6/24/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    @AppStorage(Preferences.lineWidthKey) var markLineWidth = Preferences.markLineWidth
    @AppStorage(Preferences.cursorLineWidthKey) var cursorLineWidth = Preferences.cursorLineWidth
    @AppStorage(Preferences.showImpulseOriginKey) var showImpulseOrigin: Bool = Preferences.showImpulseOrigin
    @AppStorage(Preferences.showBlockKey) var showBlock: Bool = Preferences.showBlock
    @AppStorage(Preferences.showIntervalsKey) var showIntervals: Bool = Preferences.showIntervals
    @AppStorage(Preferences.showArrowsKey) var showArrows: Bool = Preferences.showArrows
    @AppStorage(Preferences.showConductionTimesKey) var showConductionTimes: Bool = Preferences.showConductionTimes
    @AppStorage(Preferences.snapMarksKey) var snapMarks: Bool = Preferences.snapMarks
    @AppStorage(Preferences.markStyleKey) var markStyle = Preferences.markStyle
    @AppStorage(Preferences.labelDescriptionVisibilityKey) var labelDescriptionVisibility = Preferences.labelDescriptionVisibility
    @AppStorage(Preferences.playSoundsKey) var playSounds = Preferences.playSounds
    @AppStorage(Preferences.hideMarksKey) var hideMarks = Preferences.hideMarks
    @AppStorage(Preferences.caliperLineWidthKey) var caliperLineWidth = Preferences.caliperLineWidth
    @AppStorage(Preferences.doubleLineBlockMarkerKey) var doubleLineBlockerMarker = Preferences.doubleLineBlockMarker
    @AppStorage(Preferences.showMarkersKey) var showMarkers = Preferences.showMarkers
    @AppStorage(Preferences.hideZeroCTKey) var hideZeroCT = Preferences.hideZeroCT
    @AppStorage(Preferences.markerLineWidthKey) var markerLineWidth = Preferences.markerLineWidth

    // Color preferences
    @AppStorage(Preferences.activeColorNameKey) var activeColorName = Preferences.activeColorName
    @State var activeColor: Color = Color(Preferences.defaultActiveColor)
    @AppStorage(Preferences.linkedColorNameKey) var linkedColorName = Preferences.linkedColorName
    @State var linkedColor: Color = Color(Preferences.defaultLinkedColor)
    @AppStorage(Preferences.selectedColorNameKey) var selectedColorName = Preferences.linkedColorName
    @State var selectedColor: Color = Color(Preferences.defaultSelectedColor)
    @AppStorage(Preferences.connectedColorNameKey) var connectedColorName = Preferences.connectedColorName
    @State var connectedColor: Color = Color(Preferences.defaultConnectedColor)
    @AppStorage(Preferences.attachedColorNameKey) var attachedColorName = Preferences.attachedColorName
    @State var attachedColor: Color = Color(Preferences.defaultAttachedColor)
    @AppStorage(Preferences.cursorColorNameKey) var cursorColorName = Preferences.cursorColorName
    @State var cursorColor: Color = Color(Preferences.defaultCursorColor)
    @AppStorage(Preferences.caliperColorNameKey) var caliperColorName = Preferences.caliperColorName
    @State var caliperColor: Color = Color(Preferences.defaultCaliperColor)
    @AppStorage(Preferences.markerColorNameKey) var markerColorName = Preferences.markerColorName
    @State var markerColor: Color = Color(Preferences.defaultMarkerColor)

    @State var showAutoLinkWarning = false

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
                            Text("Hide all marks")
                        }
                        Toggle(isOn: $showIntervals) {
                            Text("Show intervals (after calibration)")
                        }
                        Toggle(isOn: $showConductionTimes) {
                            Text("Show conduction times (after calibration)")
                        }
                        Toggle(isOn: $hideZeroCT) {
                            Text("Hide conduction times if zero")
                        }
                        Toggle(isOn: $showMarkers) {
                            Text("Show markers")
                        }
                        Stepper("Marker width = \(markerLineWidth)", value: $markerLineWidth, in: 1...6, step: 1)
                        ColorPicker("Marker color", selection: Binding(
                                        get: { markerColor },
                                        set: { newValue in
                                            markerColorName = newValue.toString
                                            markerColor = newValue
                                        }))
                    }
                    Section(header: Text("Region")) {
                        ColorPicker("Active region color", selection: Binding(
                                        get: { activeColor },
                                        set: { newValue in
                                            activeColorName = newValue.toString
                                            activeColor = newValue
                                        }))

                    }
                    Section(header: Text("Mark")) {
                        Group {
                            Stepper("Mark width = \(markLineWidth)", value: $markLineWidth, in: 1...6, step: 1)
                            ColorPicker("Highlighted color", selection: Binding(
                                            get: { attachedColor },
                                            set: { newValue in
                                                attachedColorName = newValue.toString
                                                attachedColor = newValue
                                            }))
                            ColorPicker("Connected color", selection: Binding(
                                            get: { connectedColor },
                                            set: { newValue in
                                                connectedColorName = newValue.toString
                                                connectedColor = newValue
                                            }))
                            ColorPicker("Selected color", selection: Binding(
                                            get: { selectedColor },
                                            set: { newValue in
                                                selectedColorName = newValue.toString
                                                selectedColor = newValue
                                            }))
                            ColorPicker("Linked color", selection: Binding(
                                            get: { linkedColor },
                                            set: { newValue in
                                                linkedColorName = newValue.toString
                                                linkedColor = newValue
                                            }))
                            Toggle(isOn: $showImpulseOrigin) {
                                Text("Show impulse origin")
                            }
                            Toggle(isOn: $showBlock) {
                                Text("Show block")
                            }
                            Toggle(isOn: $doubleLineBlockerMarker) {
                                Text("Double line block marker")
                            }
                            Toggle(isOn: $showArrows) {
                                Text("Show direction of conduction")
                            }
                            // Only 10 items in each group allowed.
                            Group {
                                Toggle(isOn: $snapMarks) {
                                    Text("Auto-link marks")
                                }
                                .onChange(of: snapMarks, perform: { value in
                                    showAutoLinkWarning = !value
                                })
                                .alert(isPresented: $showAutoLinkWarning) {
                                    Alert(title: Text("Warning: No Auto-Linking"), message: Text("Auto-linking is used to link marks together and to automatically determine block and impulse origin.  If you turn it off, you will need to manually align marks and annotate block and impulse origin."))
                                }
                                Picker(selection: $markStyle, label: Text("Default mark style"), content: {
                                    Text("Solid").tag(Mark.Style.solid.rawValue)
                                    Text("Dashed").tag(Mark.Style.dashed.rawValue)
                                    Text("Dotted").tag(Mark.Style.dotted.rawValue)
                                })
                            }
                        }
                    }
                    Section(header: Text("Cursor")) {
                        Stepper("Cursor width = \(cursorLineWidth)", value: $cursorLineWidth, in: 1...6, step: 1)
                        ColorPicker("Cursor color", selection: Binding(
                                        get: { cursorColor },
                                        set: { newValue in
                                            cursorColorName = newValue.toString
                                            cursorColor = newValue
                                        }))
                    }
                    Section(header: Text("Caliper")) {
                        Stepper("Caliper width = \(caliperLineWidth)", value: $caliperLineWidth, in: 1...6, step: 1)
                        ColorPicker("Caliper color", selection: Binding(
                                        get: { caliperColor },
                                        set: { newValue in
                                            caliperColorName = newValue.toString
                                            caliperColor = newValue
                                        }))
                    }

                }.onAppear {
                    activeColor = Color.convertColorName(activeColorName) ?? activeColor
                    linkedColor = Color.convertColorName(linkedColorName) ?? linkedColor
                    selectedColor = Color.convertColorName(selectedColorName) ?? selectedColor
                    connectedColor = Color.convertColorName(connectedColorName) ?? connectedColor
                    attachedColor = Color.convertColorName(attachedColorName) ?? attachedColor
                    cursorColor = Color.convertColorName(cursorColorName) ?? cursorColor
                    caliperColor = Color.convertColorName(caliperColorName) ?? caliperColor
                    markerColor = Color.convertColorName(markerColorName) ?? markerColor
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
        Group {
            PreferencesView(diagramController: DiagramModelController(diagram: Diagram.defaultDiagram()))
            PreferencesView(diagramController: DiagramModelController(diagram: Diagram.defaultDiagram()))
                .preferredColorScheme(.dark)
        }
    }
}
#endif


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
    @AppStorage(Preferences.impulseOriginContiguousKey) var impulseOriginContiguous: Bool = Preferences.impulseOriginContiguous
    @AppStorage(Preferences.impulseOriginLargeKey) var impulseOriginLarge: Bool = Preferences.impulseOriginLarge
    @AppStorage(Preferences.showArrowsKey) var showArrows: Bool = Preferences.showArrows
    @AppStorage(Preferences.showConductionTimesKey) var showConductionTimes: Bool = Preferences.showConductionTimes
    @AppStorage(Preferences.showMarkLabelsKey) var showMarkLabels: Bool = Preferences.showMarkLabels
    @AppStorage(Preferences.snapMarksKey) var snapMarks: Bool = Preferences.snapMarks
    @AppStorage(Preferences.markStyleKey) var markStyle = Preferences.markStyle
    @AppStorage(Preferences.labelDescriptionVisibilityKey) var labelDescriptionVisibility = Preferences.labelDescriptionVisibility
    @AppStorage(Preferences.playSoundsKey) var playSounds = Preferences.playSounds
    @AppStorage(Preferences.hideMarksKey) var hideMarks = Preferences.hideMarks
    @AppStorage(Preferences.caliperLineWidthKey) var caliperLineWidth = Preferences.caliperLineWidth
    @AppStorage(Preferences.doubleLineBlockMarkerKey) var doubleLineBlockerMarker = Preferences.doubleLineBlockMarker
    @AppStorage(Preferences.rightAngleBlockMarkerKey) var rightAngleBlockMarker = Preferences.rightAngleBlockMarker
    @AppStorage(Preferences.showMarkersKey) var showMarkers = Preferences.showMarkers
    @AppStorage(Preferences.hideZeroCTKey) var hideZeroCT = Preferences.hideZeroCT
    @AppStorage(Preferences.markerLineWidthKey) var markerLineWidth = Preferences.markerLineWidth
    @AppStorage(Preferences.showPeriodsKey) var showPeriods = Preferences.showPeriods
    @AppStorage(Preferences.periodPositionKey) var periodPosition = Preferences.periodPosition
    @AppStorage(Preferences.periodTransparencyKey) var periodTransparency = Preferences.periodTransparency
    @AppStorage(Preferences.periodTextJustificationKey) var periodTextJustification = Preferences.periodTextJustification
    @AppStorage(Preferences.periodsOverlapMarksKey) var periodOverlapMark = Preferences.periodsOverlapMarks
    @AppStorage(Preferences.periodSizeKey) var periodSize = Preferences.periodSize
    @AppStorage(Preferences.periodShowBorderKey) var periodShowBorder = Preferences.periodShowBorder
    @AppStorage(Preferences.periodResetMethodKey) var periodResetMethod = Preferences.periodResetMethod
    @AppStorage(Preferences.intervalGroupingKey) var intervalGrouping = Preferences.intervalGrouping

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
    @AppStorage(Preferences.periodColorNameKey) var periodColorName = Preferences.periodColorName
    @State var periodColor: Color = Color(Preferences.defaultPeriodColor)

    @State var showAutoLinkWarning = false

    @ObservedObject var diagramController: DiagramModelController
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>


    fileprivate func getColorPicker(title: LocalizedStringKey, selection: Binding<Color>) -> some View {
        return Color.getColorPicker(title: title, selection: selection)
    }

    // Note: At most 10 views in a Section.  Wrap views in Group{} if more than 10 views.  See https://stackoverflow.com/questions/61178868/swiftui-random-extra-argument-in-call-error.
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    #if !targetEnvironment(macCatalyst)
                    Section(header: Text("General")) {
                        Toggle(isOn: $playSounds) {
                            Text("Play sounds")
                        }
                    }
                    #endif
                    Section(header: Text("Ladder")) {
                        // Grouped to avoid section with > 10 items.
                        Group {
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
                        Picker(selection: $intervalGrouping, label: Text("Interval grouping"), content: {
                            Text("Full interior").tag(IntervalGrouping.fullInterior.rawValue)
                            Text("Full exterior").tag(IntervalGrouping.fullExterior.rawValue)
                            Text("Partial above").tag(IntervalGrouping.partialAbove.rawValue)
                            Text("Partial below").tag(IntervalGrouping.partialBelow.rawValue)
                        })
                        }
                        Toggle(isOn: $showConductionTimes) {
                            Text("Show conduction times (after calibration)")
                        }
                        Toggle(isOn: $hideZeroCT) {
                            Text("Hide conduction times if zero")
                        }
                        Toggle(isOn: $showMarkLabels) {
                            Text("Show mark labels")
                        }
                        Toggle(isOn: $showMarkers) {
                            Text("Show markers")
                        }
                        Stepper("Marker width = \(markerLineWidth)", value: $markerLineWidth, in: 1...6, step: 1)
                        getColorPicker(title: "Marker color", selection: Binding(
                                        get: { markerColor },
                                        set: { newValue in
                                            markerColorName = newValue.toString
                                            markerColor = newValue
                                        }))
                    }
                    Section(header: Text("Region")) {
                        getColorPicker(title: "Active region color", selection: Binding(
                                        get: { activeColor },
                                        set: { newValue in
                                            activeColorName = newValue.toString
                                            activeColor = newValue
                                        }))

                    }
                    Section(header: Text("Mark")) {
                        Group {
                            Stepper("Mark width = \(markLineWidth)", value: $markLineWidth, in: 1...6, step: 1)
                            getColorPicker(title: "Highlighted color", selection: Binding(
                                            get: { attachedColor },
                                            set: { newValue in
                                                attachedColorName = newValue.toString
                                                attachedColor = newValue
                                            }))
                            getColorPicker(title: "Connected color", selection: Binding(
                                            get: { connectedColor },
                                            set: { newValue in
                                                connectedColorName = newValue.toString
                                                connectedColor = newValue
                                            }))
                            getColorPicker(title: "Selected color", selection: Binding(
                                            get: { selectedColor },
                                            set: { newValue in
                                                selectedColorName = newValue.toString
                                                selectedColor = newValue
                                            }))
                            getColorPicker(title: "Linked color", selection: Binding(
                                            get: { linkedColor },
                                            set: { newValue in
                                                linkedColorName = newValue.toString
                                                linkedColor = newValue
                                            }))
                            Toggle(isOn: $showImpulseOrigin) {
                                Text("Show impulse origin")
                            }
                            Toggle(isOn: $impulseOriginContiguous) {
                                Text("Impulse origin contiguous with mark")
                            }
                            Toggle(isOn: $impulseOriginLarge) {
                                Text("Large impulse origin symbol")
                            }
                            Toggle(isOn: $showBlock) {
                                Text("Show block")
                            }
                            // Only 10 items in each group allowed.
                            Group {
                                Toggle(isOn: $doubleLineBlockerMarker) {
                                    Text("Double line block marker")
                                }
                                Toggle(isOn: $rightAngleBlockMarker) {
                                    Text("Right angle block marker")
                                }
                                Toggle(isOn: $showArrows) {
                                    Text("Show direction of conduction arrows")
                                }

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
                    Section(header: Text("Period")) {
                        Toggle(isOn: $showPeriods) {
                            Text("Show periods")
                        }
                        Picker(selection: $periodPosition, label: Text("Position of periods in region"), content: {
                            Text("Top").tag(PeriodPosition.top.rawValue)
                            Text("Bottom").tag(PeriodPosition.bottom.rawValue)
                        })
                        Picker(selection: $periodTextJustification, label: Text("Period text justification"), content: {
                            Text("Left").tag(TextJustification.left.rawValue)
                            Text("Center").tag(TextJustification.center.rawValue)
                        })
                        Toggle(isOn: $periodOverlapMark) {
                            Text("Periods overlap marks")
                        }
                        getColorPicker(title: "Default period color", selection: Binding(
                            get: { periodColor },
                                        set: { newValue in
                                            periodColorName = newValue.toString
                                            periodColor = newValue
                                        }))
                        HStack {
                            Text("Period transparency")
                            Slider(value: $periodTransparency, in: 0.2...1.0)
                        }
                        Picker(selection: $periodSize, label: Text("Period size"), content: {
                            Text("Large").tag(PeriodSize.large.rawValue)
                            Text("Small").tag(PeriodSize.small.rawValue)
                        })
                        Toggle(isOn: $periodShowBorder) {
                            Text("Show period border")
                        }
                        Picker(selection: $periodResetMethod, label: Text("Reset method"), content: {
                            Text("Clip").tag(PeriodResetMethod.clip.rawValue)
                            Text("Interrupt").tag(PeriodResetMethod.interrupt.rawValue)
                        })
                    }
                    Section(header: Text("Cursor")) {
                        Stepper("Cursor width = \(cursorLineWidth)", value: $cursorLineWidth, in: 1...6, step: 1)
                        getColorPicker(title: "Cursor color", selection: Binding(
                                        get: { cursorColor },
                                        set: { newValue in
                                            cursorColorName = newValue.toString
                                            cursorColor = newValue
                                        }))
                    }
                    Section(header: Text("Caliper")) {
                        Stepper("Caliper width = \(caliperLineWidth)", value: $caliperLineWidth, in: 1...6, step: 1)
                        getColorPicker(title: "Caliper color", selection: Binding(
                                        get: { caliperColor },
                                        set: { newValue in
                                            caliperColorName = newValue.toString
                                            caliperColor = newValue
                                        }))
                    }

                }
                .onAppear {
                    activeColor = Color.convertColorName(activeColorName) ?? activeColor
                    linkedColor = Color.convertColorName(linkedColorName) ?? linkedColor
                    selectedColor = Color.convertColorName(selectedColorName) ?? selectedColor
                    connectedColor = Color.convertColorName(connectedColorName) ?? connectedColor
                    attachedColor = Color.convertColorName(attachedColorName) ?? attachedColor
                    cursorColor = Color.convertColorName(cursorColorName) ?? cursorColor
                    caliperColor = Color.convertColorName(caliperColorName) ?? caliperColor
                    markerColor = Color.convertColorName(markerColorName) ?? markerColor
                    periodColor = Color.convertColorName(periodColorName) ?? periodColor
               }
            }
            .navigationBarTitle("Preferences", displayMode: .inline)
            .navigationBarHidden(isRunningOnMac() ? true : false)

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


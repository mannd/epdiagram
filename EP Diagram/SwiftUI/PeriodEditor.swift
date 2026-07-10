//
//  PeriodEditor.swift
//  EP Diagram
//
//  Created by David Mann on 3/1/22.
//  Copyright © 2022 EP Studios. All rights reserved.
//

import SwiftUI

fileprivate func getColorPicker(title: LocalizedStringKey, selection: Binding<Color>) -> some View {
    return Color.getColorPicker(title: title, selection: selection)
}

var periodColorName = Preferences.periodColorName

struct PeriodEditor: View {
    @ObservedObject var periodsModelController: PeriodsModelController
    var dismissAction: (([Period], Bool) -> Void)?
    @Binding var period: Period
    @State var resettable = false
    @State var periodColor: Color = Color(Preferences.defaultPeriodColor)
    @State private var durationText = ""

    private static let durationRange: ClosedRange<CGFloat> = 10...2000

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField(period.name, text: $period.name)
                }
                Section(header: Text("Duration (msec)")) {
                    HStack {
                        TextField("Value in msec", text: $durationText, onEditingChanged: { isEditing in
                            if !isEditing {
                                commitDurationText()
                            }
                        }, onCommit: {
                            commitDurationText()
                        })
                        .keyboardType(.numberPad)

                        Stepper("", value: Binding(
                            get: { period.duration },
                            set: { newValue in
                                stepDuration(to: newValue)
                            }), in: Self.durationRange, step: 1)
                        .labelsHidden()
                    }
                }
                Section(header: Text("Color")) {
                    getColorPicker(title: "Color", selection: Binding(
                        get: { Color(period.color) },
                        set: { newValue in
                            periodColorName = newValue.toString
                            period.color = UIColor(newValue)
                        }))
                }
                Section(header: Text("Resettable")) {
                    Toggle(isOn: $period.resettable) {
                        Text("Resettable")
                    }
                }
                Section(header: Text("Offset")) {
                        Stepper(value: $period.offset, in: 0...3, step: 1) {
                            HStack {
                                Text("\(period.offset) height units")
                            }
                        }
                }
            }
            .onAppear {
                periodColor = Color.convertColorName(periodColorName) ?? periodColor
                updateDurationText()
            }
            .onDisappear() {
                commitDurationText()
                if let dismissAction = dismissAction {
                    dismissAction(periodsModelController.periods, false)
                }
            }
            .navigationBarTitle(Text("Edit Period"), displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func commitDurationText() {
        guard let typedDuration = parsedDurationText() else {
            updateDurationText()
            return
        }

        period.duration = typedDuration
        updateDurationText()
    }

    private func stepDuration(to newValue: CGFloat) {
        let step = newValue - period.duration
        let baseDuration = parsedDurationText() ?? period.duration
        let steppedDuration = min(max(baseDuration + step, Self.durationRange.lowerBound), Self.durationRange.upperBound)
        period.duration = steppedDuration.rounded()
        updateDurationText()
    }

    private func parsedDurationText() -> CGFloat? {
        let trimmedText = durationText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmedText) else {
            return nil
        }

        let clampedDuration = min(max(CGFloat(value), Self.durationRange.lowerBound), Self.durationRange.upperBound)
        return clampedDuration.rounded()
    }

    private func updateDurationText() {
        durationText = "\(Int(period.duration.rounded()))"
    }
}

struct PeriodEditor_Previews: PreviewProvider {
    static var previews: some View {
        PeriodEditor(periodsModelController: PeriodsModelController(periods: []), period: .constant(Period(name: "LRI", duration: 200, color: .green, resettable: true)))
    }
}

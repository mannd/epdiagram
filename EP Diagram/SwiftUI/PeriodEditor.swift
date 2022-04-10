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

    static var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimum = 10
        formatter.maximum = 2000
        return formatter
    }()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField(period.name, text: $period.name)
                }
                Section(header: Text("Duration (msec)")) {
                    HStack {
                        TextField("Value", value: $period.duration, formatter: Self.numberFormatter)
                            .keyboardType(.numberPad)
                        Stepper("", value: $period.duration, in: 10...2000, step: 1).labelsHidden()
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
            }
            .onDisappear() {
                if let dismissAction = dismissAction {
                    dismissAction(periodsModelController.periods, false)
                }
            }
            .navigationBarTitle(Text("Edit Period"), displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct PeriodEditor_Previews: PreviewProvider {
    static var previews: some View {
        PeriodEditor(periodsModelController: PeriodsModelController(periods: []), period: .constant(Period(name: "LRI", duration: 200, color: .green, resettable: true)))
    }
}

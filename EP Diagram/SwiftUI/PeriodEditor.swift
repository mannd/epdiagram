//
//  PeriodEditor.swift
//  EP Diagram
//
//  Created by David Mann on 3/1/22.
//  Copyright © 2022 EP Studios. All rights reserved.
//

import SwiftUI

fileprivate func getColorPicker(title: LocalizedStringKey, selection: Binding<Color>) -> some View {
#if targetEnvironment(macCatalyst)
    return HStack {
        Text(title)
        Spacer()
        ColorPicker("", selection: selection).frame(maxWidth: 100)
    }
#else
    return ColorPicker(title, selection: selection)
#endif
}

var periodColorName = Preferences.periodColorName

struct PeriodEditor: View {
    @State var period = Period(name: "Test", duration: 500, color: .blue)
    @State var resettable = false
    @State var periodColor: Color = Color(Preferences.defaultPeriodColor)

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField(period.name, text: $period.name)
                }
                Section(header: Text("Duration")) {
                    Text("Duration = \(lround(Double( period.duration))) msec")
                    Slider(value: $period.duration, in: 10...500)
                }
                Section(header: Text("Color")) {
                    getColorPicker(title: "Color", selection: Binding(
                        get: { periodColor },
                        set: { newValue in
                            periodColorName = newValue.toString
                            periodColor = newValue
                        }))
                }
                Section(header: Text("Resettable")) {
                    Toggle(isOn: $resettable) {
                        Text("Resettable")
                    }
                }
            }
            .onAppear {
                periodColor = Color.convertColorName(periodColorName) ?? periodColor
            }
            .navigationBarTitle(Text("Edit Period"), displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct PeriodEditor_Previews: PreviewProvider {
    static var previews: some View {
        PeriodEditor(period: Period(name: "LRI", duration: 200, color: .green, resettable: true))
    }
}

//
//  RhythmView.swift
//  EP Diagram
//
//  Created by David Mann on 3/5/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import SwiftUI

enum RhythmType: Int, CustomStringConvertible, Identifiable, CaseIterable {
    case regular
    case fibrillation

    var id: RhythmType { return self }

    var description: String {
        switch self {
        case .regular:
            return "Regular"
        case .fibrillation:
            return "Fibrillation"
        }
    }
}

struct RhythmView: View {
    var dismissAction: ((Double) -> Void)?

    @State var cl: Double = 600
    @State var minCL: Double = 100
    @State var maxCL: Double = 150
    @State var rhythmType: RhythmType = .regular
    @State var randomizeCycleLength: Bool = true
    @State var randomizeOrigin: Bool = false
    @State var randomizeConductionTime: Bool = false
    @State var deletePrexistingMarks: Bool = true

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rhythm type")) {
                    Picker(selection: $rhythmType, label: Text("")) {
                        ForEach(RhythmType.allCases) { rhythm in
                            Text(rhythm.description)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section(header: Text("Mean Cycle Length")) {
                    Text("Mean cycle length = \(lround(cl))")
                    Slider(value: $cl, in: 50...2000)
                }
                Section(header: Text("Fibrillation Parameters")) {
                    Toggle(isOn: $randomizeCycleLength) {
                        Text("Randomize cycle length")
                    }
                    Text("Minimum cycle length = \(lround(minCL))")
                    Slider(value: $minCL, in: 10...(maxCL - 10)).disabled(randomizeCycleLength == false)
                    Text("Maximum cycle length = \(lround(maxCL))")
                    Slider(value: $maxCL, in: (minCL + 10)...200).disabled(randomizeCycleLength == false)
                    Toggle(isOn: $randomizeOrigin) {
                        Text("Randomize origin")
                    }
                    Toggle(isOn: $randomizeConductionTime) {
                        Text("Randomize conduction time")
                    }
                }
                .disabled(rhythmType == .regular)
                Section(header: Text("Delete preexisting marks?")) {
                    Toggle(isOn: $deletePrexistingMarks) {
                        Text("Delete marks in selected area first?")
                    }
                }
            }.navigationBarTitle("Rhythm Details", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                self.applyRhythm()

            }, label: {
                Text("Apply")
            }))
        }.navigationViewStyle(StackNavigationViewStyle())

    }

    func applyRhythm() {
        print("apply rhythm")
        if let dismissAction = dismissAction {
            dismissAction(cl)
        }
    }
}



struct RhythmView_Previews: PreviewProvider {
    static var previews: some View {
        RhythmView()
    }
}

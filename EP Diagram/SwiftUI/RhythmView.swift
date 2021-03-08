//
//  RhythmView.swift
//  EP Diagram
//
//  Created by David Mann on 3/5/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import SwiftUI

struct RhythmView: View {
    var dismissAction: ((Rhythm) -> Void)?

    @State var rhythm: Rhythm = Rhythm(meanCL: 600, rhythmType: .regular, minCL: 100, maxCL: 150, randomizeCL: true, randomizeImpulseOrigin: false, randomizeConductionTime: false, replaceExistingMarks: true)

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rhythm type")) {
                    Picker(selection: $rhythm.rhythmType, label: Text("")) {
                        ForEach(RhythmType.allCases) { rhythm in
                            Text(rhythm.description)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section(header: Text("Mean Cycle Length")) {
                    Text("Mean cycle length = \(lround(Double(rhythm.meanCL)))")
                    Slider(value: $rhythm.meanCL, in: 50...2000)
                }
                Section(header: Text("Fibrillation Parameters")) {
                    Toggle(isOn: $rhythm.randomizeCL) {
                        Text("Randomize cycle length")
                    }
                    Text("Minimum cycle length = \(lround(Double(rhythm.minCL)))")
                    Slider(value: $rhythm.minCL, in: 10...(rhythm.maxCL - 10)).disabled(rhythm.randomizeCL == false)
                    Text("Maximum cycle length = \(lround(Double(rhythm.maxCL)))")
                    Slider(value: $rhythm.maxCL, in: (rhythm.minCL + 10)...200).disabled(rhythm.randomizeCL == false)
                    Toggle(isOn: $rhythm.randomizeImpulseOrigin) {
                        Text("Randomize impulse origin")
                    }
                    Toggle(isOn: $rhythm.randomizeConductionTime) {
                        Text("Randomize conduction time")
                    }
                }
                .disabled(rhythm.rhythmType == .regular)
                Section(header: Text("Delete preexisting marks?")) {
                    Toggle(isOn: $rhythm.replaceExistingMarks) {
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
        if let dismissAction = dismissAction {
            dismissAction(rhythm)
        }
    }
}

struct RhythmView_Previews: PreviewProvider {
    static var previews: some View {
        RhythmView()
    }
}

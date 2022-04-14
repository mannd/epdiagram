//
//  RhythmView.swift
//  EP Diagram
//
//  Created by David Mann on 3/5/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import SwiftUI

struct RhythmView: View {
    var dismissAction: ((Rhythm, Bool) -> Void)?

    @State var rhythm: Rhythm = Rhythm(meanCL: 600, regularity: .regular, minCL: 100, maxCL: 150, randomizeImpulseOrigin: false, randomizeConductionTime: false, impulseOrigin: .proximal, replaceExistingMarks: true)

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Regularity")) {
                    Picker(selection: $rhythm.regularity, label: Text("")) {
                        ForEach(Regularity.allCases) { rhythm in
                            Text(rhythm.description)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section(header: Text("Regular Rhythm Cycle Length")) {
                    Text("Cycle length = \(lround(Double( rhythm.meanCL))) msec")
                    Slider(value: $rhythm.meanCL, in: Rhythm.minimumCL...Rhythm.maximumCL)
                        // See https://stackoverflow.com/questions/64756306/using-a-toggle-to-disable-a-slider-in-swiftui-results-in-styling-problems for why we need to change the id to force update the slider being disabled.
                        .disabled(rhythm.regularity == .fibrillation)
                        .id(rhythm.regularity == .regular)

                }
                Section(header: Text("Fibrillation Parameters")) {
                    Text("Fibrillation minimum cycle length = \(lround(Double(rhythm.minCL))) msec")
                    Slider(value: $rhythm.minCL, in: Rhythm.minimumFibCL...(rhythm.maxCL - 10))
                        .disabled(rhythm.regularity == .regular)
                        .id(rhythm.regularity == .fibrillation)

                    Text("Fibrillation maximum cycle length = \(lround(Double(rhythm.maxCL))) msec")
                    Slider(value: $rhythm.maxCL, in: (rhythm.minCL + 10)...Rhythm.maximumFibCL)
                        .disabled(rhythm.regularity == .regular)
                        .id(rhythm.regularity == .fibrillation)
                    Picker(selection: $rhythm.impulseOrigin, label: Text("Conduction direction")) {
                        Text("Proximal -> Distal").tag(Mark.Endpoint.proximal)
                        Text("Distal -> Proximal").tag(Mark.Endpoint.distal)
                        Text("Random").tag(Mark.Endpoint.random)
                    }
                    Toggle(isOn: $rhythm.randomizeImpulseOrigin) {
                        Text("Randomize impulse origin")
                    }
                    Toggle(isOn: $rhythm.randomizeConductionTime) {
                        Text("Randomize conduction time")
                    }
                }.disabled(rhythm.regularity == .regular)
                Section(header: Text("Delete preexisting marks?")) {
                    Toggle(isOn: $rhythm.replaceExistingMarks) {
                        Text("Delete marks in selected area first?")
                    }
                }
            }
            .navigationBarTitle("Rhythm Details", displayMode: .inline)
            .navigationBarItems(leading: Button(action: { self.applyRhythm(cancel: true) }, label: { Text("Cancel")}), trailing: Button(action: { self.applyRhythm(cancel: false)
            }, label: {
                Text("Apply")
            }))
        }.navigationViewStyle(StackNavigationViewStyle())

    }

    func applyRhythm(cancel: Bool) {
        if let dismissAction = dismissAction {
            dismissAction(rhythm, cancel)
        }
    }
}

struct RhythmView_Previews: PreviewProvider {
    static var previews: some View {
        RhythmView()
    }
}

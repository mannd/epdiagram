//
//  SampleSelector.swift
//  EP Diagram
//
//  Created by David Mann on 8/1/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI

struct SampleSelector: View {
    var sampleDiagrams: [Diagram]
    @State var selectedDiagram: Diagram? = nil
    weak var delegate: ViewControllerDelegate?
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>


    var body: some View {
        NavigationView {
            VStack {
                List() {
                    ForEach(sampleDiagrams, id:\.self.name) {
                        diagram in VStack(alignment: .leading) { Text(diagram.name ?? "").bold().foregroundColor(.green)
                            Text(diagram.longDescription).foregroundColor(.secondary)
                            }.padding().onTapGesture {
                            self.selectedDiagram = diagram
                            self.delegate?.selectSampleDiagram(self.selectedDiagram)
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Sample Diagrams"), displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SampleSelector_Previews: PreviewProvider {
    static var sampleDiagram = Diagram.defaultDiagram(name: "Sample ECG")
    static var previews: some View {
        SampleSelector(sampleDiagrams: [sampleDiagram])
    }
}

//
//  RegionEditor.swift
//  EP Diagram
//
//  Created by David Mann on 10/20/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI

struct RegionTemplateEditor: View {
    @Binding var regionTemplate: RegionTemplate

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField(regionTemplate.name, text: $regionTemplate.name)
                }
                Section(header: Text("Description")) {
                    TextEditor(text: $regionTemplate.description)
                }
                Section(header: Text("Height")) {
                    Stepper(value: $regionTemplate.unitHeight, in: 1...4, step: 1) {
                        HStack {
                            Text("\(regionTemplate.unitHeight) unit" + (regionTemplate.unitHeight > 1 ? "s" : ""))
                        }
                    }
                }
                Section(header: Text("Line style")) {
                    Picker(selection: $regionTemplate.lineStyle, label: Text("Line style"), content: {
                        ForEach(Mark.LineStyle.allCases) { style in
                            Text(style.description)

                        }
                    }).pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationBarTitle(Text("Edit Region"), displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#if DEBUG
struct RegionEditor_Previews: PreviewProvider {
    static var previews: some View {
        RegionTemplateEditor(regionTemplate: .constant(RegionTemplate(name: "A", description: "Atrium", unitHeight: 1, lineStyle: .solid)))
    }
}
#endif

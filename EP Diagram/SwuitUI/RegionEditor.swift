//
//  RegionEditor.swift
//  EP Diagram
//
//  Created by David Mann on 5/16/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI
import os.log

struct RegionEditor: View {
    @State var unitHeight: Int = 1
    @State var regionTemplate: RegionTemplate
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Label:").bold()
                    TextField(regionTemplate.name, text: $regionTemplate.name)
                }
                HStack {
                    Text("Description:").bold()
                    TextField(regionTemplate.description, text: $regionTemplate.description)
                }
                Stepper(value: $regionTemplate.unitHeight, in: 1...4, step: 1) {
                    HStack {
                        Text("Height:").bold()
                        Text("\(regionTemplate.unitHeight) unit" + (regionTemplate.unitHeight > 1 ? "s" : ""))
                    } }
                Spacer()
                HStack {
                    Button(action: { saveAction() }) {
                        Text(L("Cancel"))
                    }
                    Spacer()
                    Button(action: { saveAction() }) {
                        Text(L("Save"))
                    }
                }
                }.navigationBarTitle(Text(L("Edit ") + regionTemplate.description), displayMode: .inline).padding()
        }
    }
}

private func saveAction() {
    os_log("saveAction() - RegionEditor", log: .action, type: .info)
}

#if DEBUG
struct RegionEditor_Previews: PreviewProvider {
    static let testLadder = LadderTemplate.defaultTemplate()
    static var previews: some View {
        RegionEditor(regionTemplate: testLadder.regionTemplates[0])
    }
}
#endif

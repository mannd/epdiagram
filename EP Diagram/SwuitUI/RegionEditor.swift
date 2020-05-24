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
    @State var newText: String = ""
    @State var newDescription: String = ""
    @State var unitHeight: Int = 1
    @State var region: RegionTemplate
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Label:").bold()
                    TextField(region.name, text: $region.name)
                }
                HStack {
                    Text("Description:").bold()
                    TextField(region.description, text: $region.description)
                }
                Stepper(value: $unitHeight, in: 1...4, step: 1) {
                    HStack {
                        Text("Height:").bold()
                        Text("\(unitHeight) unit" + (unitHeight > 1 ? "s" : ""))
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
                }.navigationBarTitle(Text(L("Edit ") + region.description), displayMode: .inline).padding()
        }
    }
}

private func saveAction() {
    os_log("saveAction() - RegionEditor", log: .action, type: .info)
}

struct RegionEditor_Previews: PreviewProvider {
    static let testLadder = LadderTemplate.defaultTemplate()
    static var previews: some View {
        RegionEditor(region: testLadder.regionTemplates[0])
    }
}

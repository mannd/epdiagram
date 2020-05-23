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
    @State var region: Region
    var body: some View {
        VStack {
            HStack {
                Text(L("Label:"))
                TextField(region.name, text: $region.name)
            }
            HStack {
                Text(L("Description:"))
                TextField(region.description, text: $region.description)
            }
            Stepper(value: $unitHeight, in: 1...4, step: 1) {
                Text(L("Region height = \(unitHeight) unit") + (unitHeight > 1 ? "s" : "")) }
            HStack {
                Button(action: { saveAction() }) {
                    Text(L("Save"))
                }
                Spacer()
                Button(action: { saveAction() }) {
                    Text(L("Cancel"))
                }
            }
        }.padding(10)
            .navigationBarTitle(Text(L("Edit Region ") + region.name), displayMode: .inline)
    }
}

private func saveAction() {
    os_log("saveAction() - RegionEditor", log: .action, type: .info)
}

struct RegionEditor_Previews: PreviewProvider {
    static let testLadder = Ladder.defaultLadder()
    static var previews: some View {
        RegionEditor(region: testLadder.regions[0])
    }
}

//
//  RegionEditor.swift
//  EP Diagram
//
//  Created by David Mann on 5/16/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI

struct RegionEditor: View {
    @State var newText: String = ""
    @State var newDescription: String = ""
    @State var unitHeight: Int = 1
    let region: Region
    var body: some View {
        VStack {
            HStack {
                Text(L("Label"))
                TextField(region.name, text: $newText).border(Color.black)
            }
            HStack {
                Text(L("Description"))
                TextField(region.description, text: $newDescription).border(Color.black)
            }
            Stepper(value: $unitHeight, in: 1...4, step: 1) {
                Text("Region height = \(unitHeight) unit" + (unitHeight > 1 ? "s" : "")) }
            HStack {
                Button(action: { saveAction() }) {
                    Text("Save")
                }
                Spacer()
                Button(action: { saveAction() }) {
                    Text("Cancel")
                }
            }
        }.padding(10)
            .navigationBarTitle(Text("Edit Region " + region.name), displayMode: .inline)
    }
}

func saveAction() {

}

struct RegionEditor_Previews: PreviewProvider {
    static let testLadder = Ladder.defaultLadder()
    static var previews: some View {
        RegionEditor(region: testLadder.regions[0])
    }
}

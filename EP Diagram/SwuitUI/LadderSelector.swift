//
//  LadderSelector.swift
//  EP Diagram
//
//  Created by David Mann on 5/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI
import os.log

extension LadderTemplate: Identifiable { }

struct LadderSelector: View {
    var ladderTemplates: [LadderTemplate] = [LadderTemplate.defaultTemplate(), LadderTemplate.defaultTemplate()]
    @State private var selectedLadderIndex: Int = 0
    @State private var showingAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationView {
            VStack {
                Picker(selection: $selectedLadderIndex, label: Text("")) {
                    ForEach(0 ..< ladderTemplates.count) {
                        Text(self.ladderTemplates[$0].name)
                    }
                    }.padding().labelsHidden()
                Spacer()
                Text(ladderTemplates[selectedLadderIndex].name).bold()
                Text(ladderTemplates[selectedLadderIndex].description).foregroundColor(.secondary)
                Spacer()
//                Spacer(minLength: 50)
                Text("Regions").font(.headline)
                HStack {
                    Text("Labels").foregroundColor(.primary)
                    Spacer()
                    Text("Description").foregroundColor(.primary)
                }.padding()
                    .font(.headline)
                List(0 ..< ladderTemplates[selectedLadderIndex].regionTemplates.count) { item in
                    HStack {
                        Text(self.ladderTemplates[self.selectedLadderIndex].regionTemplates[item].name).fontWeight(.bold).foregroundColor(.red)
                        Spacer()
                        Text(self.ladderTemplates[self.selectedLadderIndex].regionTemplates[item].description)
                    }
                }
            }.animation(.default)
                .navigationBarTitle("Select Ladder")
                .navigationBarItems(
                    trailing: Button(action: { self.showingAlert = true }) { Text("Save")
                })
        }
    }

    private func selectLadder() {
        os_log("selectLadder()", log: OSLog.action, type: .info)
        let pickerIndex = selectedLadderIndex
        let selectedLadderTemplate = ladderTemplates[pickerIndex]
        os_log("selected ladder = %@", selectedLadderTemplate.name)
    }
}


private func saveAction() {
    os_log("saveAction() - LadderSelector", log: .action, type: .info)

}

private func cancelAction() {
    os_log("cancelAction() - LadderSelector", log: .action, type: .info)

}

fileprivate let testData: [LadderTemplate] = [LadderTemplate.defaultTemplate(), LadderTemplate.defaultTemplate2(), LadderTemplate.defaultTemplate()]

struct LadderSelector_Previews: PreviewProvider {
    static var previews: some View {
        LadderSelector(ladderTemplates: testData)
    }
}

//
//  LadderSelector.swift
//  EP Diagram
//
//  Created by David Mann on 5/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI
import os.log

struct LadderSelector: View {
    @State var ladderTemplates: [LadderTemplate] = [LadderTemplate.defaultTemplate(), LadderTemplate.defaultTemplate()]
    @State private var selectedLadderIndex: Int = 0
    @State private var showingAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationView {
            VStack {
                Picker(selection: $selectedLadderIndex, label: Text(L("Select:"))) {
                    ForEach(0 ..< ladderTemplates.count) {
                        Text(self.ladderTemplates[$0].name)
                    }
                }
            }
            .padding()
            .navigationBarTitle(L("Select Ladder"))
            .foregroundColor(.purple)
            .navigationBarItems(
                leading: Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                })
                { Text("Cancel") }
                    .alert(isPresented: $showingAlert)
                    { Alert(
                        title: Text(L("Change Ladder?")),
                        message: Text(L("Previous ladder data will be lost.  If you wish to keep the data, save the diagram first.")),
                        primaryButton: .destructive(Text("Do it")) {
                            self.selectLadder()
                            self.presentationMode.wrappedValue.dismiss()
                        },
                        secondaryButton: .cancel(Text("Cancel"))) },

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

struct LadderSelector_Previews: PreviewProvider {
    static var previews: some View {
        LadderSelector()
    }
}

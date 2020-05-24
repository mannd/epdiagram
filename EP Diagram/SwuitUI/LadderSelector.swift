//
//  LadderSelector.swift
//  EP Diagram
//
//  Created by David Mann on 5/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI
import os.log

extension LadderTemplate: Identifiable {}

struct LadderSelector: View {
    @State var ladderTemplates: [LadderTemplate] = [LadderTemplate.defaultTemplate(), LadderTemplate.defaultTemplate()]
    @State private var selectedLadderIndex: Int = 0
    @State private var showingAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    Divider()
                    Picker(selection: $selectedLadderIndex, label: Text("")) {
                        ForEach(0 ..< ladderTemplates.count) {
                            Text(self.ladderTemplates[$0].name)
                        }
                    }.labelsHidden()
                    Divider()
                    Text(ladderTemplates[selectedLadderIndex].name).bold().foregroundColor(.green)
                    Text(ladderTemplates[selectedLadderIndex].description).foregroundColor(.secondary)
                    List(ladderTemplates[selectedLadderIndex].regionTemplates) { item in
                        HStack {
                            Text(item.name).fontWeight(.bold).foregroundColor(.red)
                            Spacer()
                            Text(item.description).foregroundColor(.secondary)
                        }
                    }.animation(.default)
                }
                .navigationBarTitle("Select Ladder")
                HStack {
                    Button(action: { self.showingAlert = true }) {
                        Text("Select Ladder")
                    }.alert(isPresented: $showingAlert)
                    { Alert(
                        title: Text(L("Select Ladder?")),
                        message: Text(L("Previous ladder data will be lost.  If you wish to keep the data, save the diagram first.")),
                        primaryButton: .destructive(Text("Select Ladder")) {
                            self.selectLadder()
                            self.presentationMode.wrappedValue.dismiss()
                        },
                        secondaryButton: .cancel(Text("Cancel"))) }
                    Spacer()
                    NavigationLink(destination: LadderEditor(ladder: ladderTemplates[selectedLadderIndex])) {
                        Text("Edit Ladder")
                    }
                }.padding()
            }
        }
    }

    private func selectLadder() {
        os_log("selectLadder()", log: OSLog.action, type: .info)
        let pickerIndex = selectedLadderIndex
        let selectedLadderTemplate = ladderTemplates[pickerIndex]
        os_log("selected ladder = %@", selectedLadderTemplate.name)
    }
}


#if DEBUG
fileprivate let testData: [LadderTemplate] = [LadderTemplate.defaultTemplate(), LadderTemplate.defaultTemplate2(), LadderTemplate.defaultTemplate()]

struct LadderSelector_Previews: PreviewProvider {
    static var previews: some View {
        LadderSelector(ladderTemplates: testData)
    }
}
#endif

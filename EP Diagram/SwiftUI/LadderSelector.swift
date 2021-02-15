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

// Ladder selector is really selecting a ladder template.
struct LadderSelector: View {
    @State var ladderTemplates: [LadderTemplate] = []
    @State var selectedIndex: Int = 0
    @State var selectedTemplate: LadderTemplate? = nil
    @State private var showingAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    weak var delegate: DiagramViewControllerDelegate?

    var ladderListView: some View {
        NavigationView {
            Form {
                Section(header: Text("Select ladder")) {
                    Picker(selection: $selectedIndex, label: Text("")) {
                        ForEach(0 ..< ladderTemplates.count) {
                            Text(self.ladderTemplates[$0].name)
                        }
                        }.pickerStyle(WheelPickerStyle()).padding()
                }
                Section(header: Text("Ledder details")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(ladderTemplates[selectedIndex].name).bold().foregroundColor(.green)
                    }
                    HStack {
                        Text("Description")
                        Spacer()
                        Text(ladderTemplates[selectedIndex].description).foregroundColor(.secondary)
                    }
                    List(ladderTemplates[selectedIndex].regionTemplates) { item in
                        HStack {
                            Text(item.name).fontWeight(.bold).foregroundColor(.red)
                            Spacer()
                            Text(item.description).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Select Ladder"), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                self.selectLadder()
                self.presentationMode.wrappedValue.dismiss() }) {
                Text("Select") })
        }
    }

    @ViewBuilder
    var listView: some View {
        if ladderTemplates.isEmpty {
            emptyListView
        } else {
            ladderListView
        }
    }

    var body: some View {
        listView.navigationViewStyle(StackNavigationViewStyle())
    }

    var emptyListView: some View {
           Text("You have no saved ladders.  Use the Ladder Editor to create new ones.")
       }

    private func selectLadder() {
        os_log("selectLadder()", log: OSLog.action, type: .info)
        let pickerIndex = selectedIndex
        let selectedLadderTemplate = ladderTemplates[pickerIndex]
        os_log("selected ladder = %@", selectedLadderTemplate.name)
        delegate?.selectLadderTemplate(ladderTemplate: selectedLadderTemplate)
    }
}


#if DEBUG
fileprivate let testData: [LadderTemplate] = [LadderTemplate.defaultTemplate1(), LadderTemplate.defaultTemplate2(), LadderTemplate.defaultTemplate1()]

struct LadderSelector_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LadderSelector(ladderTemplates: testData)
            LadderSelector(ladderTemplates: testData)
                .preferredColorScheme(.dark)
                .padding(0.0)
        }
    }
}
#endif

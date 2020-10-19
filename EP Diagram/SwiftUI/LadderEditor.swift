//
//  LadderEditor.swift
//  EP Diagram
//
//  Created by David Mann on 5/14/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI
import os.log

extension RegionTemplate: Identifiable {}

struct LadderEditor: View {
    @Binding var ladderTemplate: LadderTemplate
    @State private var editMode = EditMode.inactive
    var lineStyles = ["Solid", "Dashed", "Dotted"]

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField(ladderTemplate.name, text: $ladderTemplate.name)
                }
                Section(header: Text("Description")) {
                    TextEditor(text: $ladderTemplate.description)
                }
                Section(header: Text("Regions")) {
                    RegionListView(ladderTemplate: $ladderTemplate)
                }
            }
            .navigationBarTitle(Text("Edit Ladder"), displayMode: .inline)
            .navigationBarItems(leading: EditButton(), trailing: addButton)
            .environment(\.editMode, $editMode)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var addButton: some View {
        switch editMode {
        case .inactive:
            return AnyView(Button(action: onAdd) { Image(systemName: "plus")})
        default:
            return AnyView(EmptyView())
        }
    }

    private func onAdd() {
        os_log("onAdd() - LadderEditor", log: OSLog.action, type: .info)
        let newRegionTemplate = RegionTemplate(name: "XX", description: "New region", unitHeight: 1)
        ladderTemplate.regionTemplates.append(newRegionTemplate)
    }

    private func itemsToBeDeleted() -> Bool {
        var flag = false
        for i in 0..<ladderTemplate.regionTemplates.count {
            if ladderTemplate.regionTemplates[i].deletionFlag == true {
                flag = true
            }
        }
        return flag
    }
}



struct RegionListView: View {
    @Binding var ladderTemplate: LadderTemplate

    var body: some View {
        List {
            ForEach(ladderTemplate.regionTemplates.indices, id: \.self) {
                index in
                VStack(alignment: .leading) {
                    HStack {
                        Text("Name:").bold()
                        TextField("Name", text: self.$ladderTemplate.regionTemplates[index].name)
                    }.foregroundColor(self.ladderTemplate.regionTemplates[index].deletionFlag ? .white : .primary)
                    HStack {
                        Text("Description:").bold()
                        TextField("Description", text: self.$ladderTemplate.regionTemplates[index].description)
                    }
                    .foregroundColor(self.ladderTemplate.regionTemplates[index].deletionFlag ? .white : .primary)
                    Stepper(value: self.$ladderTemplate.regionTemplates[index].unitHeight, in: 1...4, step: 1) {
                        HStack {
                            Text("Height:").bold()
                            Text("\(self.ladderTemplate.regionTemplates[index].unitHeight) unit" + (self.ladderTemplate.regionTemplates[index].unitHeight > 1 ? "s" : ""))
                        }
                    }
                    Picker(selection: self.$ladderTemplate.regionTemplates[index].lineStyle, label: Text("Line style"), content: {
                        ForEach(Mark.LineStyle.allCases) { style in
                            Text(style.description)
                        }
                    })
                }.foregroundColor(self.ladderTemplate.regionTemplates[index]
                                    .deletionFlag ? .white : .primary)
                .listRowBackground(self.ladderTemplate.regionTemplates[index].deletionFlag ? Color.red : Color.clear).disabled(self.ladderTemplate.regionTemplates[index].deletionFlag)
            }
            .onMove(perform: onMove)
            .onDelete(perform: onDelete)
        }
    }

    private func onDelete(offsets: IndexSet) {
        os_log("onDelete() - LadderEditor", log: OSLog.action, type: .info)
        for item in offsets {
            ladderTemplate.regionTemplates[item].deletionFlag = true
        }
    }

    private func onMove(source: IndexSet, destination: Int) {
        os_log("onMove() - LadderEditor", log: OSLog.action, type: .info)
        ladderTemplate.regionTemplates.move(fromOffsets: source, toOffset: destination)
    }

    #if DEBUG
    struct LadderEditor_Previews: PreviewProvider {
        static var previews: some View {
            LadderEditor(ladderTemplate: .constant(LadderTemplate.defaultTemplate()))
        }
    }
    #endif
}

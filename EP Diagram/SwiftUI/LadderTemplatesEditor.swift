//
//  LadderTemplatesEditor.swift
//  EP Diagram
//
//  Created by David Mann on 5/29/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI
import os.log

/*
Must uses indices for this to work.  For onDelete, just mark the row for deletion-> gray out fields, disable navigation, Label for deletion, etc.  Have a deletion flag bit.  When View is Saved, do the actual deletion.
 */
struct LadderTemplatesEditor: View {
    @State var ladderTemplates: [LadderTemplate]
    @State var editMode = EditMode.inactive
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        NavigationView {
            VStack {
                List() {
                    ForEach(ladderTemplates.indices, id: \.self) { index in
                        NavigationLink(destination: LadderEditor(ladderTemplate: self.$ladderTemplates[index])) {
                            VStack(alignment: .leading) {
                                Text(self.ladderTemplates[index].name).foregroundColor(self.ladderTemplates[index].deletionFlag ? Color.white : Color.primary)
                                Text(self.ladderTemplates[index].description).foregroundColor(self.ladderTemplates[index].deletionFlag ? Color.white : Color.secondary)
                            }
                        }.listRowBackground(self.ladderTemplates[index].deletionFlag ? Color.red : Color.clear).disabled(self.ladderTemplates[index].deletionFlag)
                    }.onMove(perform: onMove)
                        .onDelete(perform: onDelete)
                        .padding()
                }.navigationBarTitle(Text("Edit Ladders"), displayMode: .inline)
                    .navigationBarItems(leading: EditButton(), trailing: addButton)
                    .environment(\.editMode, $editMode)
                Button(action: { self.onSave() }, label: {Text("Save")}).disabled(self.editMode == .active)
            }
        }
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
        let newRegionTemplate = RegionTemplate(name: "XXX", description: "New region", unitHeight: 1)
        let newLadderTemplate = LadderTemplate(name: "New Ladder", description: "New ladder", regionTemplates: [newRegionTemplate])
        ladderTemplates.append(newLadderTemplate)
    }

    private func onDelete(offsets: IndexSet) {
        os_log("onDelete() - LadderTemplatesEditor", log: OSLog.action, type: .info)
        for item in offsets {
            ladderTemplates[item].deletionFlag = true
        }
    }

    private func onMove(source: IndexSet, destination: Int) {
        os_log("onMove() - LadderTemplatesEditor", log: OSLog.action, type: .info)
        ladderTemplates.move(fromOffsets: source, toOffset: destination)
    }

    private func onSave() {
        os_log("onSave() - LadderTemplatesEditor", log: OSLog.action, type: .info)
        do {
            try Persistance.store(ladderTemplates, to: .documents, withFileName: "user_ladder_templates")
            self.presentationMode.wrappedValue.dismiss()
        }
        catch let error {
            os_log("Save error %s", log: OSLog.default, type: .error, error.localizedDescription)
//            throw error
        }
    }
}

#if DEBUG
fileprivate let testData = [LadderTemplate.defaultTemplate(), LadderTemplate.defaultTemplate2()]

struct LadderTemplatesEditor_Previews: PreviewProvider {
    static var previews: some View {
        LadderTemplatesEditor(ladderTemplates: testData)
    }
}
#endif

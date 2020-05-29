//
//  LadderTemplatesEditor.swift
//  EP Diagram
//
//  Created by David Mann on 5/29/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI
import os.log

struct LadderTemplatesEditor: View {
    @State var ladderTemplates: [LadderTemplate] = []
    @State var editMode = EditMode.inactive
    
    var body: some View {
        NavigationView {
            List() {
                ForEach(ladderTemplates.indices) { index in
                    NavigationLink(destination: LadderEditor(ladderTemplate: self.$ladderTemplates[index])) {
                        VStack(alignment: .leading) {
                            Text(self.ladderTemplates[index].name).bold()
                            Text(self.ladderTemplates[index].description).foregroundColor(.secondary)
                        }
                    }
                }.onMove(perform: onMove)
                    .onDelete(perform: onDelete)
                    .padding()
            }.navigationBarTitle(Text("Edit Ladders"), displayMode: .inline)
                .navigationBarItems(leading: EditButton(), trailing: addButton)
                .environment(\.editMode, $editMode)
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
    }

    private func onDelete(offsets: IndexSet) {
        os_log("onDelete() - LadderTemplatesEditor", log: OSLog.action, type: .info)
        ladderTemplates.remove(atOffsets: offsets)
    }

    private func onMove(source: IndexSet, destination: Int) {
        os_log("onMove() - LadderTemplatesEditor", log: OSLog.action, type: .info)
        ladderTemplates.move(fromOffsets: source, toOffset: destination)
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

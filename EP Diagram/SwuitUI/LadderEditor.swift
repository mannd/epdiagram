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

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField(ladderTemplate.name, text: $ladderTemplate.name).padding()
                }
                Section(header: Text("Description")) {
                    TextField(ladderTemplate.description, text: $ladderTemplate.description).padding()
                }
                Section(header: Text("Regions")) {
                    List {
                        // Thanks to https://stackoverflow.com/questions/57836990/swiftui-dynamic-list-with-binding-controls for figuring out how to do this!
                        ForEach(ladderTemplate.regionTemplates.indices) {
                            index in
                            VStack {
                                HStack {
                                    Text("Name:").bold()
                                    TextField("Name", text: self.$ladderTemplate.regionTemplates[index].name)
                                }
                                HStack {
                                    Text("Description:").bold()
                                    TextField("Description", text: self.$ladderTemplate.regionTemplates[index].description)
                                }
                                Stepper(value: self.$ladderTemplate.regionTemplates[index].unitHeight, in: 1...4, step: 1) {
                                    HStack {
                                        Text("Height:").bold()
                                        Text("\(self.ladderTemplate.regionTemplates[index].unitHeight) unit" + (self.ladderTemplate.regionTemplates[index].unitHeight > 1 ? "s" : ""))
                                    }
                                }
                            }
                        }
                        .onMove(perform: onMove)
                        .onDelete(perform: onDelete)
                    }
                }
            }
            .navigationBarTitle(Text("Edit Ladder"), displayMode: .inline)
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
        os_log("onDelete() - LadderEditor", log: OSLog.action, type: .info)
        ladderTemplate.regionTemplates.remove(atOffsets: offsets)
    }

    private func onMove(source: IndexSet, destination: Int) {
        os_log("onMove() - LadderEditor", log: OSLog.action, type: .info)
        ladderTemplate.regionTemplates.move(fromOffsets: source, toOffset: destination)
    }
}

#if DEBUG
struct LadderEditor_Previews: PreviewProvider {
    static var previews: some View {
        LadderEditor(ladderTemplate: .constant(LadderTemplate.defaultTemplate()))
    }
}
#endif

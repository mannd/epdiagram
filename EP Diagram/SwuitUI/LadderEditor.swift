//
//  LadderEditor.swift
//  EP Diagram
//
//  Created by David Mann on 5/14/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI
import UIKit
import os.log

extension RegionTemplate: Identifiable {}

struct LadderEditor: View {
    @State var ladderTemplate: LadderTemplate = LadderTemplate.defaultTemplate()
    @State private var editMode = EditMode.inactive

    var body: some View {
        NavigationView {
            VStack {
                Text("Name").bold()
                TextField(ladderTemplate.name, text: $ladderTemplate.name).padding()
                Text("Description").bold()
                TextField(ladderTemplate.name, text: $ladderTemplate.description).padding()
                List {
                    ForEach(ladderTemplate.regionTemplates) {
                        regionTemplate in
                        NavigationLink(
                        destination: RegionEditor(regionTemplate: regionTemplate)) {
                            HStack {
                                Text(regionTemplate.name).bold()
                                Spacer()
                                Text(regionTemplate.description)
                            }
                        }
                    }
                    .onMove(perform: onMove)
                    .onDelete(perform: onDelete)
                }
            }
            .navigationBarTitle("Ladder")
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
        LadderEditor()
    }
}
#endif

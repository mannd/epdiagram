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

struct LadderTemplateEditor: View {
    @Binding var ladderTemplate: LadderTemplate
    @State private var editMode = EditMode.inactive
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
}

struct RegionListView: View {
    @Binding var ladderTemplate: LadderTemplate

    var body: some View {
        List {
            ForEach(ladderTemplate.regionTemplates) { regionTemplate in
                NavigationLink(
                    destination: RegionEditor(regionTemplate: self.selectedRegionTemplate(id: regionTemplate.id))) {
                    VStack(alignment: .leading) {
                        Text(regionTemplate.name).bold()
                        Text(regionTemplate.description)
                        Text("Height: \(regionTemplate.unitHeight)")
                        Text("Line style: \(regionTemplate.lineStyle.description)")
                    }
                }
            }
            .onDelete { indexSet in
                self.ladderTemplate.regionTemplates.remove(atOffsets: indexSet)
            }
            .onMove { indices, newOffset in
                self.ladderTemplate.regionTemplates.move(fromOffsets: indices, toOffset: newOffset)
            }
        }
    }

    private func selectedRegionTemplate(id: UUID) -> Binding<RegionTemplate> {
        guard let index = self.ladderTemplate.regionTemplates.firstIndex(where: { $0.id == id }) else {
            fatalError("Region template doesn't exist.")
        }
        print(index)
        return self.$ladderTemplate.regionTemplates[index]
    }

    #if DEBUG
    struct LadderEditor_Previews: PreviewProvider {
        static var previews: some View {
            LadderTemplateEditor(ladderTemplate: .constant(LadderTemplate.defaultTemplate()))
        }
    }
    #endif
}

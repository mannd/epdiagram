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
    // For some reason, need the observed object here, even though it is never called.  Having it here apparently forces updates.
    @ObservedObject var ladderTemplatesController: LadderTemplatesModelController
    @Binding var ladderTemplate: LadderTemplate
    @State private var editMode = EditMode.inactive
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        VStack {
            NavigationView {
                Form {
                    Section(header: Text("Name")) {
                        TextField(ladderTemplate.name, text: $ladderTemplate.name)
                    }
                    Section(header: Text("Description")) {
                        TextEditor(text: $ladderTemplate.description)
                    }
                    Section(header: Text("Left margin")) {
                        Stepper(value: $ladderTemplate.leftMargin, in: 30...100, step: 5) {
                            HStack {
                                Text("\(Int(ladderTemplate.leftMargin)) points")
                            }
                        }
                    }
                    Section(header: Text("Regions")) {
                        RegionListView(ladderTemplatesController: ladderTemplatesController, ladderTemplate: $ladderTemplate)
                    }
                }
                .navigationBarTitle(Text("Edit Ladder"), displayMode: .inline)
                .navigationBarItems(leading: EditButton(), trailing: addButton)
                .environment(\.editMode, $editMode)
            }
            .navigationViewStyle(StackNavigationViewStyle())
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
        let newRegionTemplate = RegionTemplate(name: "XX", description: "New region", unitHeight: 1)
        ladderTemplate.regionTemplates.append(newRegionTemplate)
    }
}

struct RegionListView: View {
    @ObservedObject var ladderTemplatesController: LadderTemplatesModelController
    @Binding var ladderTemplate: LadderTemplate
    @State private var tooFewRegionTemplates = false

    var body: some View {
        List {
            ForEach(ladderTemplate.regionTemplates) { regionTemplate in
                NavigationLink(
                    destination: RegionTemplateEditor(ladderTemplatesController: ladderTemplatesController, regionTemplate: self.selectedRegionTemplate(id: regionTemplate.id))) {
                    VStack(alignment: .leading) {
                        Text(regionTemplate.name).bold().foregroundColor(.red)
                        Text(regionTemplate.description).bold()
                        Text("Height: ") + Text("\(regionTemplate.unitHeight)").bold()
                        Text("Line style: ") + Text("\(regionTemplate.style.description)").bold()
                    }
                }.alert(isPresented: $tooFewRegionTemplates) { Alert(title: Text("Too Few Regions"), message: Text("You have to have at least 1 region in your ladder."), dismissButton: .default(Text("OK")))
                }
            }
            .onDelete { indexSet in
                // Don't allow deletion of last region, having zero regions will break things.
                self.tooFewRegionTemplates = self.ladderTemplate.regionTemplates.count < 2
                if !self.tooFewRegionTemplates {
                    self.ladderTemplate.regionTemplates.remove(atOffsets: indexSet)
                }
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
        return self.$ladderTemplate.regionTemplates[index]
    }

    #if DEBUG
    struct LadderEditor_Previews: PreviewProvider {

        static var previews: some View {
            LadderTemplateEditor(ladderTemplatesController: LadderTemplatesModelController(ladderTemplates: LadderTemplate.defaultTemplates()), ladderTemplate: .constant(LadderTemplate.defaultTemplate1()))
        }
    }
    #endif
}

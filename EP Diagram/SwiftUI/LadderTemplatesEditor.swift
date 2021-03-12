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
    @ObservedObject var ladderTemplatesController: LadderTemplatesModelController
    @State private var editMode = EditMode.inactive
    @State private var fileSaveError = false
    @State private var errorMessage = String()
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @GestureState private var dragOffset = CGSize.zero

    var body: some View {
        //        VStack {
        NavigationView {
            Form {
                Section(header: Text("First in list is default ladder for new diagrams")) {
                    List() {
                        ForEach(ladderTemplatesController.ladderTemplates) { ladderTemplate in
                            NavigationLink(destination: LadderTemplateEditor(ladderTemplatesController: ladderTemplatesController, ladderTemplate: self.selectedLadderTemplate(id: ladderTemplate.id))) {
                                VStack(alignment: .leading) {
                                    Text(ladderTemplate.name)
                                    Text(ladderTemplate.description)
                                }
                            }

                        }
                        .onDelete { indexSet in
                            self.ladderTemplatesController.ladderTemplates.remove(atOffsets: indexSet)
                        }
                        .onMove { indices, newOffset in
                            self.ladderTemplatesController.ladderTemplates.move(fromOffsets: indices, toOffset: newOffset)
                        }
                    }
                }

            }
            .navigationBarTitle(Text("Ladders"), displayMode: .inline)
            .navigationBarItems(leading: EditButton(), trailing: addButton)
            .environment(\.editMode, $editMode)
        }
        // Force full screen for this view even on iPad
        .navigationViewStyle(StackNavigationViewStyle())

    }

    // We create a binding for each template, otherwise delete does not work.  See https://troz.net/post/2019/swiftui-data-flow/ where this is the least ugly of several ugly work arounds.
    private func selectedLadderTemplate(id: UUID) -> Binding<LadderTemplate> {
        guard let index = self.ladderTemplatesController.ladderTemplates.firstIndex(where: { $0.id == id }) else {
            fatalError("Ladder template doesn't exist.")
        }
        return self.$ladderTemplatesController.ladderTemplates[index]
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
        let newRegionTemplate = RegionTemplate(name: "NEW", description: "New region", unitHeight: 1)
        let newLadderTemplate = LadderTemplate(name: "New Ladder", description: "New ladder", regionTemplates: [newRegionTemplate])
        ladderTemplatesController.ladderTemplates.append(newLadderTemplate)
    }
}

#if DEBUG
fileprivate let testData = [LadderTemplate.defaultTemplate1(), LadderTemplate.defaultTemplate2()]

struct LadderTemplatesEditor_Previews: PreviewProvider {
    static var previews: some View {
        LadderTemplatesEditor(ladderTemplatesController: LadderTemplatesModelController(ladderTemplates: LadderTemplate.defaultTemplates()))

    }
}
#endif

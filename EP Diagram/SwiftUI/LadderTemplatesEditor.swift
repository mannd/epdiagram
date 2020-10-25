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
    @State var ladderTemplates: [LadderTemplate]
    @State private var editMode = EditMode.inactive
    @State private var fileSaveError = false
    @State private var errorMessage = String()
    var parentViewTitle: String = "Back"
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @GestureState private var dragOffset = CGSize.zero
    weak var delegate: ViewControllerDelegate?
    
    var body: some View {
        NavigationView {
            VStack {
                List() {
                    ForEach(ladderTemplates) { ladderTemplate in
                        NavigationLink(destination: LadderTemplateEditor(ladderTemplate: self.selectedLadderTemplate(id: ladderTemplate.id))) {
                            VStack(alignment: .leading) {
                                Text(ladderTemplate.name)
                                Text(ladderTemplate.description)
                            }
                        }

                    }
                    .onDelete { indexSet in
                        self.ladderTemplates.remove(atOffsets: indexSet)
                    }
                    .onMove { indices, newOffset in
                        self.ladderTemplates.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                SaveButton(action: self.onSave)
                    .alert(isPresented: $fileSaveError) {
                        Alert(title: Text("Error Saving Ladders"), message: Text("Changes to ladders could not be saved. \(errorMessage)"), dismissButton: .default(Text("OK")))
                    }
                    .disabled(self.editMode == .active)
            }.padding()
            .navigationBarTitle(Text("Ladders"), displayMode: .inline)
            .navigationBarItems(leading: EditButton(), trailing: addButton)
            .environment(\.editMode, $editMode)
        }
        // Force full screen for this view even on iPad
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // We create a binding for each template, otherwise delete does not work.  See https://troz.net/post/2019/swiftui-data-flow/ where this is the least ugly of several ugly work arounds.
    private func selectedLadderTemplate(id: UUID) -> Binding<LadderTemplate> {
        guard let index = self.ladderTemplates.firstIndex(where: { $0.id == id }) else {
            fatalError("Ladder template doesn't exist.")
        }
        return self.$ladderTemplates[index]
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
        ladderTemplates.append(newLadderTemplate)
    }

    // FIXME: Catch errors and set $fileSaveError to activate alert.
    // Errors should include deleting last template and templates with no regionTemplates.
    private func onSave() {
        os_log("onSave() - LadderTemplatesEditor", log: OSLog.action, type: .info)
        for ladderTemplate in ladderTemplates {
            if ladderTemplate.regionTemplates.count < 1 {
                fileSaveError = true
            }
        }
        delegate?.saveTemplates(ladderTemplates)
        self.presentationMode.wrappedValue.dismiss()
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

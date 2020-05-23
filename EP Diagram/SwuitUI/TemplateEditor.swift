//
//  TemplateEditor.swift
//  EP Diagram
//
//  Created by David Mann on 5/20/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI
import os.log

struct TemplateEditor: View {
    @State var templates: [LadderTemplate] = [LadderTemplate.defaultTemplate()]
    @State private var editMode = EditMode.inactive

    var body: some View {
        NavigationView {
            List {
                ForEach(templates, id: \.id) {
                    template in
                    NavigationLink(destination: LadderEditor()) {
                        Text(template.name)
                    }
                }
                .onMove(perform: onMove)
                .onDelete(perform: onDelete)
            }
            .navigationBarTitle(L("Ladder Templates"))
            .navigationBarItems(leading: EditButton(), trailing: addButton)
            .environment(\.editMode, $editMode)
        }
    }

    private var addButton: some View {
        switch editMode {
        case .inactive:
            return AnyView(Button(action: onAdd) {
                Image(systemName: "plus")})
        default:
            return AnyView(EmptyView())
        }
    }

    init() {
        let array = Persistance.retrieve("user_ladder_templates", from: .documents, as: [LadderTemplate].self)
        if let array = array {
            templates = array
        }
    }
    private func onAdd() {
        os_log("onAdd() - TemplateEditor", log: OSLog.action, type: .info)
    }

    private func onDelete(offsets: IndexSet) {
        // FIXME: Warn about deleting a template.
        templates.remove(atOffsets: offsets)
    }

    private func onMove(source: IndexSet, destination: Int) {
        templates.move(fromOffsets: source, toOffset: destination)
    }
}


struct TemplateEditor_Previews: PreviewProvider {
    static var previews: some View {
        TemplateEditor()
    }
}

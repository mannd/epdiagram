//
//  DiagramSelector.swift
//  EP Diagram
//
//  Created by David Mann on 6/6/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI

struct DiagramSelector: View {
    @State var names: [String] = []
    @State var selectedName: String = ""
    weak var delegate: ViewControllerDelegate?
    @State private var editMode = EditMode.inactive
    @State private var showingAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationView {
            VStack {
                List() {
                    ForEach(names, id:\.self) {
                        name in
                        Text(name).onTapGesture {
                            self.showingAlert = true
                            self.selectedName = name
                        }.alert(isPresented: self.$showingAlert) {
                            Alert(
                                title: Text("Open Diagram \"\(self.selectedName)\"?"),
                                message: Text("Old diagram will be automatically saved first."),
                                primaryButton: .default(Text("Open")) {
                                    self.delegate?.selectDiagram(diagramName: self.selectedName)
                                    self.presentationMode.wrappedValue.dismiss() },
                                secondaryButton: .cancel(Text("Cancel")) {
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                            )}
                                .padding()
                        }.onDelete {
                            indices in
                        for index in indices {
                            self.delegate?.deleteDiagram(diagramName: self.names[index])
                            self.names.remove(at: index)
                        }
                    }
                }
                .navigationBarTitle(Text("Select diagram"), displayMode: .inline)
                .navigationBarItems(leading: EditButton())
                .environment(\.editMode, $editMode)
            }
    }
}
}

#if DEBUG
let names = ["File1", "File2", "File3"]

struct DiagramSelector_Previews: PreviewProvider {
    static var previews: some View {
        DiagramSelector(names: names)
    }
}
#endif

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
                                title: Text("Open Selected Diagram?"),
                                message: Text("If you have marked up previous ladder this data will be lost unless you first save it.  Choose Cancel to return to your diagram, or Select to open this diagram."),
                                primaryButton: .destructive(Text("Select")) {
                                    self.delegate?.selectDiagram(diagramName: self.selectedName)
                                    self.presentationMode.wrappedValue.dismiss() },
                                secondaryButton: .cancel(Text("Cancel")) {
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                            )}
                                .padding().navigationBarTitle("Select Diagram", displayMode: .inline)
                        }.onDelete {
                            indices in
                        for index in indices {
                            self.delegate?.deleteDiagram(diagramName: self.names[index])
                            self.names.remove(at: index)
                        }
                    }
                }
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

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
    weak var delegate: ViewControllerDelegate?
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationView {
            List() {
                ForEach(names, id:\.self) {
                    name in
                    Text(name).onTapGesture {
                        P("tap")
                        self.delegate?.selectDiagram(diagramName: name)
                        self.presentationMode.wrappedValue.dismiss()
                    }.padding().navigationBarTitle("Select Diagram", displayMode: .inline)
                }.onDelete {
                    indices in
                    for index in indices {
                        self.delegate?.deleteDiagram(diagramName: self.names[index])
                        self.names.remove(at: index)
                    }
                }
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

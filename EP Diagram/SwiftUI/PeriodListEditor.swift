//
//  PeriodListEditor.swift
//  EP Diagram
//
//  Created by David Mann on 3/1/22.
//  Copyright © 2022 EP Studios. All rights reserved.
//

import SwiftUI

// TODO: dismiss doesn't work right
struct PeriodListEditor: View {
    var dismissAction: (([Period], Bool) -> Void)?
    var periods: [Period] = []
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Test")) {
                Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                }
            }
            .navigationBarTitle(Text("Periods"), displayMode: .inline)
//            .navigationBarItems(leading: EditButton(), trailing: addButton)
//            .environment(\.editMode, $editMode)
        }
        // Force full screen for this view even on iPad
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct PeriodListEditor_Previews: PreviewProvider {
    static var previews: some View {
        PeriodListEditor()
    }
}

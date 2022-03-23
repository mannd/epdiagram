//
//  PeriodListEditor.swift
//  EP Diagram
//
//  Created by David Mann on 3/1/22.
//  Copyright © 2022 EP Studios. All rights reserved.
//

import SwiftUI
import os.log

struct PeriodListEditor: View {
    var dismissAction: (([Period], Bool) -> Void)?
    @State var periods: [Period] = []
    @State private var editMode = EditMode.inactive
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Periods")) {
                    List() {
                        ForEach (periods, id: \.self.id) {
                            period in NavigationLink(destination: PeriodEditor()) {
                                VStack(alignment: .leading) {
                                    Text(period.name)
                                }
                            }.background(Color(period.color))
                        }
                        .onDelete { indexSet in
                            self.periods.remove(atOffsets: indexSet)
                        }
                        .onMove { indices, newOffset in
                            self.periods.move(fromOffsets: indices, toOffset: newOffset)
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Periods"), displayMode: .inline)
            .navigationBarItems(leading: EditButton(), trailing: addButton)
            .environment(\.editMode, $editMode)
            .onDisappear() {
                if let dismissAction = dismissAction {
                    dismissAction(periods, false)
                }
            }
        }
        // Force full screen for this view even on iPad
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
        os_log("onAdd() - PeriodListEditor", log: OSLog.action, type: .info)
//        let newRegionTemplate = RegionTemplate(name: "NEW", description: "New region", unitHeight: 1)
//        let newLadderTemplate = LadderTemplate(name: "New Ladder", description: "New ladder", regionTemplates: [newRegionTemplate])
//        ladderTemplatesController.ladderTemplates.append(newLadderTemplate)
    }
}

fileprivate let testData = [Period(name: "LRI", duration: 400, color: .green, resettable: true), Period(name: "AVD", duration: 200, color: .red, resettable: false)]

struct PeriodListEditor_Previews: PreviewProvider {
    static var previews: some View {
        PeriodListEditor(periods: testData)
    }
}

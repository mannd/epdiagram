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
    let backgroundAlpha = 0.6
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
                            period in NavigationLink(destination: PeriodEditor(period: self.selectedPeriod(id: period.id))) {
                                VStack(alignment: .leading) {
                                        Text("Period: \(period.name)")
                                        Text("Duration: \(Int(period.duration)) msec")
                                    Text("Resettable: \(period.resettable ? "Yes" : "No")")
                                }
                                .padding()
                            }.background(Color(period.color.withAlphaComponent(backgroundAlpha)))
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
        let period = Period()
        periods.append(period)
    }

    private func selectedPeriod(id: UUID) -> Binding<Period> {
        guard let index = self.periods.firstIndex(where: { $0.id == id }) else {
            fatalError("Period doesn't exist.")
        }
        return self.$periods[index]
    }
}

fileprivate let testData = [Period(name: "LRI", duration: 400, color: .green, resettable: true), Period(name: "AVD", duration: 200, color: .red, resettable: false)]

struct PeriodListEditor_Previews: PreviewProvider {
    static var previews: some View {
        PeriodListEditor(periods: testData)
    }
}

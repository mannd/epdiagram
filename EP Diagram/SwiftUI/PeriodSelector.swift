//
//  PeriodSelector.swift
//  EP Diagram
//
//  Created by David Mann on 3/28/22.
//  Copyright © 2022 EP Studios. All rights reserved.
//

import SwiftUI

struct PeriodSelector: View {
    // Show debugging info in selector
    // Will be ignored in release versions
    let debug = false

    let backgroundAlpha = 0.6
    var dismissAction: ((Set<UUID>, Bool) -> Void)?
    @Binding var periods: [Period]
    @State private var editMode = EditMode.inactive
    @State private var selection: Set<UUID> = []
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    #if targetEnvironment(macCatalyst)
    let header_message: String = "Select periods to copy to selected marks.  Hold command to select multiple marks."
    #else
    let header_message: String = "Select periods to copy to selected marks"
    #endif

    var body: some View {
        NavigationView {
            List(selection: $selection) {
                Section(header: Text(header_message)) {
                ForEach(periods, id: \.self.id) { period in
                    VStack(alignment: .leading) {
                        Text("Name: \(period.name)")
                        Text("Duration: \(Int(period.duration)) msec")
                        Text("Resettable: \(period.resettable ? "Yes" : "No")")
                        Text("Offset: \(period.offset)")
                        #if DEBUG
                        debug ? Text("\(period.id)") : nil
                        #endif

                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(period.color.withAlphaComponent(backgroundAlpha)))
                }
                }
            }
            .navigationBarTitle(Text("Select Periods"), displayMode: .inline)
            #if targetEnvironment(macCatalyst)
            .navigationBarItems(leading: backButton)
            #endif
            .environment(\.editMode, .constant(EditMode.active))
            .onDisappear() {
                if let dismissAction = dismissAction {
                    // if not selection, leave periods alone
                    dismissAction(selection, selection.isEmpty)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        }
    }
}

struct PeriodSelector_Previews: PreviewProvider {
    static var testPeriods: [Period] = [Period(), Period(color: .red)]
    static var previews: some View {
        PeriodSelector(periods: .constant(testPeriods))
    }
}

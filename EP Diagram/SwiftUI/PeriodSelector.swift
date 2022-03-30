//
//  PeriodSelector.swift
//  EP Diagram
//
//  Created by David Mann on 3/28/22.
//  Copyright © 2022 EP Studios. All rights reserved.
//

import SwiftUI

struct PeriodSelector: View {
    let backgroundAlpha = 0.6
    var dismissAction: ((Set<UUID>, Bool) -> Void)?
    @Binding var periods: [Period]
    @State private var editMode = EditMode.inactive
    @State private var selection: Set<UUID> = []
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationView {
            List(selection: $selection) {
                Section(header: Text("Select periods to copy to selected marks")) {
                ForEach(periods, id: \.self.id) { period in
                    VStack(alignment: .leading) {
                        Text("Period: \(period.name)")
                        Text("Duration: \(Int(period.duration)) msec")
                        Text("Resettable: \(period.resettable ? "Yes" : "No")")
                        Text("Offset: \(period.offset)")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(period.color.withAlphaComponent(backgroundAlpha)))
                }
                }
            }
            .navigationBarTitle(Text("Select Periods"), displayMode: .inline)
            .environment(\.editMode, .constant(EditMode.active))
            .onDisappear() {
                if let dismissAction = dismissAction {
                    dismissAction(selection, false)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct PeriodSelector_Previews: PreviewProvider {
    static var testPeriods: [Period] = [Period(), Period(color: .red)]
    static var previews: some View {
        PeriodSelector(periods: .constant(testPeriods))
    }
}

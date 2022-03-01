//
//  PeriodEditor.swift
//  EP Diagram
//
//  Created by David Mann on 3/1/22.
//  Copyright © 2022 EP Studios. All rights reserved.
//

import SwiftUI


struct PeriodEditor: View {
    @State var period = Period(name: "Test", duration: 500, color: .blue)

    var body: some View {
        VStack {
        Text("Name = \(period.name)")
        Text("Duration = \(lround(Double(period.duration)))")
            
//        Text(period.color)
        }
    }
}

struct PeriodEditor_Previews: PreviewProvider {
    static var previews: some View {
        PeriodEditor()
    }
}

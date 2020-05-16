//
//  LadderEditor.swift
//  EP Diagram
//
//  Created by David Mann on 5/14/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI
import UIKit
import os.log

extension Region: Identifiable { }

struct LadderEditor: View {
    //    var regions: [String] = []
    @State var ladder: Ladder = Ladder.defaultLadder()
    @State private var editMode = EditMode.inactive

    var body: some View {
        NavigationView {
            List {
                ForEach(ladder.regions, id: \.id) {
                    region in
                    NavigationLink(
                    destination: RegionEditor(region: region)) {
                        HStack {
                            Text(region.name).bold()
                            Spacer()
                            Text(region.description)
                        }
                    }
                }
                .onMove(perform: onMove)
            .onDelete(perform: onDelete)
            }
            .navigationBarTitle("Diagram Regions")
            .navigationBarItems(leading: EditButton(), trailing: addButton)
            .environment(\.editMode, $editMode)
        }
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
        os_log("onAdd - LadderEditor", log: OSLog.action, type: .info)
    }

    private func onDelete(offsets: IndexSet) {
        ladder.regions.remove(atOffsets: offsets)
    }

    private func onMove(source: IndexSet, destination: Int) {
        ladder.regions.move(fromOffsets: source, toOffset: destination)
    }
}



struct LadderEditor_Previews: PreviewProvider {
    static var previews: some View {
        LadderEditor()
    }
}

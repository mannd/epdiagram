//
//  SaveButton.swift
//  EP Diagram
//
//  Created by David Mann on 10/25/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import SwiftUI

struct SaveButton: View {
    var action: ()->Void = {}

    var body: some View {
            Button(action: action, label: {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save Changes")}

            )
            .padding(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(10)
    }
}

struct SaveButton_Previews: PreviewProvider {

    static var previews: some View {
        SaveButton()
    }
}

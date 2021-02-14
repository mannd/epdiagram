//
//  DiagramModelController.swift
//  EP Diagram
//
//  Created by David Mann on 2/13/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import Foundation
import Combine

class DiagramModelController: ObservableObject {
    @Published var diagram: Diagram 

    init(diagram: Diagram) {
        self.diagram = diagram
    }
}

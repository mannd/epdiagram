//
//  Mode.swift
//  EP Diagram
//
//  Created by David Mann on 8/23/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import Foundation

// Mode is used by both DiagramViewController, LadderView and CalipersView.
enum Mode: Int {
    case normal
    case calibrate
    case connect
    case select
}

//
//  Mode.swift
//  EP Diagram
//
//  Created by David Mann on 8/23/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import Foundation

// Mode is used by both DiagramViewController, LadderView and CalipersView.
enum Mode {
    case normal
    case calibrate
    case connect
    case select
    case menu  // a toolbar menu is active
}


//
//  Mode.swift
//  EP Diagram
//
//  Created by David Mann on 8/23/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import Foundation

// Mode is used by both LadderView and CalipersView.
enum Mode {
    case normal
    case calibration
    case connect
    case select
    case menu  // a toolbar menu is active
}


//
//  Mode.swift
//  EP Diagram
//
//  Created by David Mann on 8/23/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import Foundation

/// Mode determines the outcome of touch actions in the various views.
///
/// Mode is used by DiagramViewController, LadderView and CalipersView.
enum Mode: Int {
    case normal
    case calibrate
    case connect
    case select
}

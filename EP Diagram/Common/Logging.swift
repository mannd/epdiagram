//
//  Logging.swift
//  EP Diagram
//
//  Created by David Mann on 4/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

extension OSLog {
    static let subsystem = Bundle.main.bundleIdentifier!

    static let viewCycle = OSLog(subsystem: OSLog.subsystem, category: "viewcycle")
    static let action = OSLog(subsystem: OSLog.subsystem, category: "actions")
    static let debugging = OSLog(subsystem: OSLog.subsystem, category: "debugging")
    static let touches = OSLog(subsystem: OSLog.subsystem, category: "touches")
}

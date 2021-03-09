//
//  Logging.swift
//  EP Diagram
//
//  Created by David Mann on 4/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import OSLog

extension OSLog {
    static let subsystem = Bundle.main.bundleIdentifier!

    static let viewCycle = OSLog(subsystem: OSLog.subsystem, category: "viewcycle")
    static let action = OSLog(subsystem: OSLog.subsystem, category: "actions")
    static let debugging = OSLog(subsystem: OSLog.subsystem, category: "debugging")
    static let touches = OSLog(subsystem: OSLog.subsystem, category: "touches")
    static let errors = OSLog(subsystem: OSLog.subsystem, category: "errors")
    static let hamburgerCycle = OSLog(subsystem: subsystem, category: "hamburger")
    static let lifeCycle = OSLog(subsystem: subsystem, category: "lifecycle")
    static let test = OSLog(subsystem: subsystem, category: "test")
    static let deprecated = OSLog(subsystem: subsystem, category: "deprecated")
}

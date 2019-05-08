//
//  Mark.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import Foundation


class Mark {
    enum Origin {
        case atStart
        case atEnd
        case notOrigin
    }

    public var startPosition: Double?
    public var endPosition: Double?
    public var selected: Bool = false
    public var origin: Origin = .notOrigin

}

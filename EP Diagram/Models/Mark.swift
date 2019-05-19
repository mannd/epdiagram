//
//  Mark.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import Foundation

// A Mark is the little line drawn on the ladder, such as the vertical line for
// atrial activation.  It isn't necessarily vertical, as in the AV region, so it
// has a start and end position.  The Mark only cares about its horizontal positioning;
// Regions care about vertical positioning.  A Mark represent the origin of an impulse.
// Presumably start and end positions are top to bottom.
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

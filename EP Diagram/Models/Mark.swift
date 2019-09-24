//
//  Mark.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

// We import UIKit here and elsewhere to use CGFloat and avoid conversions
// of Double to CGFloat.
import UIKit

//  See this attempt at a ladder diagram program, the only one I can find: https://epfellow.wordpress.com/2010/11/04/electrocardiogram-ecgekg-ladder-diagrams/


struct MarkPosition {
    var origin: CGPoint
    var terminus: CGPoint

//    init(origin: CGPoint, terminus: CGPoint) {
//        self.origin = origin
//        self.terminus = terminus
//    }

}

/**
 The mark is a fundamental component of a ladder diagram.

 A mark can be many things, which makes the concept difficult to pin down.  It can be conduction through a region, with or without decrement.  Conduction can originate  in a region, at the top, bottom, or somewhere in the middle, or may originate in another region.  A mark can block or conduct. It can reenter, spawning another mark.

 After much back and forth on terminology, it seems that the two ends of a mark should be defined by the time axis.  Thus a mark always has one end that is theoretically earlier in time than the other.  These points are the *origin* and *terminus* of the mark.  Each of these points is defined by an x position in time (based on the unzzomed, non-offset ECG image) and a y position in the region.  The y position is not a specific location on the y axis, rather it is a float from 0 to 1.0, where 0 is the most proximal part of the region, and 1.0 is the most distal.  the LadderViewModel converts these point coordinates to actual coordinates, depending on the height of the regions and the zoom and offset factors of the ECG image.
*/
class Mark {
    /// Draw a solid or dashed line when drawing a mark.
    enum LineStyle {
        case solid
        case dashed
    }

    /// Whether cursor is shown and if so is linked to the origin or terminus of thef mark, or to the mark as a whole (positional).
    enum CursorType {
        case origin
        case terminus
        case positional
        case none
    }

    /// If a mark is an impulse origin and properties indicate show this, a dot of some sort with appear at the origin of the mark.
    var isImpulseOrigin: Bool = false
    var position: MarkPosition

    // TODO: Need to support multiple selection and copy features from one mark to a group of selected marks.
    var selected: Bool = false {
        didSet {
            print("selected set and = \(selected)")
        }
    }
    var hasCursor: Bool = false
    var attached: Bool = false


    init() {
        position = MarkPosition(origin: CGPoint.zero, terminus: CGPoint.zero)
    }

}

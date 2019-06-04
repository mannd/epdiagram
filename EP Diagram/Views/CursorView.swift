//
//  CursorView.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class CursorView: UIView {
    var cursor: Cursor = Cursor(position: 100)

    override func draw(_ rect: CGRect) {
        // Drawing code
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.magenta.cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: 100, y: 0))
            context.addLine(to: CGPoint(x: 100, y: rect.height))
            context.strokePath()
        }
    }

    // This function passes touch events to the views below if the point is not
    // near the cursor.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if cursor.isNearCursor(point: point) {
            return true
        }
        return false
    }
}

//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class LadderView: UIView {
    public var lineXPosition: Double = 0.0
    public var scrollViewBounds = CGRect(x: 0, y: 0 , width: 0, height: 0)

    let margin: CGFloat = 50

    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: lineXPosition, y: 0.0))
            context.addLine(to: CGPoint(x: lineXPosition, y: Double(bounds.height)))
            context.strokePath()
            context.setStrokeColor(UIColor.red.cgColor)
            context.move(to: CGPoint(x: margin + scrollViewBounds.origin.x, y: 0))
            context.addLine(to: CGPoint(x: margin + scrollViewBounds.origin.x, y: bounds.height))
            context.strokePath()
            // TODO: draw line at other margin
            context.move(to: CGPoint(x: scrollViewBounds.width + scrollViewBounds.origin.x - margin, y: 0))
            context.addLine(to: CGPoint(x: scrollViewBounds.width + scrollViewBounds.origin.x - margin, y: bounds.height))
            context.strokePath()
        }
    }

}

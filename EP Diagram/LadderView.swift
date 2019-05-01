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

    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: lineXPosition, y: 0.0))
            context.addLine(to: CGPoint(x: lineXPosition, y: Double(bounds.height)))
            context.strokePath()
        }
    }

}

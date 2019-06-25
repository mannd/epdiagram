//
//  CursorView.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

protocol MarkDelegate {
    func makeMark(location: CGFloat)
    func deleteMark(location: CGFloat)
}

class CursorView: UIView {
    var cursor: Cursor = Cursor(position: 100)
    var delegate: MarkDelegate?
    var height: CGFloat = 0

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTapRecognizer)
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        self.addGestureRecognizer(doubleTapRecognizer)
        let draggingPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.dragging))
        self.addGestureRecognizer(draggingPanRecognizer)
    }

    override func draw(_ rect: CGRect) {
        // Drawing code
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.magenta.cgColor)
            context.setLineWidth(1)
            context.setAlpha(0.8)
            context.move(to: CGPoint(x: cursor.position, y: 0))
            context.addLine(to: CGPoint(x: cursor.position, y: rect.height))
            context.strokePath()
        }
    }

    // This function passes touch events to the views below if the point is not
    // near the cursor.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if cursor.isNearCursor(point: point) {
            NSLog("Near point")
            return true
        }
        return false
    }

    @objc func singleTap(tap: UITapGestureRecognizer) {
        NSLog("Single tap")
        // position Mark
        // temp draw A mark
        delegate?.makeMark(location: cursor.position)

    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        NSLog("Double tap")
        // delete Mark
        delegate?.deleteMark(location: cursor.position)
    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        NSLog("Panning")
        // drag Mark
        let delta = pan.translation(in: self)
        cursor.move(delta: delta)
        pan.setTranslation(CGPoint(x: 0,y: 0), in: self)
        setNeedsDisplay()
    }
}

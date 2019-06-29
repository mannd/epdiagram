//
//  CursorView.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

protocol LadderDelegate {
    func makeMark(location: CGFloat)
    func deleteMark(location: CGFloat)
    func getMarkStartPositionInView(_ view: UIView) -> CGFloat
}

class CursorView: UIView {
    var cursor: Cursor = Cursor(position: 100)
    var cursorViewModel: CursorViewModel?
    var delegate: LadderDelegate?
    var leftMargin: CGFloat {
        set(value) {
            cursorViewModel?.leftMargin = value
        }
        get {
            return cursorViewModel?.leftMargin ?? 0
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initCursorViewModel()
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

    func initCursorViewModel() {
        cursorViewModel = CursorViewModel(cursor: cursor, leftMargin: leftMargin, width: self.frame.width, height: 0)
    }

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            cursorViewModel?.height = delegate?.getMarkStartPositionInView(self) ?? self.frame.height
            cursorViewModel?.draw(rect: rect, context: context)
        }
    }

    // This function passes touch events to the views below if the point is not
    // near the cursor.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if cursor.isNearCursor(point: point) && point.y < delegate?.getMarkStartPositionInView(self) ?? self.frame.height {
            NSLog("Near cursor")
            return true
        }
        return false
    }

    @objc func singleTap(tap: UITapGestureRecognizer) {
        NSLog("Single tap on cursor")
        // position Mark
        // temp draw A mark
        delegate?.makeMark(location: cursor.position)

    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        NSLog("Double tap on cursor")
        // delete Mark
        delegate?.deleteMark(location: cursor.position)
    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        NSLog("Panning cursor")
        // drag Cursor
        let delta = pan.translation(in: self)
        cursor.move(delta: delta)
        pan.setTranslation(CGPoint(x: 0,y: 0), in: self)
        setNeedsDisplay()
    }
}

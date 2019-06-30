//
//  CursorView.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

protocol LadderViewDelegate: AnyObject {
    func ladderViewMakeMark(location: CGFloat)
    func ladderViewDeleteMark(location: CGFloat)
    func ladderViewGetMarkStartPosition(view: UIView) -> CGFloat
}

class CursorView: UIView, CursorViewDelegate {
    var cursor: Cursor = Cursor()
    var grabbedMark: Mark?
    var cursorViewModel: CursorViewModel?
    weak var delegate: LadderViewDelegate?
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
        reset()
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

    func reset() {
        cursorViewModel = CursorViewModel(cursor: cursor, leftMargin: leftMargin, width: self.frame.width, height: 0)
    }

    func cursorViewRefresh() {
        setNeedsDisplay()
    }

    func cursorViewGrabMark(mark: Mark?) {
        guard let mark = mark else { return }
        grabbedMark = mark
        print("Mark grabbed!")
    }

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            cursorViewModel?.height = delegate?.ladderViewGetMarkStartPosition(view: self) ?? self.frame.height
            cursorViewModel?.draw(rect: rect, context: context)
        }
    }

    // This function passes touch events to the views below if the point is not
    // near the cursor.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if cursor.isNearCursor(point: point) && point.y < delegate?.ladderViewGetMarkStartPosition(view: self) ?? self.frame.height {
            NSLog("Near cursor")
            return true
        }
        return false
    }

    @objc func singleTap(tap: UITapGestureRecognizer) {
        NSLog("Single tap on cursor")
        // position Mark
        // temp draw A mark
        delegate?.ladderViewMakeMark(location: cursor.position)

    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        NSLog("Double tap on cursor")
        // delete Mark
        delegate?.ladderViewDeleteMark(location: cursor.position)
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

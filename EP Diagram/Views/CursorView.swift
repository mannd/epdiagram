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
    func ladderViewGetRegionUpperBoundary(view: UIView) -> CGFloat
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

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            cursorViewModel?.height = delegate?.ladderViewGetRegionUpperBoundary(view: self) ?? self.frame.height
            cursorViewModel?.draw(rect: rect, context: context)
        }
    }

    // This function passes touch events to the views below if the point is not
    // near the cursor.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if cursor.isNearCursor(point: point) && point.y < delegate?.ladderViewGetRegionUpperBoundary(view: self) ?? self.frame.height {
            print("Near cursor")
            return true
        }
        return false
    }

    @objc func singleTap(tap: UITapGestureRecognizer) {
        print("Single tap on cursor")
        // position Mark
        // temp draw A mark
        delegate?.ladderViewMakeMark(location: cursor.location)

    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        print("Double tap on cursor")
        // delete Mark
        delegate?.ladderViewDeleteMark(location: cursor.location)
    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        print("Panning cursor")
        // drag Cursor
        let delta = pan.translation(in: self)
        cursor.move(delta: delta)
        if let grabbedMark = grabbedMark {
            print("Move grabbed Mark")
            //delegate?.ladderViewMoveMark(mark: grabbedMark, location: cursor.position)
            //delegate?.ladderViewNeedsDisplay()
        }
        pan.setTranslation(CGPoint(x: 0,y: 0), in: self)
        setNeedsDisplay()
    }

    // MARK: - CursorView delegate methods
    func cursorViewRefresh() {
        setNeedsDisplay()
    }

    func cursorViewGrabMark(mark: Mark?) {
        guard let mark = mark else { return }
        grabbedMark = mark
        print("Mark grabbed!")
    }

    func cursorViewMoveCursor(location: CGFloat) {
        cursor.location = location
    }

    func cursorViewRecenterCursor() {
        // TODO: Deal with mark already in center, so cursor doesn't move:
        // Possible solutions:
        //    Test for this situation and move cursor elsewhere
        //    Move cursor set distance from mark in either direction
        //    Change color of grabbed vs released cursor (and change mark color too?)
        //    Combination of above.
        cursorViewModel?.centerCursor()
    }

    func cursorViewHighlightCursor(_ on: Bool) {
        if on {
            cursorViewModel?.color = UIColor.blue
        }
        else {
            cursorViewModel?.color = UIColor.magenta
        }
    }

}

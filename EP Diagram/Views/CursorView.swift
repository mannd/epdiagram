//
//  CursorView.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

protocol LadderViewDelegate: AnyObject {
    func ladderViewMakeMark(location: CGFloat) -> Mark?
    func ladderViewDeleteMark(location: CGFloat)
    func ladderViewDeleteMark(mark: Mark)
    func ladderViewGetRegionUpperBoundary(view: UIView) -> CGFloat
    func ladderViewMoveMark(mark: Mark, location: CGFloat)
    func ladderViewRefresh()
}

class CursorView: UIView, CursorViewDelegate {
    var cursor: Cursor = Cursor()
    var attachedMark: Mark?
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
        self.isOpaque = false
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
            // FIXME: draw rect temporarily
            context.setFillColor(UIColor.black.cgColor)
            let testRect = CGRect(x: 20, y: 20, width: 100, height: 100)
            context.addRect(testRect)
            context.drawPath(using: .fillStroke)
        }
    }

    // This function passes touch events to the views below if the point is not
    // near the cursor.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Hidden cursor shouldn't interfere with touches.
        guard cursor.state != .hidden else { return false }
        if cursor.isNearCursor(point: point) && point.y < delegate?.ladderViewGetRegionUpperBoundary(view: self) ?? self.frame.height {
            return true
        }
        return false
    }

    @objc func singleTap(tap: UITapGestureRecognizer) {
        print("Single tap on cursor")
        // Logic here is single tap adds mark if no mark attached.
        // If mark attached, release mark
        if attachedMark != nil {
            cursorViewUnattachMark()
            attachedMark?.selected = false
            attachedMark?.attached = false
            cursorViewHighlightCursor(false)
            delegate?.ladderViewRefresh()
            setNeedsDisplay()
        }
        else { // create mark and attach it
            // FIXME: Don't create marks on top of each other.  If a mark exists
            // with within "accuracy" points, just attach to it.
            let mark = delegate?.ladderViewMakeMark(location: cursor.location)
            mark?.selected = true
            mark?.attached = true
            cursorViewHighlightCursor(true)
            cursorViewAttachMark(mark: mark)
            delegate?.ladderViewRefresh()
            setNeedsDisplay()
        }
    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        print("Double tap on cursor")
        // delete attached Mark
        if let attachedMark = attachedMark {
            delegate?.ladderViewDeleteMark(mark: attachedMark)
            cursorViewHighlightCursor(false)
            delegate?.ladderViewRefresh()
            setNeedsDisplay()
        }
    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        print("Panning cursor")
        // FIXME: Move this to dragging in LadderView
//        let vel: CGPoint = pan.velocity(in: self)
//        if vel.x > 1.0 {
//            print("Panning to right")
//        }
//        else if vel.x < 1.0 {
//            print("Panning to left")
//        }
//        if vel.y > 1.0 {
//            print("Panning down")
//        }
//        else if vel.y < 1.0 {
//            print("Panning up")
//        }

        // drag Cursor
        let delta = pan.translation(in: self)
        cursor.move(delta: delta)
        if let attachedMark = attachedMark {
            print("Move grabbed Mark")
            delegate?.ladderViewMoveMark(mark: attachedMark, location: cursor.location)
            delegate?.ladderViewRefresh()
        }
        pan.setTranslation(CGPoint(x: 0,y: 0), in: self)
        setNeedsDisplay()
    }

    // MARK: - CursorView delegate methods
    func cursorViewRefresh() {
        setNeedsDisplay()
    }

    func cursorViewAttachMark(mark: Mark?) {
        guard let mark = mark else { return }
        attachedMark = mark
        print("Mark attached!")
    }

    func cursorViewUnattachMark() {
        attachedMark = nil
        print("Mark unattached!")
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
            cursorViewModel?.cursorState = .attached
        }
        else {
            cursorViewModel?.cursorState = .unattached
        }
    }

    func cursorViewHideCursor(hide: Bool) {
        if hide {
            cursor.state = .hidden
        }
        else {
            cursor.state = .unattached
        }
    }

}

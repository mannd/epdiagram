//
//  CursorView.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

protocol CursorViewDelegate: AnyObject {
    func refresh()
    func attachMark(mark: Mark?)
    func unattachMark()
    func moveCursor(location: CGFloat)
    func recenterCursor()
    func highlightCursor(_ on: Bool)
    func hideCursor(hide: Bool)
    func cursorIsVisible() -> Bool
    func setAnchor(anchor: Cursor.Anchor)
}

class CursorView: UIView, CursorViewDelegate {
    var attachedMark: Mark?
    var cursorViewModel: CursorViewModel = CursorViewModel()
    weak var ladderViewDelegate: LadderViewDelegate?
    var leftMargin: CGFloat = 0 {
        didSet {
            cursorViewModel.leftMargin = leftMargin
        }
    }
    var scale: CGFloat = 1.0
    var contentOffset: CGFloat = 0
    let accuracy: CGFloat = 20
    var calibrating = false

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isOpaque = false
        cursorViewModel = CursorViewModel(leftMargin: leftMargin, width: self.frame.width, height: 0)

        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTapRecognizer)
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        self.addGestureRecognizer(doubleTapRecognizer)
        let draggingPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.dragging))
        self.addGestureRecognizer(draggingPanRecognizer)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress))
        self.addGestureRecognizer(longPressRecognizer)

    }

    override func draw(_ rect: CGRect) {
        print("CursorView draw()")
        if let context = UIGraphicsGetCurrentContext() {
            cursorViewModel.height = getCursorHeight(anchor: cursorViewModel.cursor.anchor)
            cursorViewModel.draw(rect: rect, scale: scale, offset: contentOffset, context: context)
        }
    }

    private func getCursorHeight(anchor: Cursor.Anchor) -> CGFloat {
        switch anchor {
        case .proximal:
            return ladderViewDelegate?.getRegionUpperBoundary(view: self) ?? self.frame.height
        case .middle:
            return ladderViewDelegate?.getRegionMidPoint(view: self) ?? self.frame.height
        case .distal:
            return ladderViewDelegate?.getRegionLowerBoundary(view: self) ?? self.frame.height
        case .none:
            return ladderViewDelegate?.getHeight() ?? self.frame.height
        }
    }

    // This function passes touch events to the views below if the point is not
    // near the cursor.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Hidden cursor shouldn't interfere with touches.
        // TODO: However, scrollview must deal with single tap and create cursor via a delegate.
        guard cursorViewModel.cursor.visible else { return false }
        if isNearCursor(location: point.x, cursor: cursorViewModel.cursor) && point.y < ladderViewDelegate?.getRegionUpperBoundary(view: self) ?? self.frame.height {
            print("near cursor")
            return true
        }
        return false
    }

    func isNearCursor(location: CGFloat, cursor: Cursor) -> Bool {
        return location < translateToRelativeLocation(location: cursor.location, offset: contentOffset, scale: scale) + accuracy
            && location > translateToRelativeLocation(location: cursor.location, offset: contentOffset, scale: scale) - accuracy
    }


    @objc func singleTap(tap: UITapGestureRecognizer) {
        print("Single tap on cursor")
        if calibrating {
            doCalibration()
            return
        }
        // toggle hide or show cursor with single tap
        hideCursor(hide: cursorViewModel.cursorVisible)
        unattachMark()
        setNeedsDisplay()
    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        print("Double tap on cursor")
        // delete attached Mark
        if let attachedMark = attachedMark {
            ladderViewDelegate?.deleteMark(mark: attachedMark)
            ladderViewDelegate?.refresh()
        }
        hideCursor(hide: true)
        setNeedsDisplay()
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
        // Adjust movement to scale
        cursorViewModel.cursor.move(delta: delta.x / scale)
        if let attachedMark = attachedMark {
            print("Move attached Mark")
            switch cursorViewModel.cursor.anchor {
            case .proximal:
                attachedMark.cursorType = .proximal
            case .middle:
                attachedMark.cursorType = .all
            case .distal:
                attachedMark.cursorType = .distal
            case .none:
                attachedMark.cursorType = .none
            }
            ladderViewDelegate?.moveMark(mark: attachedMark, location: translateToRelativeLocation(location: cursorViewModel.cursor.location, offset: contentOffset, scale: scale), moveCursor: false)
            ladderViewDelegate?.refresh()
        }
        pan.setTranslation(CGPoint(x: 0,y: 0), in: self)
        setNeedsDisplay()
    }

    @objc func longPress(press: UILongPressGestureRecognizer) {
        print("Long press on caliper")
    }

    func doCalibration() {
        print("Do calibration")
    }


    func putCursor(location: CGFloat) {
        print("Cursor location = \(location)")
        // 
        cursorViewModel.cursor.location = location / scale
        hideCursor(hide: false)
    }

    // MARK: - CursorView delegate methods
    func refresh() {
        setNeedsDisplay()
    }

    func attachMark(mark: Mark?) {
        guard let mark = mark else { return }
        attachedMark = mark
        mark.attached = true
        mark.highlight = .all
        print("Mark attached!")
    }

    func unattachMark() {
        if let mark = attachedMark {
            mark.attached = false
            mark.highlight = .none
            ladderViewDelegate?.refresh()
        }
        attachedMark = nil
        print("Mark unattached!")
    }

    func moveCursor(location: CGFloat) {
        cursorViewModel.cursor.location = location
    }

    func recenterCursor() {
        // TODO: Deal with mark already in center, so cursor doesn't move:
        // Possible solutions:
        //    Test for this situation and move cursor elsewhere
        //    Move cursor set distance from mark in either direction
        //    Change color of grabbed vs released cursor (and change mark color too?)
        //    Combination of above.
        cursorViewModel.centerCursor()
    }

    func highlightCursor(_ on: Bool) {
        if on {
            cursorViewModel.cursorState = .attached
        }
        else {
            cursorViewModel.cursorState = .unattached
        }
    }

    func hideCursor(hide: Bool) {
        cursorViewModel.cursorVisible = !hide
    }

    func cursorIsVisible() -> Bool {
        return cursorViewModel.cursorVisible
    }

    func setAnchor(anchor: Cursor.Anchor) {
        print("CursorView set anchor to \(anchor)")
        cursorViewModel.cursor.anchor = anchor
    }

}

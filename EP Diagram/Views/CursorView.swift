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
    func moveCursor(positionX: CGFloat)
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
    var scale: CGFloat = 1.0 {
        didSet {
            cursorViewModel.scale = scale
        }
    }
    var offset: CGFloat = 0 {
        didSet {
            cursorViewModel.offset = offset
        }
    }
    let accuracy: CGFloat = 20
    var calibrating = false

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isOpaque = false
        self.layer.masksToBounds = true
        if #available(iOS 13.0, *) {
            self.layer.borderColor = UIColor.label.cgColor
        } else {
            self.layer.borderColor = UIColor.black.cgColor
        }
        self.layer.borderWidth = 1

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
        P("CursorView draw()")
        if let context = UIGraphicsGetCurrentContext() {
            cursorViewModel.height = getCursorHeight(anchor: attachedMark?.anchor ?? .none)
            cursorViewModel.draw(rect: rect, context: context, defaultHeight: ladderViewDelegate?.getTopOfLadder(view: self))
        }
    }

    private func getCursorHeight(anchor: Anchor) -> CGFloat {
        switch anchor {
        case .proximal:
            return ladderViewDelegate?.getRegionProximalBoundary(view: self) ?? self.frame.height
        case .middle:
            return ladderViewDelegate?.getRegionMidPoint(view: self) ?? self.frame.height
        case .distal:
            return ladderViewDelegate?.getRegionDistalBoundary(view: self) ?? self.frame.height
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
        if isNearCursor(positionX: point.x, cursor: cursorViewModel.cursor) && point.y < ladderViewDelegate?.getRegionProximalBoundary(view: self) ?? self.frame.height {
            P("near cursor")
            return true
        }
        return false
    }

    func isNearCursor(positionX: CGFloat, cursor: Cursor) -> Bool {
        cursorViewModel.isNearCursor(positionX: positionX, cursor: cursor, accuracy: accuracy)
    }


    // FIXME: This is overriden in ViewController.
    // TODO: Need to move all touches to ViewController.
    @objc func singleTap(tap: UITapGestureRecognizer) {
        P("Single tap on cursor")
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
        P("Double tap on cursor")
        // delete attached Mark
        if let attachedMark = attachedMark {
            ladderViewDelegate?.deleteMark(mark: attachedMark)
            ladderViewDelegate?.refresh()
        }
        hideCursor(hide: true)
        setNeedsDisplay()
    }

    func doubleTapHandler(tap: UITapGestureRecognizer) {
        P("Double tap handler")
        // delete attached Mark
        if let attachedMark = attachedMark {
            ladderViewDelegate?.deleteMark(mark: attachedMark)
            ladderViewDelegate?.refresh()
        }
        hideCursor(hide: true)
        setNeedsDisplay()
    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        P("Panning cursor")
        // FIXME: Move this to dragging in LadderView
//        let vel: CGPoint = pan.velocity(in: self)
//        if vel.x > 1.0 {
//            PRINT("Panning to right")
//        }
//        else if vel.x < 1.0 {
//            PRINT("Panning to left")
//        }
//        if vel.y > 1.0 {
//            PRINT("Panning down")
//        }
//        else if vel.y < 1.0 {
//            PRINT("Panning up")
//        }

        // drag Cursor
        if pan.state == .changed {
            let delta = pan.translation(in: self)
            // Adjust movement to scale
            cursorViewModel.cursor.move(delta: delta.x / scale)
            if let attachedMark = attachedMark {
                P("Move attached Mark")
                ladderViewDelegate?.moveMark(mark: attachedMark, position: CGPoint(x: Common.translateToRelativePositionX(positionX: cursorViewModel.cursor.position, offset: offset, scale: scale), y: 0), moveCursor: false)
                ladderViewDelegate?.refresh()
            }
            pan.setTranslation(CGPoint(x: 0,y: 0), in: self)
            setNeedsDisplay()
        }
        if pan.state == .ended {
            if let attachedMark = attachedMark {
                ladderViewDelegate?.linkNearbyMarks(mark: attachedMark)
                ladderViewDelegate?.refresh()
                setNeedsDisplay()
            }
        }
    }

    @objc func longPress(press: UILongPressGestureRecognizer) {
        P("Long press on caliper")
    }

    func doCalibration() {
        P("Do calibration")
    }


    func putCursor(positionX: CGFloat) {
        P("Cursor positionX = \(positionX)")
        // 
        cursorViewModel.cursor.position = positionX / scale
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
        P("Mark attached!")
    }

    func unattachMark() {
        if let mark = attachedMark {
            mark.attached = false
            mark.highlight = .none
            ladderViewDelegate?.refresh()
        }
        attachedMark = nil
        P("Mark unattached!")
    }

    func moveCursor(positionX: CGFloat) {
        P("Move cursor")
        cursorViewModel.cursor.position = positionX
    }

    // FIXME: Not called by anyone.
    func recenterCursor() {
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
        P("CursorView set anchor to \(anchor)")
        cursorViewModel.cursor.anchor = anchor
    }

}

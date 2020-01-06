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
    func attachMark(_: Mark?)
    func unattachMark()
    func moveCursor(positionX: CGFloat)
    func recenterCursor()
    func highlightCursor(_ on: Bool)
    func hideCursor(hide: Bool)
    func cursorIsVisible() -> Bool
    func setAnchor(anchor: Cursor.Anchor)
}

class CursorView: UIView, CursorViewDelegate {
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

    // How close a tap has to be to a cursor to register.
    let accuracy: CGFloat = 20
    var calibrating = false

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        didLoad()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        didLoad()
    }

    fileprivate func didLoad() {
        // CursorView is mostly transparent, so let iOS know.
        self.isOpaque = false

        // Draw a border around the view.
        self.layer.masksToBounds = true
        if #available(iOS 13.0, *) {
            self.layer.borderColor = UIColor.label.cgColor
        } else {
            self.layer.borderColor = UIColor.black.cgColor
        }
        self.layer.borderWidth = 1

        cursorViewModel = CursorViewModel(leftMargin: leftMargin, width: self.frame.width, height: self.frame.width)

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
        if let context = UIGraphicsGetCurrentContext() {
            cursorViewModel.height = getCursorHeight(anchor: cursorViewModel.getAttachedMarkAnchor())
            cursorViewModel.draw(rect: rect, context: context, defaultHeight: ladderViewDelegate?.getTopOfLadder(view: self))
        }
    }

    private func getCursorHeight(anchor: Anchor) -> CGFloat {
        guard let ladderViewDelegate = ladderViewDelegate else { return self.frame.height }
        switch anchor {
        case .proximal:
            return ladderViewDelegate.getRegionProximalBoundary(view: self)
        case .middle:
            return ladderViewDelegate.getRegionMidPoint(view: self)
        case .distal:
            return ladderViewDelegate.getRegionDistalBoundary(view: self)
        case .none:
            return ladderViewDelegate.getHeight()
        }
    }

    // This function passes touch events to the views below if the point is not
    // near the cursor.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard cursorViewModel.cursorVisible, let ladderViewDelegate = ladderViewDelegate else { return false }
        if cursorViewModel.isNearCursor(positionX: point.x, accuracy: accuracy) && point.y < ladderViewDelegate.getRegionProximalBoundary(view: self) {
            return true
        }
        return false
    }

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
        if let attachedMark = cursorViewModel.attachedMark {
            ladderViewDelegate?.deleteMark(attachedMark)
            ladderViewDelegate?.refresh()
        }
        hideCursor(hide: true)
        setNeedsDisplay()
    }

    func doubleTapHandler(tap: UITapGestureRecognizer) {
        P("Double tap handler")
        // delete attached Mark
        if let attachedMark = cursorViewModel.attachedMark {
            ladderViewDelegate?.deleteMark(attachedMark)
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
            cursorViewModel.cursorMove(delta: delta.x)
            if let attachedMark = cursorViewModel.attachedMark {
                P("Move attached Mark")
                ladderViewDelegate?.moveMark(mark: attachedMark, position: CGPoint(x: Common.translateToRelativePositionX(positionX: cursorViewModel.cursorPosition, offset: offset, scale: scale), y: 0), moveCursor: false)
                ladderViewDelegate?.refresh()
            }
            pan.setTranslation(CGPoint(x: 0,y: 0), in: self)
            setNeedsDisplay()
        }
        if pan.state == .ended {
            if let attachedMark = cursorViewModel.attachedMark {
                ladderViewDelegate?.linkNearbyMarks(mark: attachedMark)
                ladderViewDelegate?.refresh()
                setNeedsDisplay()
            }
        }
    }

    @objc func longPress(press: UILongPressGestureRecognizer) {
        P("Long press on cursor")
    }

    func doCalibration() {
        P("Do calibration")
    }


    func putCursor(positionX: CGFloat) {
        cursorViewModel.cursorPosition = positionX / scale
        hideCursor(hide: false)
    }

    // MARK: - CursorView delegate methods
    func refresh() {
        setNeedsDisplay()
    }

    func attachMark(_ mark: Mark?) {
        cursorViewModel.attachMark(mark: mark)
    }

    func unattachMark() {
        if cursorViewModel.unattachMark() {
            ladderViewDelegate?.refresh()
        }
    }

    func moveCursor(positionX: CGFloat) {
        P("Move cursor")
        cursorViewModel.cursorPosition = positionX
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
        cursorViewModel.cursorAnchor = anchor
    }

    func attachMark(positionX: CGFloat) {
        let mark = ladderViewDelegate?.addMark(positionX: positionX)
        attachMark(mark)
    }

}

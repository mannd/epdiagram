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
    func attachMark(_ mark: Mark?)
    func unattachAttachedMark()
    func moveCursor(cursorViewPositionX positionX: CGFloat)
    func hideCursor(_ hide: Bool)
    func cursorIsVisible() -> Bool
}

final class CursorView: ScaledView {
    private let rightMargin: CGFloat = 5 // unused?
    private let alphaValue: CGFloat = 0.8
    private let accuracy: CGFloat = 20 // How close a tap has to be to a cursor to register.

    // parameters that will eventually be preferences
    var lineWidth: CGFloat = 2
    var color: UIColor = UIColor.systemBlue

    private var cursor: Cursor
    private var attachedMark: Mark?

    var leftMargin: CGFloat = 0

    weak var ladderViewDelegate: LadderViewDelegate?

    var calibrating = false

    // MARK: - init

    required init?(coder: NSCoder) {
        self.cursor = Cursor()
        self.cursor.visible = false
        super.init(coder: coder)
        didLoad()
    }

    override init(frame: CGRect) {
        self.cursor = Cursor()
        self.cursor.visible = false
        super.init(frame: frame)
        didLoad()
    }

    private func didLoad() {
        self.isOpaque = false // CursorView is mostly transparent, so let iOS know.

        self.layer.masksToBounds = true // Draw a border around the view.
        if #available(iOS 13.0, *) {
            self.layer.borderColor = UIColor.label.cgColor
        } else {
            self.layer.borderColor = UIColor.black.cgColor
        }
        self.layer.borderWidth = 1

        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTapRecognizer)

        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        self.addGestureRecognizer(doubleTapRecognizer)

        let draggingPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.drag))
        self.addGestureRecognizer(draggingPanRecognizer)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress))
        self.addGestureRecognizer(longPressRecognizer)
    }

    // MARK: - draw

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            guard cursor.visible, let cursorHeight = getCursorHeight(anchor: getAttachedMarkAnchor()) else { return }

            let cursorDefaultHeight = ladderViewDelegate?.getTopOfLadder(view: self)
            let position = scale * cursor.position - offsetX // inlined, for efficiency
            let defaultHeight = cursorDefaultHeight ?? cursorHeight
            let height = (position <= leftMargin) ? defaultHeight : cursorHeight
            let endPoint = CGPoint(x: position, y: height)

            context.setStrokeColor(color.cgColor)
            context.setLineWidth(lineWidth)
            context.setAlpha(alphaValue)
            context.move(to: CGPoint(x: position, y: 0))
            context.addLine(to: endPoint)
            context.strokePath()
            if position > leftMargin {
                drawCircle(context: context, center: endPoint, radius: 5)
            }
        }
    }

    // Add tiny circle around intersection of cursor and mark.
    private func drawCircle(context: CGContext, center: CGPoint, radius: CGFloat) {
        context.addArc(center: center, radius: radius, startAngle: 0.0, endAngle: .pi * 2.0, clockwise: true)
        context.strokePath()
    }

    func getAttachedMarkAnchor() -> Anchor {
        guard let attachedMark = attachedMark else { return .none }
        return attachedMark.anchor
    }

    private func getAnchorPositionY(_ anchor: Anchor, _ ladderViewDelegate: LadderViewDelegate) -> CGFloat? {
        let anchorY: CGFloat?
        switch anchor {
        case .proximal:
            anchorY = ladderViewDelegate.getRegionProximalBoundary(view: self)
        case .middle:
            anchorY = ladderViewDelegate.getRegionMidPoint(view: self)
        case .distal:
            anchorY = ladderViewDelegate.getRegionDistalBoundary(view: self)
        case .none:
            anchorY = nil
        }
        return anchorY
    }

    private func getCursorHeight(anchor: Anchor) -> CGFloat? {
        guard let ladderViewDelegate = ladderViewDelegate else { return nil }
        return getAnchorPositionY(anchor, ladderViewDelegate)
    }

    // MARK: - touches

    // This function passes touch events to the views below if the point is not
    // near the cursor.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard cursor.visible, let ladderViewDelegate = ladderViewDelegate else { return false }
        if isNearCursor(positionX: point.x, accuracy: accuracy) && point.y < ladderViewDelegate.getRegionProximalBoundary(view: self) {
            return true
        }
        return false
    }

    func isNearCursor(positionX: CGFloat, accuracy: CGFloat) -> Bool {
        return positionX < translateToScaledViewPositionX(regionPositionX: cursor.position) + accuracy && positionX > translateToScaledViewPositionX(regionPositionX: cursor.position) - accuracy
    }

    @objc func singleTap(tap: UITapGestureRecognizer) {
        if calibrating {
            doCalibration()
            return
        }
        hideCursor(cursor.visible)
        unattachAttachedMark()
        ladderViewDelegate?.refresh()
        setNeedsDisplay()
    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        if let attachedMark = attachedMark {
            ladderViewDelegate?.deleteMark(attachedMark)
            cursor.visible = false
            ladderViewDelegate?.refresh()
            setNeedsDisplay()
        }
    }

    @objc func drag(pan: UIPanGestureRecognizer) {
        if pan.state == .changed {
            let delta = pan.translation(in: self)
            cursorMove(delta: delta.x)
            dragMark(ladderViewDelegate: ladderViewDelegate)
            pan.setTranslation(CGPoint(x: 0,y: 0), in: self)
        }
        if pan.state == .ended {
            if let attachedMark = attachedMark {
                ladderViewDelegate?.linkNearbyMarks(mark: attachedMark)
                ladderViewDelegate?.refresh()
            }
        }
        setNeedsDisplay()
    }

    private func cursorMove(delta: CGFloat) {
        // Movement adjusted to scale.
        cursor.move(delta: delta / scale)
    }

    private func dragMark(ladderViewDelegate: LadderViewDelegate?) {
        if let attachedMark = attachedMark {
            ladderViewDelegate?.moveMark(mark: attachedMark, position: CGPoint(x: translateToScaledViewPositionX(regionPositionX: cursor.position), y: 0), moveCursor: false)
            ladderViewDelegate?.refresh()
        }
    }

    @objc func longPress(press: UILongPressGestureRecognizer) {
        P("Long press on cursor")
    }

    func doCalibration() {
        P("Do calibration")
    }

    func putCursor(screenPositionX positionX: CGFloat) {
        cursor.position = positionX / scale
    }

    func attachMark(screenPositionX positionX: CGFloat) {
        guard let mark = ladderViewDelegate?.addMark(positionX: positionX) else { return }
        attachMark(mark)
        mark.attached = true
        mark.highlight = .all
    }
}

// MARK: - CursorView delegate methods

extension CursorView: CursorViewDelegate {
    func refresh() {
        setNeedsDisplay()
    }

    func attachMark(_ mark: Mark?) {
        guard let mark = mark else { return }
        attachedMark = mark
        mark.attached = true
        mark.highlight = .all
    }

    func unattachAttachedMark() {
        guard let mark = attachedMark else { return }
        mark.attached = false
        mark.highlight = .none
        attachedMark = nil
    }

    func moveCursor(cursorViewPositionX positionX: CGFloat) {
        cursor.position = positionX
    }

    func hideCursor(_ hide: Bool) {
        cursor.visible = !hide
    }

    func cursorIsVisible() -> Bool {
        return cursor.visible
    }
}

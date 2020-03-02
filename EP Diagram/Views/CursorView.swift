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
    func moveCursor(positionX: CGFloat)
    func highlightCursor(_ on: Bool)
    func hideCursor(_ hide: Bool)
    func cursorIsVisible() -> Bool
}

class CursorView: ScaledView {
    let unattachedColor: UIColor = UIColor.systemRed
    let attachedColor: UIColor = UIColor.systemBlue
    let goneColor: UIColor = UIColor.clear
    var cursor: Cursor
    var attachedMark: Mark?

    let rightMargin: CGFloat = 5
    let alphaValue: CGFloat = 0.8
    let lineWidth: CGFloat = 2
    var color: UIColor
    var cursorState: Cursor.CursorState {
        didSet {
            cursor.state = cursorState
            switch cursorState {
            case .attached:
                color = attachedColor
            case .unattached:
                color = unattachedColor
            case .null:
                color = unattachedColor

            }
        }
    }
    var width: CGFloat = 0
    var height: CGFloat = 0

    weak var ladderViewDelegate: LadderViewDelegate?

    var leftMargin: CGFloat = 0

    // How close a tap has to be to a cursor to register.
    let accuracy: CGFloat = 20
    var calibrating = false

    // MARK: - init

    required init?(coder: NSCoder) {
        P("CursorView required init")
        self.cursor = Cursor()
        self.cursor.visible = false
        self.cursor.state = .null
        self.cursorState = .null
        self.color = attachedColor
        super.init(coder: coder)
        didLoad()
    }

    override init(frame: CGRect) {
        P("CursorView override init")
        self.cursor = Cursor()
        self.cursor.visible = false
        self.cursor.state = .null
        self.cursorState = .null
        self.color = attachedColor
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

    // MARK: - draw

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            height = getCursorHeight(anchor: getAttachedMarkAnchor())
            let viewDefaultHeight = ladderViewDelegate?.getTopOfLadder(view: self)
            assert(cursor.direction == .vertical)

            guard cursor.visible else { return }

            context.setStrokeColor(color.cgColor)
            context.setLineWidth(lineWidth)
            context.setAlpha(alphaValue)
            let position = scale * cursor.position - offsetX
            let defaultHeight = viewDefaultHeight ?? height
            let cursorHeight = (position <= leftMargin) ? defaultHeight : height
            context.move(to: CGPoint(x: position, y: 0))
            let endPoint = CGPoint(x: position, y: cursorHeight)
            context.addLine(to: endPoint)
            context.strokePath()
            // Add tiny circle around intersection of cursor and mark.
            if position > leftMargin {
                drawCircle(context: context, center: endPoint, radius: 5)
            }
        }
    }

    func drawCircle(context: CGContext, center: CGPoint, radius: CGFloat) {
        context.addArc(center: center, radius: radius, startAngle: 0.0, endAngle: .pi * 2.0, clockwise: true)
        context.strokePath()
    }

    func getAttachedMarkAnchor() -> Anchor {
        guard let attachedMark = attachedMark else { return .none }
        return attachedMark.anchor
    }

    fileprivate func getAnchorY(_ anchor: Anchor, _ ladderViewDelegate: LadderViewDelegate) -> CGFloat {
        let anchorY: CGFloat
        switch anchor {
        case .proximal:
            anchorY = ladderViewDelegate.getRegionProximalBoundary(view: self)
        case .middle:
            anchorY = ladderViewDelegate.getRegionMidPoint(view: self)
        case .distal:
            anchorY = ladderViewDelegate.getRegionDistalBoundary(view: self)
        case .none:
            anchorY = ladderViewDelegate.getHeight()
        }
        return anchorY
    }

    private func getCursorHeight(anchor: Anchor) -> CGFloat {
        guard let ladderViewDelegate = ladderViewDelegate else { return self.frame.height }
        return getAnchorY(anchor, ladderViewDelegate)
    }

    // MARK: - touches

    // This function passes touch events to the views below if the point is not
    // near the cursor.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        P("cursor.visible = \(cursor.visible)")
        guard cursor.visible, let ladderViewDelegate = ladderViewDelegate else { return false }
        if isNearCursor(positionX: point.x, accuracy: accuracy) && point.y < ladderViewDelegate.getRegionProximalBoundary(view: self) {
            return true
        }
        return false
    }

    func isNearCursor(positionX: CGFloat, accuracy: CGFloat) -> Bool {
        return positionX < translateToLadderViewPositionX(regionPositionX: cursor.position) + accuracy && positionX > translateToLadderViewPositionX(regionPositionX: cursor.position) - accuracy
    }

    @objc func singleTap(tap: UITapGestureRecognizer) {
        if calibrating {
            doCalibration()
            return
        }
        hideCursor(cursor.visible)
        unattachAttachedMark()
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

    @objc func dragging(pan: UIPanGestureRecognizer) {
        if pan.state == .changed {
            let delta = pan.translation(in: self)
            cursorMove(delta: delta.x)
            dragMark(ladderViewDelegate: ladderViewDelegate, cursorViewDelegate: self)
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

    func cursorMove(delta: CGFloat) {
        // Movement adjusted to scale.
        cursor.move(delta: delta / scale)
    }

    func dragMark(ladderViewDelegate: LadderViewDelegate?, cursorViewDelegate: CursorViewDelegate?) {
        if let attachedMark = attachedMark {
            P("Move attached Mark")
            ladderViewDelegate?.moveMark(mark: attachedMark, position: CGPoint(x: translateToLadderViewPositionX(regionPositionX: cursor.position), y: 0), moveCursor: false, cursorViewDelegate: cursorViewDelegate)
            ladderViewDelegate?.refresh()
        }
    }

    @objc func longPress(press: UILongPressGestureRecognizer) {
        P("Long press on cursor")
    }

    func doCalibration() {
        P("Do calibration")
    }

    func putCursor(positionX: CGFloat) {
        cursor.position = positionX / scale
        hideCursor(false)
    }
}

extension CursorView: CursorViewDelegate {
    // MARK: - CursorView delegate methods
    func refresh() {
        setNeedsDisplay()
    }

    func attachMark(_ mark: Mark?) {
        guard let mark = mark else { return }
        attachedMark = mark
        mark.attached = true
        mark.highlight = .all
        P("Mark attached!")
    }

    func attachMark(positionX: CGFloat) {
        let mark = ladderViewDelegate?.addMark(positionX: positionX)
        attachMark(mark)
    }

    func unattachAttachedMark() {
        if let mark = attachedMark {
            mark.attached = false
            attachedMark = nil
            ladderViewDelegate?.unhighlightMarks()
        }
    }

    func moveCursor(positionX: CGFloat) {
        cursor.position = positionX
    }

    func highlightCursor(_ on: Bool) {
        cursorState = on ? .attached : .unattached
    }

    func hideCursor(_ hide: Bool) {
        cursor.visible = !hide
    }

    func cursorIsVisible() -> Bool {
        return cursor.visible
    }

}

//
//  CursorViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 6/29/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class CursorViewModel: ScaledViewModel {
    let cursor: Cursor
    let unattachedColor: UIColor = UIColor.systemRed
    let attachedColor: UIColor = UIColor.systemBlue
    let goneColor: UIColor = UIColor.clear
    var leftMargin: CGFloat
    let rightMargin: CGFloat = 5
    let alphaValue: CGFloat = 0.8
    let lineWidth: CGFloat = 2
    var color: UIColor
    var width: CGFloat
    var height: CGFloat
    var attachedMark: Mark?
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
    var cursorVisible: Bool {
        get {
           cursor.visible
        }
        set(newValue) {
            cursor.visible = newValue
        }
    }

    var cursorPosition: CGFloat {
        get {
            cursor.position
        }
        set(newValue) {
            cursor.position = newValue
        }
    }

    var cursorAnchor: Cursor.Anchor {
        get {
            cursor.anchor
        }
        set(newValue) {
            cursor.anchor = newValue
        }
    }

    override convenience init() {
        self.init(leftMargin: 0, width: 0, height: 0)
    }

    init(leftMargin: CGFloat, width: CGFloat, height: CGFloat) {
        self.leftMargin = leftMargin
        self.width = width
        self.height = height

        self.cursor = Cursor()
        self.cursor.visible = false
        self.cursor.state = .null
        self.cursorState = .null
        self.color = attachedColor
        super.init()
    }

    // Not currently used.
    func centerCursor() {
        cursor.position = width / 2
    }

    func hideCursor() {
        cursor.visible = false
    }

    func showCursor() {
        cursor.visible = true
    }

    func cursorMove(delta: CGFloat) {
        // Movement adjusted to scale.
        cursor.move(delta: delta / scale)
    }

    func isNearCursor(positionX: CGFloat, accuracy: CGFloat) -> Bool {
        return positionX < translateToScreenPositionX(regionPositionX: cursor.position) + accuracy && positionX > translateToScreenPositionX(regionPositionX: cursor.position) - accuracy
    }

    func draw(rect: CGRect, context: CGContext, defaultHeight: CGFloat?) {
        // TODO: Until horizontal cursors are implemented, trap them.
        assert(cursor.direction == .vertical)

        guard cursor.visible else { return }

        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        context.setAlpha(alphaValue)
        let position = scale * cursor.position - offset
        let defaultHeight = defaultHeight ?? height
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

    func drawCircle(context: CGContext, center: CGPoint, radius: CGFloat) {
        context.addArc(center: center, radius: radius, startAngle: 0.0, endAngle: .pi * 2.0, clockwise: true)
        context.strokePath()
    }

    func attachMark(_ mark: Mark?) {
        guard let mark = mark else { return }
        attachedMark = mark
        mark.attached = true
        mark.highlight = .all
        P("Mark attached!")
    }

    /// Unattaches mark if attached.  Returns true if mark was unattached, false if attached mark was already nil.
    func unattachMark(ladderViewDelegate: LadderViewDelegate?) -> Bool {
        if let mark = attachedMark {
            mark.attached = false
            ladderViewDelegate?.getViewModel().unhighlightMarks()
            attachedMark = nil
            return true
        }
        return false
    }

    func dragMark(ladderViewDelegate: LadderViewDelegate?, cursorViewDelegate: CursorViewDelegate?) {
        if let attachedMark = attachedMark {
            P("Move attached Mark")
            ladderViewDelegate?.getViewModel().moveMark(mark: attachedMark, position: CGPoint(x: translateToScreenPositionX(regionPositionX: cursorPosition), y: 0), moveCursor: false, cursorViewDelegate: cursorViewDelegate)
            ladderViewDelegate?.refresh()
        }
    }

    func getAttachedMarkAnchor() -> Anchor {
        guard let attachedMark = attachedMark else { return .none }
        return attachedMark.anchor
    }

    func doubleTap(ladderViewDelegate: LadderViewDelegate?) {
        if let attachedMark = attachedMark {
            ladderViewDelegate?.getViewModel().deleteMark(attachedMark)
            hideCursor()
            ladderViewDelegate?.refresh()
        }
    }

    func attachMark(positionX: CGFloat, ladderViewDelegate: LadderViewDelegate?) {
        let mark = ladderViewDelegate?.getViewModel().addMark(positionX: positionX)
        attachMark(mark)
    }

}

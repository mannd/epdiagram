//
//  CursorViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 6/29/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class CursorViewModel: NSObject {
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
    var scale: CGFloat = 1
    var offset: CGFloat = 0
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
    var cursorVisible: Bool = false {
        didSet {
            cursor.visible = cursorVisible
        }
    }

    override convenience init() {
        self.init(leftMargin: 0, width: 0, height: 0)
    }

    init(leftMargin: CGFloat, width: CGFloat, height: CGFloat) {
        self.cursor = Cursor()
        self.cursor.visible = false
        self.cursor.state = .null
        self.leftMargin = leftMargin
        self.width = width
        self.height = height
        self.cursorState = .null
        self.color = attachedColor
        super.init()
        //centerCursor()
    }

    func centerCursor() {
        cursor.position = width / 2
    }

    func hideCursor() {
        cursor.visible = false
    }

    func showCursor() {
        cursor.visible = true
    }

    func isNearCursor(location: CGFloat, cursor: Cursor, accuracy: CGFloat) -> Bool {
        return location < Common.translateToRelativeLocation(location: cursor.position, offset: offset, scale: scale) + accuracy
            && location > Common.translateToRelativeLocation(location: cursor.position, offset: offset, scale: scale) - accuracy
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

}

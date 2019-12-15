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
        cursor.location = width / 2
    }

    func hideCursor() {
        cursor.visible = false
    }

    func showCursor() {
        cursor.visible = true
    }

    func draw(rect: CGRect, scale: CGFloat, offset: CGFloat, context: CGContext, defaultHeight: CGFloat?) {
        guard cursor.visible else { return }
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        context.setAlpha(alphaValue)
        adjustLocation()
        let location = scale * cursor.location - offset
        let defaultHeight = defaultHeight ?? height
        let cursorHeight = (location <= leftMargin) ? defaultHeight : height
        context.move(to: CGPoint(x: location, y: 0))
        context.addLine(to: CGPoint(x: location, y: cursorHeight))
        context.strokePath()
    }

    private func adjustLocation() {
        return
//        cursor.location = max(cursor.location, leftMargin)
//        cursor.location = min(cursor.location, width - rightMargin)
    }
}

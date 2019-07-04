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
    var leftMargin: CGFloat
    let rightMargin: CGFloat = 5
    let alphaValue: CGFloat = 0.8
    let lineWidth: CGFloat = 1
    var color: UIColor = UIColor.magenta
    var width: CGFloat
    var height: CGFloat

    init(cursor: Cursor, leftMargin: CGFloat, width: CGFloat, height: CGFloat) {
        self.cursor = cursor
        self.leftMargin = leftMargin
        self.width = width
        self.height = height
        super.init()
        centerCursor()
    }

    func centerCursor() {
        cursor.location = width / 2
    }

    func draw(rect: CGRect, context: CGContext) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        context.setAlpha(alphaValue)
        adjustLocation()
        context.move(to: CGPoint(x: cursor.location, y: 0))
        context.addLine(to: CGPoint(x: cursor.location, y: height))
        context.strokePath()
    }

    private func adjustLocation() {
        cursor.location = max(cursor.location, leftMargin)
        cursor.location = min(cursor.location, width - rightMargin)
    }

}

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
    var width: CGFloat
    var height: CGFloat

    init(cursor: Cursor, leftMargin: CGFloat, width: CGFloat, height: CGFloat) {
        self.cursor = cursor
        self.leftMargin = leftMargin
        self.width = width
        self.height = height
        // We'll put cursor in middle of screen to start
        cursor.position = width / 2
    }

    func draw(rect: CGRect, context: CGContext) {
        context.setStrokeColor(UIColor.magenta.cgColor)
        context.setLineWidth(lineWidth)
        context.setAlpha(alphaValue)
        adjustPosition()
        context.move(to: CGPoint(x: cursor.position, y: 0))
        context.addLine(to: CGPoint(x: cursor.position, y: height))
        context.strokePath()
    }

    private func adjustPosition() {
        cursor.position = max(cursor.position, leftMargin)
        cursor.position = min(cursor.position, width - rightMargin)
    }

}

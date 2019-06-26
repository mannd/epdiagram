//
//  RegionViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 6/2/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class RegionViewModel: NSObject {
    let rect: CGRect
    let region: Region
    let scale: CGFloat
    let offset: CGFloat
    var lastRegion = false

    init(rect: CGRect, offset: CGFloat, scale: CGFloat, region: Region) {
        self.rect = rect
        self.offset = offset
        self.scale = scale
        self.region = region
    }

    func draw(context: CGContext) {
        // draw labels
        let stringRect = CGRect(x: 0, y: rect.origin.y, width: rect.origin.x, height: rect.height)
        context.addRect(stringRect)
        context.setStrokeColor(UIColor.red.cgColor)
        context.setFillColor(UIColor.white.cgColor)
        context.setLineWidth(1)
        context.drawPath(using: .fillStroke)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key : Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 18.0),
            .foregroundColor: region.selected ? UIColor.red : UIColor.blue
        ]
        let text = region.label?.name ?? ""
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let size: CGSize = text.size(withAttributes: attributes)
        let labelRect = CGRect(x: 0, y: rect.origin.y + (rect.height - size.height) / 2, width: rect.origin.x, height: size.height)
        attributedString.draw(in: labelRect)
        // Draw ladder lines
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
        context.addLine(to: CGPoint(x: rect.width, y: rect.origin.y))
        context.strokePath()
        if region.selected {
            context.setFillColor(UIColor.red.cgColor)
            let regionRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height)
            context.setAlpha(0.1)
            context.addRect(regionRect)
            context.drawPath(using: .fillStroke)
        }
        context.setAlpha(1)
        context.strokePath()
        // Draw marks
        for mark: Mark in region.marks {
            let scrolledStartPosition = scale * mark.startPosition! - offset
            let scrolledEndPosition = scale * mark.endPosition! - offset
            context.setLineWidth(mark.width)
            // Don't bother drawing marks in margin.
            if scrolledStartPosition > rect.origin.x {
                context.setStrokeColor(mark.color.cgColor)
                context.move(to: CGPoint(x: scrolledStartPosition, y: rect.origin.y))
                context.addLine(to: CGPoint(x: scrolledEndPosition, y: rect.origin.y + rect.height))
                context.strokePath()
                context.setStrokeColor(UIColor.black.cgColor)
            }
        }
        // Only bother drawing last line if last region.
        context.setLineWidth(1)
        if lastRegion {
            context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height))
            context.addLine(to: CGPoint(x: rect.width, y: rect.origin.y + rect.height))
        }
        context.strokePath()
    }
}

//
//  LadderViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class LadderViewModel {
    let ladder: Ladder

    init() {
        ladder = Ladder.defaultLadder()
        let regions = ladder.regions

        // Temporarily act on first region
        ladder.activeRegion = regions[2]
    }

    init(ladder: Ladder) {
        self.ladder = ladder
    }

    func activeRegion() -> Region? {
        return ladder.activeRegion
    }

    func addMark(location: CGFloat) {
        print("Add mark at \(location)")
        ladder.addMarkAt(location)
    }

    func draw(rect: CGRect, margin: CGFloat, offset: CGFloat, scale: CGFloat, context: CGContext) {
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1)
        // unitHeight assumes top and bottom margins equal to height of non-decremental
        // region, and decremental regions are twice this height.
        let unitHeight = getUnitHeight(rect: rect, ladder: ladder)
        // All horizontal distances are adjusted to scale.
        let ladderWidth: CGFloat = rect.width * scale
        // Determine y axis positioning of each region in ladder.
        // First region is one unitHeight below top of LadderView.
        var regionOriginY = unitHeight
        var regionNumber = 0
        for region: Region in ladder.regions {
            let regionHeight = region.decremental ? 2 * unitHeight : unitHeight
            region.startPosition = regionOriginY
            region.endPosition = regionOriginY + regionHeight
            let regionRect = CGRect(x: margin, y: regionOriginY, width: ladderWidth, height: regionHeight)
            regionOriginY += regionHeight
            regionNumber += 1
            var lastRegion = false
            if regionNumber >= ladder.regions.count {
                lastRegion = true
            }
            drawRegion(rect: regionRect, context: context, region: region, offset: offset, scale: scale, lastRegion: lastRegion)
        }
        context.strokePath()
    }

    func drawRegion(rect: CGRect, context: CGContext, region: Region, offset: CGFloat, scale: CGFloat, lastRegion: Bool) {
        // draw label
        let stringRect = CGRect(x: 0, y: rect.origin.y, width: rect.origin.x, height: rect.height)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 18.0),
            .foregroundColor: region.selected ? UIColor.red : UIColor.blue
        ]
        let text = region.label?.name ?? ""
        let labelText = NSAttributedString(string: text, attributes: attributes)
        let size: CGSize = text.size(withAttributes: attributes)
        let labelRect = CGRect(x: 0, y: rect.origin.y + (rect.height - size.height) / 2, width: rect.origin.x, height: size.height)
        context.addRect(stringRect)
        context.setStrokeColor(UIColor.red.cgColor)
        context.setFillColor(UIColor.white.cgColor)
        context.setLineWidth(1)
        context.drawPath(using: .fillStroke)
        labelText.draw(in: labelRect)

        // Draw top ladder line
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
        context.addLine(to: CGPoint(x: rect.width, y: rect.origin.y))
        context.strokePath()

        // Highlight region if selected
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

        // Draw bottom line of region if it is the last region of the ladder.
        context.setLineWidth(1)
        if lastRegion {
            context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height))
            context.addLine(to: CGPoint(x: rect.width, y: rect.origin.y + rect.height))
        }
        context.strokePath()
    }

    func getUnitHeight(rect: CGRect, ladder: Ladder) -> CGFloat {
        var numRegionUnits = 0
        for region: Region in ladder.regions {
            numRegionUnits += region.decremental ? 2 : 1
        }
        // we'll allow one region unit space above and below, so...
        numRegionUnits += 2
        return rect.height / CGFloat(numRegionUnits)
    }
}

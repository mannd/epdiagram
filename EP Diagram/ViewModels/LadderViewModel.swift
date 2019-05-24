//
//  LadderViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class LadderViewModel {
    let margin: CGFloat = 50
    var regionLines: [CGFloat] = []

    let ladder: Ladder

    init() {
        ladder = Ladder.defaultLadder()
    }

    init(ladder: Ladder) {
        self.ladder = ladder
    }
    
    func draw(rect: CGRect, scrollViewBounds: CGRect, scale: CGFloat, context: CGContext) {
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1)
        // We'll divide the height of rect by number of regions.  Each decremental
        // region is twice as high as a nondecremental region.
        // get number of region units.
        var numRegionUnits = 0
        for region: Region in ladder.regions {
            numRegionUnits += region.decremental ? 2 : 1
        }
        // we'll allow one region unit space above and below, so...
        numRegionUnits += 2
        let heightPerRegionUnit = rect.height / CGFloat(numRegionUnits)
        let ladderWidth: CGFloat = rect.width * scale
//        print("ladderWidth = \(ladderWidth)")
//        print("rect.height = \(rect.height)")
//        print("rect.width = \(rect.width)")
//        print("heightPerRegionUnit = \(heightPerRegionUnit)")
        // Draw first line of ladder.
        var regionY = heightPerRegionUnit
        regionLines.append(regionY)
        let ladderOriginY = regionY
        context.move(to: CGPoint(x: margin, y: regionY))
        context.addLine(to: CGPoint(x: ladderWidth, y: regionY))
        for region: Region in ladder.regions {
            regionY += region.decremental ? 2 * heightPerRegionUnit : heightPerRegionUnit
//            print(regionY)
            regionLines.append(regionY)
            context.move(to: CGPoint(x: margin, y: regionY))
            context.addLine(to: CGPoint(x: ladderWidth, y: regionY))
        }
        context.strokePath()

        // instead of blank out left margin, create a rectangle for each label to
        // be centered in.

        // blank out left margin
        context.setStrokeColor(UIColor.red.cgColor) // define this as constant
        context.setFillColor(UIColor.white.cgColor)
        let rectangle = CGRect(x: 0, y: ladderOriginY, width: margin, height: rect.height - 2 * heightPerRegionUnit)
        context.addRect(rectangle)
        context.drawPath(using: .fillStroke)

        // draw labels
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key : Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 18.0),
            .foregroundColor: UIColor.blue
        ]
        let text = "A"
        let attributedString = NSAttributedString(string: text, attributes: attributes)

        let stringRect = CGRect(x: 0, y: ladderOriginY + heightPerRegionUnit / 2, width: margin, height: heightPerRegionUnit / 2)
        attributedString.draw(in: stringRect)

        for region: Region in ladder.regions {
            for mark: Mark in region.marks {
                let scrolledPosition = scale * CGFloat(mark.startPosition!) - scrollViewBounds.origin.x
                context.move(to: CGPoint(x: scrolledPosition, y: regionLines[0]))
                context.addLine(to: CGPoint(x: scrolledPosition, y: regionLines[1]))
                context.strokePath()
            }
        }
    }
}

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
        // unitHeight assumes top and bottom margins equal to height of non-decremental
        // region, and decremental regions are twice this height.
        let unitHeight = getUnitHeight(rect: rect, ladder: ladder)
        // All horizontal distances are adjusted to scale.
        let ladderWidth: CGFloat = rect.width * scale
        let ladderStartPosition = unitHeight

        // Determine y axis positioning of each region in ladder.
        // First region is one unitHeight below top of LadderView.
        var regionStartPosition = unitHeight
        for region: Region in ladder.regions {
            let regionHeight = region.decremental ? 2 * unitHeight : unitHeight
            let regionViewModel = RegionViewModel(startPosition: regionStartPosition, height: regionHeight, region: region)
            regionStartPosition += regionHeight
            regionViewModel.draw(context: context, originX: scrollViewBounds.origin.x, scale: scale, width: ladderWidth, margin: margin)

        }
//        // Draw first line of ladder.
//        var regionY = unitHeight
//        regionLines.append(regionY)
//        let ladderOriginY = regionY
//        context.move(to: CGPoint(x: margin, y: regionY))
//        context.addLine(to: CGPoint(x: ladderWidth, y: regionY))
//        // Draw rest of ladder lines.
//        for region: Region in ladder.regions {
//            regionY += region.decremental ? 2 * unitHeight : unitHeight
////            print(regionY)
//            region.startPosition = Double(regionY)
////            region.endPosition += region.decremental ? Double(2 * heightPerRegionUnit) : Double(heightPerRegionUnit)
//            regionLines.append(regionY)
//            context.move(to: CGPoint(x: margin, y: regionY))
//            context.addLine(to: CGPoint(x: ladderWidth, y: regionY))
//        }
        context.strokePath()

        // instead of blank out left margin, create a rectangle for each label to
        // be centered in.

        // blank out left margin
        context.setStrokeColor(UIColor.red.cgColor) // define this as constant
        context.setFillColor(UIColor.white.cgColor)
        let rectangle = CGRect(x: 0, y: ladderStartPosition, width: margin, height: rect.height - 2 * unitHeight)
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

        let stringRect = CGRect(x: 0, y: regionStartPosition + unitHeight / 2, width: margin, height: unitHeight / 2)
        attributedString.draw(in: stringRect)

//        for region: Region in ladder.regions {
//            for mark: Mark in region.marks {
//                let scrolledPosition = scale * CGFloat(mark.startPosition!) - scrollViewBounds.origin.x
//                context.move(to: CGPoint(x: scrolledPosition, y: regionLines[0]))
//                context.addLine(to: CGPoint(x: scrolledPosition, y: regionLines[1]))
//                context.strokePath()
//            }
//        }
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

//    func setRelativeRegionPositions(rect: CGRect, ladder: Ladder) {
//        let regionHeight = getRegionHeight(rect: rect, ladder: ladder)
//        for region in ladder.regions {
//
//        }
//    }
}

//
//  LadderViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class LadderViewModel {
    public var lineXPosition: Double = 100
    public var scrollViewBounds = CGRect(x: 0, y: 0 , width: 0, height: 0)
    let margin: CGFloat = 50

    let ladder: Ladder

    init() {
        ladder = Ladder.defaultLadder()
    }
    
    func draw(rect: CGRect, scrollViewBounds: CGRect, context: CGContext) {
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
        print(numRegionUnits)
        let heightPerRegionUnit = rect.height / CGFloat(numRegionUnits)
        print("rect.height = \(rect.height)")
        print("heightPerRegionUnit = \(heightPerRegionUnit)")
        // Draw first line of ladder.
        var regionY = heightPerRegionUnit
        context.move(to: CGPoint(x: 0, y: regionY))
        context.addLine(to: CGPoint(x: rect.width, y: regionY))
        for region: Region in ladder.regions {
            regionY += region.decremental ? 2 * heightPerRegionUnit : heightPerRegionUnit
            print(regionY)
            context.move(to: CGPoint(x: 0, y: regionY))
            context.addLine(to: CGPoint(x: rect.width, y: regionY))
        }

        context.strokePath()
        
        context.move(to: CGPoint(x: lineXPosition, y: 0.0))
        context.addLine(to: CGPoint(x: lineXPosition, y: Double(rect
            .height)))
        context.strokePath()
        context.setStrokeColor(UIColor.red.cgColor)
        context.move(to: CGPoint(x: margin + scrollViewBounds.origin.x, y: 0))
        context.addLine(to: CGPoint(x: margin + scrollViewBounds.origin.x, y: rect
            .height))
        context.strokePath()
        context.move(to: CGPoint(x: scrollViewBounds.width + scrollViewBounds.origin.x - margin, y: 0))
        context.addLine(to: CGPoint(x: scrollViewBounds.width + scrollViewBounds.origin.x - margin, y: rect
            .height))
        context.strokePath()
    }
}

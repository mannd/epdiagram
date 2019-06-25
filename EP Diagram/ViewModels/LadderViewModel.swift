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
        // Temporarily act on A region.
        ladder.activeRegion = regions[0]
    }

    init(ladder: Ladder) {
        self.ladder = ladder
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
            let regionRect = CGRect(x: margin, y: regionOriginY, width: ladderWidth, height: regionHeight)
            let regionViewModel = RegionViewModel(rect: regionRect, offset: offset, scale: scale, region: region)
            regionOriginY += regionHeight
            regionNumber += 1
            if regionNumber >= ladder.regions.count {
                regionViewModel.lastRegion = true
            }
            regionViewModel.draw(context: context)
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

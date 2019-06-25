//
//  Ladder.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

// A Ladder is simply a collection of Regions in top bottom order.  Presumably
// an origin is necessay (maybe not, maybe in the ViewModel) in order for the
// Ladder ViewController to know how to draw it.
class Ladder {
    var regions: [Region] = []
    var xOrigin: CGFloat?
    var yOrigin: CGFloat?
    var numRegions: Int {
        get {
            return regions.count
        }
    }
    var activeRegion: Region?

    func addMarkAt(_ location: CGFloat) {
        guard let activeRegion = activeRegion else {
            return
        }
        let mark = Mark()
        mark.startPosition = location
        mark.endPosition = location
        activeRegion.appendMark(mark)
    }

    // Returns a basic ladder (A, AV, V).
    public static func defaultLadder() -> Ladder {
        let ladder = Ladder()
        let aRegion = Region()
        aRegion.label = RegionLabel("A")
        let avRegion = Region()
        avRegion.label = RegionLabel("AV")
        avRegion.decremental = true
        let vRegion = Region()
        vRegion.label = RegionLabel("V")
        ladder.regions = [aRegion, avRegion, vRegion]
        // Add Mark for testing
        let testMark: Mark = Mark()
        testMark.startPosition = 0
        testMark.endPosition = 0
        aRegion.appendMark(testMark)
        let testMark2: Mark = Mark()
        testMark2.startPosition = 100.0
        testMark2.endPosition = 100.0
        aRegion.appendMark(testMark2)
        let testMark3: Mark = Mark()
        testMark3.startPosition = 50
        testMark3.endPosition = 50
        vRegion.appendMark(testMark3)
        let testMark4 = Mark()
        testMark4.startPosition = 0
        testMark4.endPosition = 50
        avRegion.appendMark(testMark4)

        return ladder
    }
}

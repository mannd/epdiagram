//
//  Ladder.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import Foundation

// A Ladder is simply a collection of Regions in top bottom order.  Presumably
// an origin is necessay (maybe not, maybe in the ViewModel) in order for the
// Ladder ViewController to know how to draw it.
class Ladder {
    var regions: [Region] = []
    var xOrigin: Double?
    var yOrigin: Double?
    var numRegions: Int {
        get {
            return regions.count
        }
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
        testMark.startPosition = 100.0
        testMark.endPosition = 100.0
        aRegion.appendMark(testMark)
        let testMark2: Mark = Mark()
        testMark2.startPosition = 200.0
        testMark2.endPosition = 200.0
        aRegion.appendMark(testMark2)
        let testMark3: Mark = Mark()
        testMark3.startPosition = 150
        testMark3.endPosition = 150
        vRegion.appendMark(testMark3)
        let testMark4 = Mark()
        testMark4.startPosition = 100
        testMark4.endPosition = 150
        avRegion.appendMark(testMark4)

        return ladder
    }
}

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
    // For any ladder, only one Mark in only one Region can be active.
    var activeMark: Mark?

    func addMarkAt(_ location: CGFloat) -> Mark? {
        guard let activeRegion = activeRegion else {
            return nil
        }
        let mark = Mark()
        mark.start = location
        mark.end = location
        mark.selected = true
        activeRegion.appendMark(mark)
        return mark
    }

    func deleteMark(mark: Mark) {
        guard let activeRegion = activeRegion else { return }
        if let index = activeRegion.marks.firstIndex(where: {$0 === mark}) {
            activeRegion.marks.remove(at: index)
        }
    }


    // Returns a basic ladder (A, AV, V).
    static func defaultLadder() -> Ladder {
        let ladder = Ladder()
        let aRegion = Region()
        aRegion.label = RegionLabel("A")
        aRegion.selected = true
        let avRegion = Region()
        avRegion.label = RegionLabel("AV")
        avRegion.decremental = true
        let vRegion = Region()
        vRegion.label = RegionLabel("V")
        ladder.regions = [aRegion, avRegion, vRegion]
        // Add Mark for testing
        let testMark: Mark = Mark()
        testMark.start = 10
        testMark.end = 10
        aRegion.appendMark(testMark)
        let testMark2: Mark = Mark()
        testMark2.start = 100.0
        testMark2.end = 100.0
        aRegion.appendMark(testMark2)
        let testMark3: Mark = Mark()
        testMark3.start = 50
        testMark3.end = 50
        vRegion.appendMark(testMark3)
        let testMark4 = Mark()
        testMark4.start = 10
        testMark4.end = 50
        avRegion.appendMark(testMark4)
        return ladder
    }
}

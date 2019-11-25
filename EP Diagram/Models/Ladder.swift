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

    // TODO: location must be a MarkPosition, to set both ends.
    func addMarkAt(_ location: CGFloat) -> Mark? {
        guard let activeRegion = activeRegion else {
            return nil
        }
        let mark = Mark()
        mark.position.proximal.x = location
        mark.position.distal.x = location
        mark.position.proximal.y = 0
        mark.position.distal.y = 1
        mark.highlight = .all
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
        aRegion.name = "A"
        aRegion.selected = true
        let avRegion = Region()
        avRegion.name = "AV"
        avRegion.decremental = true
        let vRegion = Region()
        vRegion.name = "V"
        ladder.regions = [aRegion, avRegion, vRegion]
        return ladder
    }
}

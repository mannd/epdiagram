//
//  Ladder.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

// A Ladder is simply a collection of Regions in top bottom order.
class Ladder {
    var regions: [Region] = []
    var numRegions: Int {
        get {
            return regions.count
        }
    }
    var activeRegion: Region?
    // For any ladder, only one Mark in only one Region can be active.
    // TODO: activeMark unused?
    var activeMark: Mark?

    // By default, a new mark is vertical and spans the region.
    func addMarkAt(_ positionX: CGFloat) -> Mark? {
        guard let activeRegion = activeRegion else {
            return nil
        }
        let mark = Mark(positionX: positionX)
        mark.highlight = .all
        activeRegion.appendMark(mark)
        return mark
    }

    func addMark(mark: Mark) -> Mark? {
        guard let activeRegion = activeRegion else {
            return nil
        }
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

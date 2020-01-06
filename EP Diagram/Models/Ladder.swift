//
//  Ladder.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

struct NearbyMarks {
    var proximalMarks: [Mark] = []
    var distalMarks: [Mark] = []
}

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

    // Assumes mark is in active region, which is always true when mark has a cursor.
    func deleteMark(_ mark: Mark?) {
        guard let activeRegion = activeRegion, let mark = mark else { return }
        if let index = activeRegion.marks.firstIndex(where: {$0 === mark}) {
            activeRegion.marks.remove(at: index)
        
        }
    }

    func deleteMarkInLadder(mark: Mark) {
        for region in regions {
            if let index = region.marks.firstIndex(where: {$0 === mark}) {
                region.marks.remove(at: index)
            }
        }
    }

    func deleteMark(mark: Mark, region: Region?) {
        guard let region = region else { return }
        if let index = region.marks.firstIndex(where: {$0 === mark}) {
            region.marks.remove(at: index)
        }
    }

    func getRegionIndex(region: Region?) -> Int? {
        if let index = regions.firstIndex(where: {$0 === region}) {
            return index
        }
        return nil
    }

    func getRegionBefore(region: Region?) -> Region? {
        if let index = getRegionIndex(region: region) {
            if index > 0 {
                return regions[index - 1]
            }
        }
        return nil
    }

    func getRegionAfter(region: Region?) -> Region? {
        if let index = getRegionIndex(region: region) {
            if index < regions.count - 1 {
                return regions[index + 1]
            }
        }
        return nil
    }

    func getNearbyMarks(mark: Mark, minimum: CGFloat) -> NearbyMarks {
        var proximalMarks: [Mark] = []
        var distalMarks: [Mark] = []
        // check proximal region
        if let proximalRegion = getRegionBefore(region: activeRegion) {
            for neighboringMark in proximalRegion.marks {
                if abs(mark.position.proximal.x - neighboringMark.position.distal.x) < minimum {
                    proximalMarks.append(neighboringMark)
                    break
                }
            }
        }
        // check distal region
        if let distalRegion = getRegionAfter(region: activeRegion) {
            for neighboringMark in distalRegion.marks {
                if abs(mark.position.distal.x - neighboringMark.position.proximal.x) < minimum {
                    distalMarks.append(neighboringMark)
                    break
                }
            }
        }
        return NearbyMarks(proximalMarks: proximalMarks, distalMarks: distalMarks)
    }

    func setHighlight(highlight: Mark.Highlight, region: Region?) {
        guard let region = region else { return }
        for mark in region.marks {
            mark.highlight = highlight
        }
    }

    func setHighlight(highlight: Mark.Highlight) {
        for region in regions {
            setHighlight(highlight: highlight, region: region)
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

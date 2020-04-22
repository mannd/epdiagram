//
//  Ladder.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

struct NearbyMarks {
    var proximal: [Mark] = []
    var middle: [Mark] = []
    var distal: [Mark] = []
}

/// Struct that pinpoints a point in a ladder.  Note that these tapped areas overlap (labels and marks are in regions).
struct LocationInLadder {
    var region: Region?
    var mark: Mark?
    var regionSection: RegionSection
    var regionDivision: RegionDivision
    var markAnchor: Anchor
    var regionWasTapped: Bool {
        region != nil
    }
    var labelWasTapped: Bool {
        regionSection == .labelSection
    }
    var markWasTapped: Bool {
        mark != nil
    }
}

// A Ladder is simply a collection of Regions in top bottom order.
class Ladder {
    private typealias Registry = Dictionary<UUID, Int>

    private var registry: Registry = [ : ]

    var regions: [Region] = []
    var numRegions: Int {
        get {
            return regions.count
        }
    }
    var activeRegion: Region?

    var attachedMark: Mark?
    var pressedMark: Mark?
    var movingMark: Mark?
    var selectedMarks: [Mark] = []
    var linkedMarks: [Mark] = []

    // By default, a new mark is vertical and spans the region.
    func addMarkAt(_ positionX: CGFloat) -> Mark? {
        guard let activeRegion = activeRegion else {
            return nil
        }
        let mark = Mark(positionX: positionX)
        mark.highlight = .all
        mark.attached = true
        activeRegion.appendMark(mark)
        registry[mark.id] = activeRegion.index
        return mark
    }

    func addMark(mark: Mark) {
        guard let activeRegion = activeRegion else { return }
        mark.highlight = .all
        activeRegion.appendMark(mark)
        registry[mark.id] = activeRegion.index
    }

    // Assumes mark is in active region, which is always true when mark has a cursor.
    func deleteMark(_ mark: Mark?) {
        guard let activeRegion = activeRegion, let mark = mark else { return }
        if let index = activeRegion.marks.firstIndex(where: {$0 === mark}) {
            activeRegion.marks.remove(at: index)
        }
        registry.removeValue(forKey: mark.id)
    }

    func deleteMarkInLadder(mark: Mark) {
        for region in regions {
            if let index = region.marks.firstIndex(where: {$0 == mark}) {
                region.marks.remove(at: index)
            }
        }
        registry.removeValue(forKey: mark.id)
    }

    func deleteMark(mark: Mark, region: Region?) {
        guard let region = region else { return }
        if let index = region.marks.firstIndex(where: {$0 == mark}) {
            region.marks.remove(at: index)
        }
        registry.removeValue(forKey: mark.id)
    }

    func deleteMarksInRegion(_ region: Region) {
        region.marks.removeAll()
        for mark: Mark in region.marks {
            registry.removeValue(forKey: mark.id)
        }
    }

    func getRegionIndex(region: Region?) -> Int? {
        guard let region = region else { return nil }
        return region.index
    }

    func getRegionIndex(ofMark mark: Mark) -> Int? {
        let index = registry[mark.id]
        return index
    }

    func getRegion(index: Int) -> Region? {
        return regions[index]
    }

    func getRegion(ofMark mark: Mark) -> Region? {
        if let index = getRegionIndex(ofMark: mark) {
            return getRegion(index: index)
        }
        else { return nil }
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

//    // FIXME: distance must use screen coordinates, not ladder coordinates.
//    func getNearbyMarks(mark: Mark, minimum: CGFloat) -> NearbyMarks {
//        var proximalMarks: [Mark] = []
//        var distalMarks: [Mark] = []
//        var middleMarks: [Mark] = []
//        // check proximal region
//        if let proximalRegion = getRegionBefore(region: activeRegion) {
//            for neighboringMark in proximalRegion.marks {
//                if abs(mark.segment.proximal.x - neighboringMark.segment.distal.x) < minimum {
//                    proximalMarks.append(neighboringMark)
//                    break
//                }
//            }
//        }
//        // check distal region
//        if let distalRegion = getRegionAfter(region: activeRegion) {
//            for neighboringMark in distalRegion.marks {
//                if abs(mark.segment.distal.x - neighboringMark.segment.proximal.x) < minimum {
//                    distalMarks.append(neighboringMark)
//                    break
//                }
//            }
//        }
//        // check in the same region
//        if let region = activeRegion {
//            for neighboringMark in region.marks {
//                if !(neighboringMark === mark) {
//                    // FIXME: distance must use screen coordinates, not ladder coordinates.
//                    // compare distance of 2 line segments here and append
//                    if Common.distance(segment: neighboringMark.segment, point: mark.segment.proximal) < minimum ||
//                        Common.distance(segment: neighboringMark.segment, point: mark.segment.distal) < minimum {
//                        middleMarks.append(neighboringMark)
//                        break
//                    }
//                }
//            }
//        }
//        return NearbyMarks(proximalMarks: proximalMarks, middleMarks: middleMarks, distalMarks: distalMarks)
//    }

    func setHighlightForMarks(highlight: Mark.Highlight, inRegion region: Region?) {
        guard let region = region else { return }
        for mark in region.marks {
            mark.highlight = highlight
        }
    }

    func setHighlightForAllMarks(highlight: Mark.Highlight) {
        for region in regions {
            setHighlightForMarks(highlight: highlight, inRegion: region)
        }
    }

    func unattachAllMarks() {
        for region in regions {
            for mark in region.marks {
                mark.attached = false
            }
        }
    }

    func unselectAllMarks() {
        for region in regions {
            for mark in region.marks {
                mark.selected = false
            }
        }
        selectedMarks = []
    }

    // Returns a basic ladder (A, AV, V).
    static func defaultLadder() -> Ladder {
        let ladder = Ladder()
        let aRegion = Region(index: 0)
        aRegion.name = "A"
        aRegion.selected = true
        let avRegion = Region(index: 1)
        avRegion.name = "AV"
        avRegion.unitHeight = 2
        let vRegion = Region(index: 2)
        vRegion.name = "V"
        ladder.regions = [aRegion, avRegion, vRegion]
        return ladder
    }
}

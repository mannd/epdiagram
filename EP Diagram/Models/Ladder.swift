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

    var attachedMark: Mark?
    var pressedMark: Mark?
    var movingMark: Mark?
    var selectedMarks: [Mark] = []
    var linkedMarks: [Mark] = []

    // By default, a new mark is vertical and spans the region.
    func addMark(at positionX: CGFloat, inRegion region: Region?) -> Mark? {
        if let region = region {
            let mark = Mark(positionX: positionX)
            registerMark(mark, inRegion: region)
            return mark
        }
        else { return nil }
    }

    func addMark(fromSegment segment: Segment, inRegion region: Region?) -> Mark? {
        if let region = region {
            let mark = Mark(segment: segment)
            registerMark(mark, inRegion: region)
            return mark
        }
        else { return nil }
    }

    func addMark(inRegion region: Region?) -> Mark? {
        if let region = region {
            let mark = Mark()
            registerMark(mark, inRegion: region)
            return mark
        }
        else { return nil }
    }

    private func registerMark(_ mark: Mark, inRegion region: Region) {
        region.appendMark(mark)
        mark.anchor = defaultAnchor(forMark: mark)
        registry[mark.id] = region.index
    }

    func deleteMark(_ mark: Mark?, inRegion region: Region?) {
        guard let mark = mark, let region = region else { return }
        if let index = region.marks.firstIndex(where: {$0 === mark}) {
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

    func getIndex(ofRegion region: Region?) -> Int? {
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

    func getRegionBefore(region: Region) -> Region? {
        if region.index > 0 {
            return regions[region.index - 1]
        }
        else { return nil }
    }

    func getRegionAfter(region: Region) -> Region? {
        if region.index < regions.count - 1 {
            return regions[region.index + 1]
        }
        else { return nil }
    }

    func setHighlightForMarks(highlight: Mark.Highlight, inRegion region: Region?) {
        guard let region = region else { return }
        region.marks.forEach { item in item.highlight = highlight }
    }

    func setHighlightForAllMarks(highlight: Mark.Highlight) {
        for region in regions {
            setHighlightForMarks(highlight: highlight, inRegion: region)
        }
    }

    func unattachAllMarks() {
        for region in regions {
            region.marks.forEach { item in item.attached = false }
        }
    }

    func unselectAllMarks() {
        for region in regions {
            region.marks.forEach { item in item.selected = false }
        }
        selectedMarks = []
    }

    func availableAnchors(forMark mark: Mark) -> [Anchor] {
        return defaultAnchors()
    }

    private func defaultAnchors() -> [Anchor] {
        return [.middle, .proximal, .distal]
    }

    func defaultAnchor(forMark mark: Mark) -> Anchor {
        return availableAnchors(forMark: mark)[0]
    }

    // Returns a basic ladder (A, AV, V).
    static func defaultLadder() -> Ladder {
        let ladder = Ladder()
        let aRegion = Region(index: 0)
        aRegion.name = "A"
        aRegion.activated = true
        let avRegion = Region(index: 1)
        avRegion.name = "AV"
        avRegion.unitHeight = 2
        let vRegion = Region(index: 2)
        vRegion.name = "V"
        ladder.regions = [aRegion, avRegion, vRegion]
        return ladder
    }
}

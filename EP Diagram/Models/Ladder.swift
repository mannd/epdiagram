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

    private var registry: Registry = [:]

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

    // TODO: Does region have to be optional?  Consider refactor away optionality.
    // addMark() functions.  All require a Region in which to add the mark.  Each new mark is registered to that region.  All return addedMark or nil if region is nil.
    // FIXME: should undo, redo be in ladder, and not in the super classes?
    func addMark(at positionX: CGFloat, inRegion region: Region?) -> Mark? {
        return registerAndAppendMark(Mark(positionX: positionX), toRegion: region)
    }

    func addMark(fromSegment segment: Segment, inRegion region: Region?) -> Mark? {
        return registerAndAppendMark(Mark(segment: segment), toRegion: region)
    }

    private func registerAndAppendMark(_ mark: Mark, toRegion region: Region?) -> Mark? {
        guard let region = region else { return nil }
        region.appendMark(mark)
        registry[mark.id] = region.index
        return mark
    }

    func deleteMark(_ mark: Mark?, inRegion region: Region?) {
        guard let mark = mark, let region = region else { return }
        setHighlightForAllMarks(highlight: .none)
        if let index = region.marks.firstIndex(where: {$0 === mark}) {
            region.marks.remove(at: index)
        }
        removeMarkReferences(toMark: mark)
        registry.removeValue(forKey: mark.id)
    }

    func deleteMarksInRegion(_ region: Region) {
        setHighlightForAllMarks(highlight: .none)
        for mark: Mark in region.marks {
            registry.removeValue(forKey: mark.id)
            removeMarkReferences(toMark: mark)
        }
        region.marks.removeAll()
    }

    // Remove references to this mark in neighboring marks groupedMarks.
    func removeMarkReferences(toMark mark: Mark) {
        for region in regions {
            for m in region.marks {
                m.groupedMarks.remove(mark: mark)
            }
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
        let groupedMarks = mark.groupedMarks
        // FIXME: if attachment is in middle, only allow other end to move
        if groupedMarks.count < 2 {
            return defaultAnchors()
        }
        else {
            return [.proximal, .distal]
        }
    }

    private func defaultAnchors() -> [Anchor] {
        return [.middle, .proximal, .distal]
    }

    func defaultAnchor(forMark mark: Mark) -> Anchor {
        return availableAnchors(forMark: mark)[0]
    }

    // Pivot points are really fixed points (rename?) that can't move during mark movement.
    func pivotPoints(forMark mark: Mark) -> [Anchor] {
        // No pivot points, i.e. full freedom of movement if no grouped marks.
        if mark.groupedMarks.count == 0 {
            return []
        }
        if mark.groupedMarks.proximal.count > 0 && mark.groupedMarks.distal.count > 0 {
            return [.proximal, .distal]
        }
        else if mark.groupedMarks.proximal.count > 0 {
            return [.distal]
        }
        else if mark.groupedMarks.distal.count > 0 {
            return [.proximal]
        }
        // TODO: deal with middle marks
        return []
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

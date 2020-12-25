//
//  Ladder.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import os.log

// MARK: - structs

struct NearbyMarks {
    var proximal = [Mark]()
    var middle = [Mark]()
    var distal = [Mark]()
}

// MARK: - enums

private enum Keys: String, CustomStringConvertible {
    case name = "ladderName"
    case longDescription = "ladderLongDescription"
    case regions = "ladderRegions"
    // etc.

    var description: String {
        return self.rawValue
    }
}

// Is a mark in the region before, same region, region after, or farther away?
enum RelativeRegion {
    case before
    case same
    case after
    case distant
}

// MARK: - classes

// A Ladder is simply a collection of Regions in top down order.
class Ladder: Codable {

    // MARK: constants
    private(set) var id = UUID()

    // MARK: variables
    var name: String
    var longDescription: String = ""
    var regions = [Region]()
    var numRegions: Int { regions.count }
    var attachedMark: Mark? // cursor is attached to a most 1 mark at a time
    var pressedMark: Mark? // mark that is long-pressed
    var movingMark: Mark? // mark that is being dragged
    var selectedMarks = [Mark]() // mark(s) that have been selected
    var linkedMarks = [Mark]() // marks in the process of being linked
    // marksAreVisible shows and hides all the marks.  You can toggle this for teaching purposes.
    var marksAreVisible: Bool = true
    
    // TODO: Zones are used to select parts of regions.
    var zone: Zone?

    private var registry: [UUID: Mark] = [:]


    // MARK: methods
    init(template: LadderTemplate) {
        os_log("init ladder from template", log: .action, type: .info)
        name = template.name
        longDescription = template.description
        for regionTemplate in template.regionTemplates {
            let region = Region(template: regionTemplate)
            regions.append(region)
        }
    }


    func registerMark(_ mark: Mark) {
        registry[mark.id] = mark
    }

    func unregisterMark(_ mark: Mark) {
        registry.removeValue(forKey: mark.id)
    }

    func lookup(id: UUID) -> Mark? {
        return registry[id]
    }

    func lookup(ids: MarkIdSet) -> MarkSet {
        var markSet = MarkSet()
        for id in ids {
            if let mark = lookup(id: id) {
                markSet.insert(mark)
            }
        }
        return markSet
    }

    // Convert a MarkIdGroup to a MarkGroup
    func getMarkGroup(fromMarkIdGroup markIdGroup: MarkIdGroup) -> MarkGroup {
        var markGroup = MarkGroup()
        markGroup.proximal = lookup(ids: markIdGroup.proximal)
        markGroup.middle = lookup(ids: markIdGroup.middle)
        markGroup.distal = lookup(ids: markIdGroup.distal)
        return markGroup
    }

    func getMarkSet(fromMarkIdSet markIdSet: MarkIdSet) -> MarkSet {
        return lookup(ids: markIdSet)
    }

    func hasMarks() -> Bool {
        for region in regions {
            if region.marks.count > 0 {
                return true
            }
        }
        return false
    }

    // TODO: Need editing facility of ladder: add, delete Regions, edit labels, edit region parameters.  This is important because rather than starting a ladder over from a new blank template, someone may just want to add a region.  Thus, eg.:
    func addRegion() {
        os_log("addRegion()", log: .action, type: .info)
        fatalError("not implemented")
    }

    func deleteRegion(region: Region) {
        os_log("deleteRegion(region:)", log: .action, type: .info)
        fatalError("not implemented")
    }

    func editRegion(region: Region) {
        os_log("editRegion(region:)", log: .action, type: .info)
        fatalError("not implemented")
    }

    static func getRelativeRegionBetweenMarks(mark: Mark, otherMark: Mark) -> RelativeRegion {
        var relativeRegion: RelativeRegion = .distant
        let regionDiff = otherMark.regionIndex - mark.regionIndex
        switch regionDiff {
        case 1:
            relativeRegion = .after
        case 0:
            relativeRegion = .same
        case -1:
            relativeRegion = .before
        default:
            relativeRegion = .distant
        }
        return relativeRegion
    }
    
    // TODO: Does region have to be optional?  Consider refactor away optionality.
    // addMark() functions.  All require a Region in which to add the mark.  Each new mark is registered to that region.  All return addedMark or nil if region is nil.
    func addMark(at positionX: CGFloat, inRegion region: Region?) -> Mark? {
        return addMark(Mark(positionX: positionX), toRegion: region)
    }

     func addMark(fromSegment segment: Segment, inRegion region: Region?) -> Mark? {
        let mark = Mark(segment: segment)
        return addMark(mark, toRegion: region)
    }

    @discardableResult func addMark(_ mark: Mark, toRegion region: Region?) -> Mark? {
        os_log("addMark(_:toRegion:) - Ladder", log: .action, type: .info)
        guard let region = region else { return nil }
        mark.lineStyle = region.lineStyle
        region.appendMark(mark)
        registerMark(mark)
        if let index = getIndex(ofRegion: region) {
            mark.regionIndex = index
        }
        return mark
    }

    func deleteMark(_ mark: Mark?, inRegion region: Region?) {
        guard let mark = mark, let region = region else { return }
        setHighlightForAllMarks(highlight: .none)
        unregisterMark(mark)
        if let index = region.marks.firstIndex(where: {$0 === mark}) {
            region.marks.remove(at: index)
        }
        removeMarkIdReferences(toMarkId: mark.id)
    }

    func deleteMarksInRegion(_ region: Region) {
        setHighlightForAllMarks(highlight: .none)
        for mark: Mark in region.marks {
            removeMarkIdReferences(toMarkId: mark.id)
        }
        region.marks.removeAll()
    }

    func removeMarkIdReferences(toMarkId id: UUID) {
        for region in regions {
            for mark in region.marks {
                mark.groupedMarkIds.remove(id: id)
            }
        }
    }

    // Clear ladder of all marks.
    func clear() {
        for region in regions {
            region.marks.removeAll()
        }
    }

    func getIndex(ofRegion region: Region?) -> Int? {
        guard let region = region else { return nil }
        return regions.firstIndex(of: region)
    }

    func getRegionIndex(ofMark mark: Mark) -> Int? {
        let index = mark.regionIndex
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
        guard let index = getIndex(ofRegion: region) else { return nil }
        if index > 0 {
            return regions[index - 1]
        }
        else { return nil }
    }

    func getRegionAfter(region: Region) -> Region? {
        guard let index = getIndex(ofRegion: region) else { return nil}
        if index < regions.count - 1 {
            return regions[index + 1]
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

    func setHighlightForMarkIdGroup(highlight: Mark.Highlight, markIdGroup: MarkIdGroup) {
        let markGroup = getMarkGroup(fromMarkIdGroup: markIdGroup)
        markGroup.highlight(highlight: highlight)
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

    func getAvailableAnchors(forMark mark: Mark) -> [Anchor] {
        let groupedMarkIds = mark.groupedMarkIds
        // FIXME: if attachment is in middle, only allow other end to move
        if groupedMarkIds.count < 2 {
            return defaultAnchors()
        }
        else {
            return [.proximal, .distal]
        }
    }

    func toggleAnchor(mark: Mark?) {
        guard let mark = mark else { return }
        let availableAnchors = getAvailableAnchors(forMark: mark)
        assert(availableAnchors.count == 2 || availableAnchors.count == 3, "Impossible anchor count!")
        let currentAnchor = mark.anchor
        if availableAnchors.contains(currentAnchor) {
            guard let currentAnchorIndex = availableAnchors.firstIndex(of: currentAnchor) else { mark.anchor = availableAnchors [0]; return }
            if currentAnchorIndex == availableAnchors.count - 1 {
                mark.anchor = availableAnchors[0] // last anchor, scroll around
            } else {
                mark.anchor = availableAnchors[currentAnchorIndex + 1]
            }
        }
        else {
            mark.anchor = availableAnchors[0]
        }
    }

    private func defaultAnchors() -> [Anchor] {
        return [.middle, .proximal, .distal] // Middle anchor is default first anchor
    }

    func defaultAnchor(forMark mark: Mark) -> Anchor {
        return getAvailableAnchors(forMark: mark)[0]
    }

    // Pivot points are really fixed points (rename?) that can't move during mark movement.
    func pivotPoints(forMark mark: Mark) -> [Anchor] {
        // No pivot points, i.e. full freedom of movement if no grouped marks.
        if mark.groupedMarkIds.count == 0 {
            return []
        }
        if mark.groupedMarkIds.proximal.count > 0 && mark.groupedMarkIds.distal.count > 0 {
            return [.proximal, .distal]
        }
        else if mark.groupedMarkIds.proximal.count > 0 {
            return [.distal]
        }
        else if mark.groupedMarkIds.distal.count > 0 {
            return [.proximal]
        }
        // TODO: deal with middle marks
        return []
    }

    func getActiveRegion() -> Region? {
        for region in regions {
            if region.activated {
                return region
            }
        }
        return nil
    }

    func getActiveRegionIndex() -> Int? {
        guard let activeRegion = getActiveRegion() else { return nil }
        return getIndex(ofRegion: activeRegion)
    }


    // Returns a basic ladder (A, AV, V).
    static func defaultLadder() -> Ladder {
        return Ladder(template: LadderTemplate.defaultTemplate())
    }
}

// MARK: - extensions

extension Ladder: CustomDebugStringConvertible {
    var debugDescription: String { "Ladder ID " + id.debugDescription}
}

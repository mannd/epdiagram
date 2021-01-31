//
//  Ladder.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import os.log

// MARK: - classes

/// A Ladder is simply a collection of Regions in top down order.
class Ladder: NSObject, Codable {
    private(set) var id = UUID()

    var name: String
    var longDescription: String = ""
    var regions = [Region]()
    var numRegions: Int { regions.count }
    var attachedMark: Mark? // cursor is attached to a most 1 mark at a time
    var linkedMarks = [Mark]() // marks in the process of being linked
    var marksAreVisible: Bool = true    // shows and hides all the marks.  You can toggle this for teaching purposes.
    var activeRegion: Region? {  // ladder model enforces at most one region can be active
        didSet {
            regions.forEach { region in region.mode = .normal }
            // All regions are set to normal mode if activeRegion set to nil.
            guard let activeRegion = activeRegion else { return }
            activeRegion.mode = .active
        }
    }
    var zone: Zone = Zone()
    override var debugDescription: String { "Ladder ID " + id.debugDescription }
    private var registry: [UUID: Mark] = [:] // marks are registered for quick lookup

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

    // TODO: do we need registry.  With the small number of marks, might be simpler to just search the array of marks...
    func altLookup(id: UUID) -> Mark? {
        var foundMarks = [Mark]()
        for region in regions {
            foundMarks = region.marks.filter { mark in mark.id == id }
            if foundMarks.count > 0 {
                break
            }
        }
        if foundMarks.count == 1 { // all ids should be unique
            return foundMarks[0]
        } else {
            return nil
        }
    }

    func reregisterAllMarks() {
        os_log("restoreRegistry", log: .action, type: .info)
        registry.removeAll()
        for region in regions {
            for mark in region.marks {
                registry[mark.id] = mark
            }
        }
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

    static func regionRelationBetweenMarks(mark: Mark, otherMark: Mark) -> RegionRelation {
        var regionRelation: RegionRelation = .distant
        let regionDiff = otherMark.regionIndex - mark.regionIndex
        switch regionDiff {
        case 1:
            regionRelation = .after
        case 0:
            regionRelation = .same
        case -1:
            regionRelation = .before
        default:
            regionRelation = .distant
        }
        return regionRelation
    }
    
    // TODO: Does region have to be optional?  Consider refactor away optionality.
    // addMark() functions.  All require a Region in which to add the mark.  Each new mark is registered to that region.  All return addedMark or nil if region is nil.
    func addMark(at positionX: CGFloat, inRegion region: Region?) -> Mark? {
        return addMark(Mark(positionX: positionX), toRegion: region)
    }

    @discardableResult func addMark(fromSegment segment: Segment, inRegion region: Region?) -> Mark? {
        let mark = Mark(segment: segment)
        return addMark(mark, toRegion: region)
    }

    @discardableResult func addMark(_ mark: Mark, toRegion region: Region?) -> Mark? {
        os_log("addMark(_:toRegion:) - Ladder", log: .action, type: .info)
        guard let region = region else { return nil }
        mark.style = region.style
        region.appendMark(mark)
        registerMark(mark)
        if let index = regionIndex(ofRegion: region) {
            mark.regionIndex = index
        }
        return mark
    }

    func deleteMark(_ mark: Mark?, inRegion region: Region?) {
        guard let mark = mark, let region = region else { return }
        normalizeAllMarks()
        unregisterMark(mark)
        if let index = region.marks.firstIndex(where: {$0 === mark}) {
            region.marks.remove(at: index)
        }
        removeMarkIdReferences(toMarkId: mark.id)
    }

    func deleteMarksInRegion(_ region: Region) {
        normalizeAllMarks()
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

    func regionIndex(ofRegion region: Region?) -> Int? {
        guard let region = region else { return nil }
        return regions.firstIndex(of: region)
    }

    func regionIndex(ofMark mark: Mark) -> Int? {
        let index = mark.regionIndex
        return index
    }

    func region(at index: Int) -> Region? {
        return regions[index]
    }

    func region(ofMark mark: Mark) -> Region? {
        if let index = regionIndex(ofMark: mark) {
            return region(at: index)
        }
        else { return nil }
    }

    func regionBefore(region: Region) -> Region? {
        guard let index = regionIndex(ofRegion: region) else { return nil }
        if index > 0 {
            return regions[index - 1]
        }
        else { return nil }
    }

    func regionAfter(region: Region) -> Region? {
        guard let index = regionIndex(ofRegion: region) else { return nil}
        if index < regions.count - 1 {
            return regions[index + 1]
        }
        else { return nil }
    }

    func setModeForMarkIdGroup(mode: Mark.Mode, markIdGroup: MarkIdGroup) {
        let markGroup = getMarkGroup(fromMarkIdGroup: markIdGroup)
        markGroup.setMode(mode)
    }

    func normalizeAllMarks() {
        setAllMarksWithMode(.normal)
    }

    // Will have ladder store and set mark modes
    func setAllMarksWithMode(_ mode: Mark.Mode) {
        regions.forEach {
            region in region.marks.forEach { mark in mark.mode = mode }
        }
    }

    func setMarksWithMode(_ mode: Mark.Mode, inRegion region: Region) {
        region.marks.forEach { mark in mark.mode = mode }
    }

    func setMarkwWithMode(_ mode: Mark.Mode, inZone zone: Zone) {
        
    }

    func marksWithMode(_ mode: Mark.Mode, inRegion region: Region) -> [Mark] {
        let marks = region.marks.filter { mark in mark.mode == mode }
        return marks
    }

    func allMarksWithMode(_ mode: Mark.Mode) -> [Mark] {
        var marks = [Mark]()
        for region in regions {
            marks.append(contentsOf: marksWithMode(mode, inRegion: region))
        }
        return marks
    }

    func allRegionsWithMode(_ mode: Region.Mode) -> [Region] {
        return  regions.filter { $0.mode == mode }
    }

    func availableAnchors(forMark mark: Mark) -> [Anchor] {
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
        let anchors = availableAnchors(forMark: mark)
        assert(anchors.count == 2 || anchors.count == 3, "Impossible anchor count!")
        let currentAnchor = mark.anchor
        if anchors.contains(currentAnchor) {
            guard let currentAnchorIndex = anchors.firstIndex(of: currentAnchor) else { mark.anchor = anchors [0]; return }
            if currentAnchorIndex == anchors.count - 1 {
                mark.anchor = anchors[0] // last anchor, scroll around
            } else {
                mark.anchor = anchors[currentAnchorIndex + 1]
            }
        }
        else {
            mark.anchor = anchors[0]
        }
    }

    private func defaultAnchors() -> [Anchor] {
        return [.middle, .proximal, .distal] // Middle anchor is default first anchor
    }

    func defaultAnchor(forMark mark: Mark) -> Anchor {
        return availableAnchors(forMark: mark)[0]
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

    func moveGroupedMarks(forMark mark: Mark) {
        for proximalMark in getMarkSet(fromMarkIdSet: mark.groupedMarkIds.proximal) {
            proximalMark.segment.distal.x = mark.segment.proximal.x
        }
        for distalMark in getMarkSet(fromMarkIdSet: mark.groupedMarkIds.distal) {
            distalMark.segment.proximal.x = mark.segment.distal.x
        }
        for middleMark in getMarkSet(fromMarkIdSet:mark.groupedMarkIds.middle) {
            if mark == middleMark { break }
            let distanceToProximal = Geometry.distanceSegmentToPoint(segment: mark.segment, point: middleMark.segment.proximal)
            let distanceToDistal = Geometry.distanceSegmentToPoint(segment: mark.segment, point: middleMark.segment.distal)
            if distanceToProximal < distanceToDistal {
                let x = mark.segment.getX(fromY: middleMark.segment.proximal.x)
                if let x = x {
                    middleMark.segment.proximal.x = x
                }
            }
            else {
                let x = mark.segment.getX(fromY: middleMark.segment.distal.y)
                    if let x = x {
                        middleMark.segment.distal.x = x
                }
            }
        }
 
    }

    // Returns a basic ladder (A, AV, V).
    static func defaultLadder() -> Ladder {
        return Ladder(template: LadderTemplate.defaultTemplate())
    }
}

// MARK: - structs

struct NearbyMarks {
    var proximal = [Mark]()
    var middle = [Mark]()
    var distal = [Mark]()
}

// MARK: - enums

// Is a mark in the region before, same region, region after, or farther away?
enum RegionRelation {
    case before
    case same
    case after
    case distant
}

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
final class Ladder: NSObject, Codable {
    private(set) var id = UUID()

    // Hard limit on maximum and minimum number of regions in a ladder (for space reasons).
    static let maxRegionCount = 5
    static let minRegionCount = 1

    let template: LadderTemplate
    var name: String
    var longDescription: String = ""
    var leftMargin: CGFloat = 50
    var regions = [Region]()
    var regionCount: Int { regions.count }
    var attachedMark: Mark?  { // attachedMark does not own its mark
        didSet { // cursor is attached to a most 1 mark at a time
            normalizeAllMarks()  // setting attached mark to nil does not delete it, so set its mode to normal.
            if let attachedMark = attachedMark {
                let linkedMarkIDs = attachedMark.linkedMarkIDs
                // Note that the order below is important.  An attached mark can be in its own linkedMarks.  But we always want the attached mark to have an .attached highlight.
                setModeForLinkedMarkIDs(mode: .linked, linkedMarkIDs: linkedMarkIDs)
                attachedMark.mode = .attached
            }
        }
    }

    var connectedMarks = [Mark]() // marks in the process of being connected
    var activeRegion: Region? {  // ladder model enforces at most one region can be active and region.mode == .normal
        didSet {
            regions.forEach { region in region.mode = .normal }
            // All regions are set to normal mode if activeRegion set to nil.
            guard let activeRegion = activeRegion else { return }
            activeRegion.mode = .active
        }
    }

    var defaultMarkStyle: Mark.Style = .solid
    var zone: Zone = Zone() // at most one selection zone
    override var debugDescription: String { "Ladder ID " + id.debugDescription }
    private var registry: [UUID: Mark] = [:] // marks are registered for quick lookup

    init(template: LadderTemplate) {
        os_log("init ladder from template", log: .action, type: .info)
        self.template = template
        name = template.name
        longDescription = template.description
        leftMargin = template.leftMargin
        for regionTemplate in template.regionTemplates {
            let region = Region(template: regionTemplate)
            regions.append(region)
        }
    }

    func registerMark(_ mark: Mark) {
        os_log("registerMark(_:) - Ladder", log: OSLog.touches, type: .info)
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

    // Convert a LinkedMarkIDs to LinkedMarks
    func getLinkedMarks(fromLinkedMarkIDs linkedMarkIDs: LinkedMarkIDs) -> LinkedMarks {
        var linkedMarks = LinkedMarks()
        linkedMarks.proximal = lookup(ids: linkedMarkIDs.proximal)
        linkedMarks.middle = lookup(ids: linkedMarkIDs.middle)
        linkedMarks.distal = lookup(ids: linkedMarkIDs.distal)
        return linkedMarks
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

    func addMark(at positionX: CGFloat, toRegion region: Region) -> Mark {
        os_log("addMark(at:toRegion:) - Ladder", log: OSLog.touches, type: .info)
        return addMark(Mark(positionX: positionX), toRegion: region)
    }

    @discardableResult func addMark(fromSegment segment: Segment, toRegion region: Region) -> Mark {
        os_log("addMark(fromSegment:toRegion:) - Ladder", log: .action, type: .info)
        let mark = Mark(segment: segment)
        return addMark(mark, toRegion: region)
    }

    // All roads lead to this addMark function, which ensures mark is appended to a region and registered.
    @discardableResult func addMark(_ mark: Mark, toRegion region: Region) -> Mark {
        os_log("addMark(_:toRegion:) - Ladder", log: .action, type: .info)
        mark.style = region.style == .inherited ? defaultMarkStyle : region.style
        region.appendMark(mark)
        registerMark(mark)
        if let index = index(ofRegion: region) {
            mark.regionIndex = index
        }
        return mark
    }

    func deleteMark(_ mark: Mark) {
        let markRegion = region(ofMark: mark)
        normalizeAllMarks()
        // FIXME: do we need to unregister mark?
        unregisterMark(mark)
        if let index = markRegion.marks.firstIndex(where: {$0 === mark}) {
            markRegion.marks.remove(at: index)
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
                mark.linkedMarkIDs.remove(id: id)
            }
        }
    }

    // Clear ladder of all marks.
    func clear() {
        for region in regions {
            region.marks.removeAll()
        }
    }

    func clearBlock() {
        for region in regions {
            for mark in region.marks {
                mark.blockSite = .none
            }
        }
    }

    func clearImpulseOrigin() {
        for region in regions {
            for mark in region.marks {
                mark.impulseOriginSite = .none
            }
        }
    }

    func haveDifferentRegions(_ marks: [Mark]) -> Bool {
        if marks.count <= 1 { return false }
        let markRegionIndex = marks[0].regionIndex
        for mark in marks {
            if mark.regionIndex != markRegionIndex {
                return true
            }
        }
        return false
    }

    func marksAreNotContiguous(_ marks: [Mark]) -> Bool {
        if haveDifferentRegions(marks) { return true }
        let markRegionIndex = marks[0].regionIndex
        var entryCounter = 0
        var inMarks = false
        let sortedMarks = region(atIndex: markRegionIndex).marks.sorted()
        for mark in sortedMarks {
            if marks.contains(mark) && !inMarks {
                entryCounter += 1
                inMarks = true
            }
            if !marks.contains(mark) {
                inMarks = false
            }
        }
        return entryCounter != 1
    }

    func marksIntersect(_ marks: [Mark]) -> Bool {
        guard marks.count == 2 else { return false }
        let p1 = marks[0].segment.proximal
        let p2 = marks[0].segment.distal
        let p3 = marks[1].segment.proximal
        let p4 = marks[1].segment.distal
        return Geometry.intersection(ofLineFrom: p1, to: p2, withLineFrom: p3, to: p4) != nil
    }

    func marksAreVertical(_ marks: [Mark]) -> Bool {
        for mark in marks {
            if !markIsVertical(mark) {
                return false
            }
        }
        return true
    }

    func difference(_ m1: Mark, _ m2: Mark) -> CGFloat {
        let proxDiff = abs(m1.segment.proximal.x - m2.segment.proximal.x)
        let distDiff = abs(m1.segment.distal.x - m2.segment.distal.x)
        return min(proxDiff, distDiff)
    }

    func markIsVertical(_ mark: Mark) -> Bool {
        return mark.segment.proximal.x == mark.segment.distal.x
    }

    func marksAreParallel(_ m1: Mark, _ m2: Mark) -> Bool {
        return Geometry.areParallel(m1.segment, m2.segment)
    }

    func meanCL(_ marks: [Mark]) -> CGFloat {
        guard marks.count > 1 else { return 0 }
        let sortedMarks = marks.sorted()
        let proximalSortedMarks = sortedMarks.filter { $0.segment.proximal.y <= 0 }
        var intervalSum: CGFloat = 0
        for i in 0..<proximalSortedMarks.count {
            if i + 1 < proximalSortedMarks.count {
                intervalSum += proximalSortedMarks[i+1].segment.proximal.x - proximalSortedMarks[i].segment.proximal.x
            }
        }
        return intervalSum / CGFloat(proximalSortedMarks.count - 1)
    }

    func index(ofRegion region: Region?) -> Int? {
        guard let region = region else { return nil }
        return regions.firstIndex(of: region)
    }

    func regionIndex(ofMark mark: Mark) -> Int {
        let index = mark.regionIndex
        return index
    }

    func region(atIndex index: Int) -> Region {
        precondition(index < regions.count && index >= 0, "Region index out of range")
        return regions[index]
    }

    func region(ofMark mark: Mark) -> Region {
        return region(atIndex: regionIndex(ofMark: mark))
    }

    func regionBefore(region: Region) -> Region? {
        guard let index = index(ofRegion: region) else { return nil }
        if index > 0 {
            return regions[index - 1]
        }
        else { return nil }
    }

    func regionAfter(region: Region) -> Region? {
        guard let index = index(ofRegion: region) else { return nil}
        if index < regions.count - 1 {
            return regions[index + 1]
        }
        else { return nil }
    }

    func setModeForLinkedMarkIDs(mode: Mark.Mode, linkedMarkIDs: LinkedMarkIDs) {
        let linkedMarks = getLinkedMarks(fromLinkedMarkIDs: linkedMarkIDs)
        linkedMarks.setMode(mode)
    }

    func normalizeAllMarks() {
        setAllMarksWithMode(.normal)
    }

    func normalizeRegions() {
        setAllRegionsWithMode(.normal)
    }

    func normalize() {
        normalizeAllMarks()
        normalizeRegions()
    }

    func setAllRegionsWithMode(_ mode: Region.Mode) {
        regions.forEach { $0.mode = mode }
    }

    // Will have ladder store and set mark modes
    func setAllMarksWithMode(_ mode: Mark.Mode) {
        regions.forEach {
            region in region.marks.forEach { mark in mark.mode = mode }
        }
    }

    func clearSelectedLabels() {
        for region in regions {
            if region.mode == .labelSelected {
                region.mode = .normal
            }
        }
    }

    func setMarksWithMode(_ mode: Mark.Mode, inRegion region: Region) {
        region.marks.forEach { mark in mark.mode = mode }
    }

    func setMarksWithMode(_ mode: Mark.Mode, inRegions regions: [Region]) {
        regions.forEach { region in region.marks.forEach { mark in mark.mode = mode }}
    }

    func hideZone() {
        zone.start = 0
        zone.end = 0
        zone.isVisible = false
    }

    func marksWithMode(_ mode: Mark.Mode, inRegion region: Region) -> [Mark] {
        let marks = region.marks.filter { mark in mark.mode == mode }
        return marks
    }

    func allMarks() -> [Mark] {
        var allMarks = [Mark]()
        regions.forEach { region in region.marks.forEach { mark in allMarks.append(mark) } }
        return allMarks
    }

    func allMarksWithMode(_ mode: Mark.Mode) -> [Mark] {
        var marks = [Mark]()
        for region in regions {
            marks.append(contentsOf: marksWithMode(mode, inRegion: region))
        }
        return marks
    }

    func allRegionsWithMode(_ mode: Region.Mode) -> [Region] {
        return regions.filter { $0.mode == mode }
    }

    func ladderIntervals() -> [Int: [Interval]] {
        var indexedIntervals: [Int: [Interval]] = [:]
        for i in 0..<regions.count {
            indexedIntervals[i] = Interval.createIntervals(region: regions[i])
        }
        return indexedIntervals
    }

    func regionIntervals(region: Region) -> [Interval] {
        return Interval.createIntervals(region: region)
    }


    func availableAnchors(forMark mark: Mark) -> [Anchor] {
        let linkedMarkIDs = mark.linkedMarkIDs
        // FIXME: if attachment is in middle, only allow other end to move
        if linkedMarkIDs.count < 2 {
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
        // No pivot points, i.e. full freedom of movement if no linked marks.
        if mark.linkedMarkIDs.count == 0 {
            return []
        }
        if mark.linkedMarkIDs.proximal.count > 0 && mark.linkedMarkIDs.distal.count > 0 {
            return [.proximal, .distal]
        }
        else if mark.linkedMarkIDs.proximal.count > 0 {
            return [.distal]
        }
        else if mark.linkedMarkIDs.distal.count > 0 {
            return [.proximal]
        }
        // TODO: deal with middle marks
        return []
    }

    func moveLinkedMarks(forMark mark: Mark) {
        for proximalMark in getMarkSet(fromMarkIdSet: mark.linkedMarkIDs.proximal) {
            proximalMark.segment.distal.x = mark.segment.proximal.x
        }
        for distalMark in getMarkSet(fromMarkIdSet: mark.linkedMarkIDs.distal) {
            distalMark.segment.proximal.x = mark.segment.distal.x
        }
        for middleMark in getMarkSet(fromMarkIdSet:mark.linkedMarkIDs.middle) {
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

    func removeRegion(_ region: Region) {
        regions.removeAll(where: { $0 == region })
        reindexMarks()
        // relink marks
    }

    func unlinkAllMarks() {
        regions.forEach {
            region in region.marks.forEach {
                mark in mark.linkedMarkIDs.removeAll()
            }

        }
    }

    func reindexMarks() {
        for region in regions {
            for mark in region.marks {
                mark.regionIndex = index(ofRegion: region) ?? -1
            }
        }
    }

    // Returns a basic ladder (A, AV, V).
    static func defaultLadder() -> Ladder {
        return Ladder(template: LadderTemplate.defaultTemplate())
    }

    static func freshLadder(fromLadder ladder: Ladder) -> Ladder {
        return Ladder(template: ladder.template )
    }
}

// MARK: - enums

// Is a mark in the region before, same region, region after, or farther away?
enum RegionRelation {
    case before
    case same
    case after
    case distant
}

enum TemporalRelation {
    case before
    case after
    case both
}



//
//  Ladder.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import os.log

struct NearbyMarks {
    var proximal = [Mark]()
    var middle = [Mark]()
    var distal = [Mark]()
}

// A Ladder is simply a collection of Regions in top bottom order.
class Ladder: Codable {
    private typealias Registry = Dictionary<UUID, Int>

    private var registry: Registry = [:]

    var template: LadderTemplate
    var name: String { template.name }
    // This holds the optional description for the diagram.  It is stored here rather than in Diagram because Diagram is not Codable while Ladder is and so it is easier to serialize the description via Ladder.
    var description: String = ""
    var templateDescription: String { template.description }
    var regions = [Region]()
    var numRegions: Int { regions.count }
    var attachedMark: Mark?
    var pressedMark: Mark?
    var movingMark: Mark?
    var selectedMarks = [Mark]()
    var linkedMarks = [Mark]()
    // isDirty will be true if f any changes made to ladder, even if they are reverted back.
    var isDirty: Bool = false
    // marksAreVisible shows and hides all the marks.  You can toggle this for teaching purposes.
    var marksAreVisible: Bool = true

    var zone: Zone?

    var id = UUID()

    init(template: LadderTemplate) {
        self.template = template
        for regionTemplate in template.regionTemplates {
            let region = Region(template: regionTemplate)
            regions.append(region)
        }
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
    
    // TODO: Does region have to be optional?  Consider refactor away optionality.
    // addMark() functions.  All require a Region in which to add the mark.  Each new mark is registered to that region.  All return addedMark or nil if region is nil.
    func addMark(at positionX: CGFloat, inRegion region: Region?) -> Mark? {
        return registerAndAppendMark(Mark(positionX: positionX), toRegion: region)
    }

    func addMark(fromSegment segment: Segment, inRegion region: Region?) -> Mark? {
        let mark = Mark(segment: segment)
        return registerAndAppendMark(mark, toRegion: region)
    }

    private func registerAndAppendMark(_ mark: Mark, toRegion region: Region?) -> Mark? {
        os_log("registerAndAppendMark(_:toRegion:) - Ladder", log: .action, type: .info)
        guard let region = region else { return nil }
        mark.lineStyle = region.lineStyle
        region.appendMark(mark)
        registry[mark.id] = getIndex(ofRegion: region)
        isDirty = true
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

    // Clear ladder of all marks.
    func clear() {
        registry.removeAll()
        for region in regions {
            region.marks.removeAll()
        }
    }

    func getIndex(ofRegion region: Region?) -> Int? {
        guard let region = region else { return nil }
        return regions.firstIndex(of: region)
//        return region.index
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
        return Ladder(template: LadderTemplate.defaultTemplate())
    }
}

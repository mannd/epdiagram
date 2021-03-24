//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import OSLog

final class LadderView: ScaledView {

    // For debugging
    #if DEBUG  // Change this for debugging impulse origins and block
    var showProxEnd = false
    var showEarliestPoint = false
    var debugMarkMode = false
    #else  // Don't ever change this.  They must all be FALSE.
    var showProxEnd = false
    var showEarliestPoint = false
    var debugMarkMode = false
    #endif

    // TODO: These all may need some tweaking...
    private let ladderPaddingMultiplier: CGFloat = 0.5
    private let accuracy: CGFloat = 20
    private let lowerLimitMarkHeight: CGFloat = 0.1
    private let lowerLimitMarkWidth: CGFloat = 20
    private let nearbyMarkAccuracy: CGFloat = 15
    private let arrowHeadAngle = CGFloat(Double.pi / 6)
    private let maxRegionMeasurements = 20
    private let intervalMargin: CGFloat = 10
    private let maxMarksForIntervals = 50   // If more than this number of marks in a region, don't draw intervals.
    var blockMin: CGFloat = 0.1
    var blockMax: CGFloat = 0.9

    lazy var measurementTextAttributes: [NSAttributedString.Key: Any] = {
        let textFont = UIFont(name: "Helvetica Neue Medium", size: 14.0) ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        let attributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: UIColor.label,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
        ]
        return attributes
    }()

    // Controlled by Preferences
    var markLineWidth: CGFloat = 2
    var showImpulseOrigin = true
    var showBlock = true
    var showArrows = false
    var showPivots = false
    var showIntervals = true
    var showConductionTimes = true
    var showMarkText = true
    var snapMarks = true
    var defaultMarkStyle = Mark.Style.solid {
        didSet {
            ladder.defaultMarkStyle = defaultMarkStyle
        }
    }
    var showLabelDescription: TextVisibility = .invisible
    var marksAreHidden: Bool = false
    var doubleLineBlockMarker: Bool = true
    var hideZeroCT: Bool = false

    // Colors - can change via Preferences
    var activeColor = Preferences.defaultActiveColor
    var attachedColor = Preferences.defaultAttachedColor
    var connectedColor = Preferences.defaultConnectedColor
    var selectedColor = Preferences.defaultSelectedColor
    var linkedColor = Preferences.defaultLinkedColor

    var normalColor = UIColor.label  // normalColor is not changeable via Preferences

    var ladderIsLocked = false

    var zone: Zone {
        get { return ladder.zone }
        set { ladder.zone = newValue }
    }
    let zoneColor = UIColor.systemBlue
    var calibration: Calibration?
    var ladder: Ladder = Ladder.defaultLadder()
    var activeRegion: Region? {
        get { ladder.activeRegion }
        set { ladder.activeRegion = newValue }
    }
    var caliperMaxY: CGFloat {
        get { cursorViewDelegate.caliperMaxY }
        set { cursorViewDelegate.caliperMaxY = newValue }
    }
    private var movingMark: Mark?
    private var regionOfDragOrigin: Region?
    private var regionProximalToDragOrigin: Region?
    private var regionDistalToDragOrigin: Region?
    private var dragCreatedMark: Mark?
    private var dragOriginDivision: RegionDivision = .none
    var isDragging: Bool = false
    var isDraggingSelectedMarks: Bool = false
    var diffs: [Mark: CGFloat] = [:]
    var movementDiffs: [Mark: (prox: CGFloat, distal: CGFloat)] = [:]

    var ladderIntervals: [Int: [Interval]] = [:]

    private var savedActiveRegion: Region?
    private var savedMode: Mode = .normal

    var mode: Mode = .normal

    var leftMargin: CGFloat = 0
    var viewHeight: CGFloat = 0
    // viewMaxWidth is width of image, or width of ladderView if no image is present
    var viewMaxWidth: CGFloat = 0 { didSet { viewMaxWidth = max(viewMaxWidth, frame.width) } }
    private var regionUnitHeight: CGFloat = 0

    weak var cursorViewDelegate: CursorViewDelegate! // Note IUO.
    var currentDocument: DiagramDocument?

    override var canBecomeFirstResponder: Bool { return true }

    // MARK: - init

    required init?(coder aDecoder: NSCoder) {
        os_log("init(coder:) - LadderView", log: .viewCycle, type: .info)
        super.init(coder: aDecoder)
        setupView()
    }

    // used for unit testing
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    func reset() {
        os_log("reset() - LadderView", log: .action, type: .info)
    }

    private func setupView() {
        os_log("setupView() - LadderView", log: .action, type: .info)
        // FIXME: needs to be done later
//        ladder.reregisterAllMarks()
        viewHeight = self.frame.height
        initializeRegions()
        removeConnectedMarks()
        // FIXME: snap marks on startup

        // Draw border around view.
        layer.masksToBounds = true
        layer.borderColor = UIColor.systemBlue.cgColor
        layer.borderWidth = 2

        // Set up touches.
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTapRecognizer)

        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        self.addGestureRecognizer(doubleTapRecognizer)

        let draggingPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.dragging))
        self.addGestureRecognizer(draggingPanRecognizer)
    }

    func initializeRegions(setActiveRegion: Bool = true) {
        regionUnitHeight = getRegionUnitHeight(ladder: ladder)
        var regionBoundary = regionUnitHeight * ladderPaddingMultiplier
        for region: Region in ladder.regions {
            let regionHeight = CGFloat(region.unitHeight) * regionUnitHeight
            region.proximalBoundaryY = regionBoundary
            region.distalBoundaryY = regionBoundary + regionHeight
            regionBoundary += regionHeight
        }
        guard ladder.regions.count > 0 else { assertionFailure("ladder.regions has no regions!"); return }
        if setActiveRegion && mode == .normal {
            activeRegion = ladder.region(atIndex: 0)
        }
    }

    internal func getRegionUnitHeight(ladder: Ladder) -> CGFloat {
        var numRegionUnits = 0
        for region: Region in ladder.regions {
            numRegionUnits += region.unitHeight
        }
        // we need padding above and below, so...
        let padding = Int(ladderPaddingMultiplier * 2)
        numRegionUnits += padding
        return viewHeight / CGFloat(numRegionUnits)
    }

    // MARK: - Touches

    @objc func singleTap(tap: UITapGestureRecognizer) {
        os_log("singleTap(tap:) - LadderView", log: OSLog.touches, type: .info)
        guard !marksAreHidden else { return }
        let position = tap.location(in: self)
        let tapLocationInLadder = getLocationInLadder(position: position)
        switch mode {
        case .select:
            selectModeSingleTap(tapLocationInLadder)
        case .connect:
            connectModeSingleTap(tapLocationInLadder)
        case .normal:
            normalModeSingleTap(tapLocationInLadder)
        default: // other modes don't respond to single tap
            break
        }
    }

    func normalModeSingleTap(_ tapLocationInLadder: LocationInLadder) {
        if tapLocationInLadder.specificLocation == .label {
            assert(tapLocationInLadder.region != nil, "Label tapped, but region is nil!")
            if let region = tapLocationInLadder.region {
                labelWasTapped(labelRegion: region)
                hideCursorAndNormalizeAllMarks()
                unattachAttachedMark()
            }
        }
        else if (tapLocationInLadder.region != nil) { // tap is in a region
            regionWasTapped(tapLocationInLadder: tapLocationInLadder, positionX: tapLocationInLadder.unscaledPosition.x)
        }
        cursorViewDelegate.refresh()
        setNeedsDisplay()
    }

    private func hideCursorAndNormalizeAllMarks() {
        guard cursorViewDelegate.cursorIsVisible else { return }
        cursorViewDelegate.cursorIsVisible = false
        normalizeAllMarks()
    }

    /// Magic function that returns struct indicating in what part of ladder a point is.
    /// - Parameter position: point to be processed
    func getLocationInLadder(position: CGPoint) -> LocationInLadder {
        var tappedRegion: Region?
        var tappedMark: Mark?
        var tappedRegionSection: RegionSection = .markSection
        var tappedDivision: RegionDivision = .none
        var tappedAnchor: Anchor?
        var tappedZone: Zone?
        for region in ladder.regions {
            if position.y > region.proximalBoundaryY && position.y < region.distalBoundaryY {
                tappedRegion = region
                tappedDivision = tappedRegionDivision(region: region, positionY: position.y)
            }
        }
        if position.x > min(zone.start, zone.end) && position.x < max(zone.start, zone.end), let tappedRegion = tappedRegion {
            if ladder.zone.regions.firstIndex(of: tappedRegion) != nil {
                tappedZone = zone
            }
        }
        if let tappedRegion = tappedRegion {
            if position.x < leftMargin {
                tappedRegionSection = .labelSection
            }
            else {
                tappedRegionSection = .markSection
                outerLoop: for mark in tappedRegion.marks {
                    if nearMark(position: position, mark: mark, region: tappedRegion, accuracy: accuracy) {
                        tappedMark = mark
                        tappedAnchor = nearestAnchor(position: position, mark: mark)
                        break outerLoop
                    }
                }
            }
        }
        let location = LocationInLadder(region: tappedRegion, mark: tappedMark, ladder: ladder, zone: tappedZone, regionSection: tappedRegionSection, regionDivision: tappedDivision, markAnchor: tappedAnchor, unscaledPosition: position)
        return location
    }

    private func tappedRegionDivision(region: Region, positionY: CGFloat) -> RegionDivision {
        guard  positionY > region.proximalBoundaryY && positionY < region.distalBoundaryY else {
            return .none
        }
        if positionY < region.proximalBoundaryY + 0.25 * (region.distalBoundaryY - region.proximalBoundaryY) {
            return .proximal
        }
        else if positionY < region.proximalBoundaryY + 0.75 * (region.distalBoundaryY - region.proximalBoundaryY) {
            return .middle
        }
        else {
            return .distal
        }
    }

    func labelWasTapped(labelRegion: Region) {
        if labelRegion.mode == .active {
            activeRegion = nil
        }
        else {
            activeRegion = labelRegion
        }
    }

    private func regionWasTapped(tapLocationInLadder: LocationInLadder, positionX: CGFloat) {
        assert(tapLocationInLadder.region != nil, "Region tapped, but is nil!")
        if let tappedRegion = tapLocationInLadder.region {
            if tappedRegion.mode != .active {
                activeRegion = tappedRegion
            }
            if let mark = tapLocationInLadder.mark {
                markWasTapped(mark: mark, tapLocationInLadder: tapLocationInLadder)
            }
            else if cursorViewDelegate.cursorIsVisible {
                hideCursorAndNormalizeAllMarks()
                unattachAttachedMark()
            }
            else { // make mark and attach cursor
                let mark = addMarkToActiveRegion(scaledViewPositionX: positionX)
                if let mark = mark {
                    undoablyAddMark(mark: mark)
                    normalizeAllMarks()
                    mark.anchor = ladder.defaultAnchor(forMark: mark)
                    attachMark(mark)
                    cursorViewDelegate.setCursorHeight()
                    cursorViewDelegate.moveCursor(cursorViewPositionX: mark.segment.proximal.x)
                    cursorViewDelegate.cursorIsVisible = true
                }
            }
        }
    }

    private func markWasTapped(mark: Mark?, tapLocationInLadder: LocationInLadder) {
        if let mark = mark {
            if mark.mode == .attached {
                attachMark(mark)
                // TODO: Consider using RegionDivision to position Anchor.  Tapping on cursor it makes sense to just toggle the anchor, but tapping on the mark itself it might be better to position anchor near where you tap.  On other hand, it might be easy to miss the mark division zone.  Also, if not all anchors are available (say the .middle anchor is missing), which anchor do you switch to?  Maybe default to toggleAnchor() if anchor not available.
                toggleAnchor(mark: mark)
                adjustCursor(mark: mark)
                cursorViewDelegate.cursorIsVisible = true
            }
            else { // mark wasn't already attached.
                normalizeAllMarks()
                attachMark(mark)
                mark.anchor = ladder.defaultAnchor(forMark: mark)
                adjustCursor(mark: mark)
                cursorViewDelegate.cursorIsVisible = true
            }
        }
    }

    private func connect(marksToConnect marks: [Mark]) -> Mark? {
        // Should not be called unless two marks to connect are in marks.
        guard marks.count == 2 else { return nil }
        // None of the region indices can be out of range, given the guard above.
        let firstRegionIndex = ladder.regionIndex(ofMark: marks[0])
        let secondRegionIndex = ladder.regionIndex(ofMark: marks[1])
        let regionDifference = secondRegionIndex - firstRegionIndex
        // ignore same region for now.  Only allow diff of 2 regions
        if abs(regionDifference) == 2 {
            if regionDifference > 0 {
                // If first and secondRegionIndex aren't out of range, markRegion can't be either.
                let markRegion = ladder.region(atIndex: firstRegionIndex + 1)
                let segment = Segment(proximal: CGPoint(x: marks[0].segment.distal.x, y: 0), distal: CGPoint(x: marks[1].segment.proximal.x, y: 1.0))
                let mark = ladder.addMark(fromSegment: segment, toRegion: markRegion)
                undoablyAddMark(mark: mark)
                return mark
            }
            if regionDifference < 0 {
                let markRegion = ladder.region(atIndex: firstRegionIndex - 1)
                let segment = Segment(proximal: CGPoint(x: marks[1].segment.distal.x, y: 0), distal: CGPoint(x: marks[0].segment.proximal.x, y: 1.0))
                let mark = ladder.addMark(fromSegment: segment, toRegion: markRegion)
                undoablyAddMark(mark: mark)
                return mark
            }
        }
        return nil
    }

    private func connectTappedMark(_ mark: Mark) {
        switch ladder.connectedMarks.count {
        case 2...:
            ladder.connectedMarks.removeAll()
            normalizeAllMarks()
            ladder.connectedMarks.append(mark)
            mark.mode = .connected
            return
        case 0:
            ladder.connectedMarks.append(mark)
            mark.mode = .connected
            return
        case 1:
            guard mark != ladder.connectedMarks[0] else { return }
            // different mark tapped
            // what region is the mark in?
            let markRegionIndex = ladder.regionIndex(ofMark: mark)
            let firstMarkRegionIndex = ladder.regionIndex(ofMark: ladder.connectedMarks[0])
            let regionDistance = abs(markRegionIndex - firstMarkRegionIndex)
            if regionDistance > 1 {
                ladder.connectedMarks.append(mark)
                mark.mode = .connected
                if let connectedMark = connect(marksToConnect: ladder.connectedMarks) {
                    ladder.connectedMarks.append(connectedMark)
                    connectedMark.mode = .connected
                    linkConnectedMarks()
                    assessBlockAndImpulseOrigin(mark: connectedMark)
                    let linkedMarks = ladder.getLinkedMarksFromLinkedMarkIDs(connectedMark.linkedMarkIDs)
                    assessBlockAndImpulseOrigin(marks: linkedMarks.allMarks)
                }
            }
        default:
            assertionFailure("Impossible connected mark count.")
        }
    }

    func removeConnectedMarks() {
        ladder.connectedMarks.removeAll()
    }

    fileprivate func addBlockedMark(newMark: Mark, tapRegionPosition: CGPoint, endPoint: Mark.Endpoint) {
        switch endPoint {
        case .distal:
            newMark.segment.distal = tapRegionPosition
        case .proximal:
            newMark.segment.proximal = tapRegionPosition
        default:
            fatalError("Connection endpoint of mark can't be .none.")
        }
        newMark.mode = .connected
        ladder.connectedMarks.append(newMark)
        currentDocument?.undoManager.beginUndoGrouping()
        undoablyAddMark(mark: newMark)
        let newNearbyMarks = getNearbyMarkIDs(mark: newMark)
        linkNearbyMarks(mark: newMark, nearbyMarks: newNearbyMarks)
        currentDocument?.undoManager.endUndoGrouping()
    }

    func connectTappedMarkToBlockedMark(position: CGPoint, region: Region) {
        // Regions are only used if a first mark is already chosen.
        guard ladder.connectedMarks.count == 1 else { return }
        let firstTappedMark = ladder.connectedMarks[0]
        // Region must be adjacent to the first mark.
        let firstTappedMarkRegionIndex = ladder.regionIndex(ofMark: firstTappedMark)
        guard let regionIndex = ladder.index(ofRegion: region),
              abs(firstTappedMarkRegionIndex - regionIndex) == 1 else { return }
        // draw mark from end of previous connecteded mark
        let tapRegionPosition = transformToRegionPosition(scaledViewPosition: position, region: region)
        if firstTappedMarkRegionIndex < regionIndex {
            // marks must reach close enough to region boundary to be snapable
            guard firstTappedMark.segment.distal.y > (1.0 - lowerLimitMarkHeight) else { return }
            let newMark = ladder.addMark(at: firstTappedMark.segment.distal.x, toRegion: region)
            addBlockedMark(newMark: newMark, tapRegionPosition: tapRegionPosition, endPoint: .distal)
        }
        else if firstTappedMarkRegionIndex > regionIndex {
            guard firstTappedMark.segment.proximal.y < lowerLimitMarkHeight else { return }
            let newMark = ladder.addMark(at: firstTappedMark.segment.proximal.x, toRegion: region)
            addBlockedMark(newMark: newMark, tapRegionPosition: tapRegionPosition, endPoint: .proximal)

        }
        else {
            ladder.connectedMarks.removeAll()
        }
    }

    private func connectModeSingleTap(_ tapLocationInLadder: LocationInLadder) {
        if let mark = tapLocationInLadder.mark {
            connectTappedMark(mark)
        }
        else if let region = tapLocationInLadder.region {
            connectTappedMarkToBlockedMark(position: tapLocationInLadder.unscaledPosition, region: region)
        }
        setNeedsDisplay()
    }

    private func selectModeSingleTap(_ tapLocationInLadder: LocationInLadder) {
        if ladder.zone.isVisible {
            // This deselects all selected marks, even those outside zone, which means you can't combine zone selection with region or mark selection, but this seems like the best solution for now.
            ladder.setAllMarksWithMode(.normal)
            ladder.hideZone()
            setNeedsDisplay()
            return
        }
        switch tapLocationInLadder.specificLocation {
        case .mark:
            if let mark = tapLocationInLadder.mark {
                mark.mode = mark.mode == .selected ? .normal : .selected
            }
        case .region, .label: // single tap on label highlights view
            if let region = tapLocationInLadder.region {
                region.mode = region.mode == .selected ? .normal : .selected
                ladder.setMarksWithMode(region.mode == .selected ? .selected : .normal, inRegion: region)
            }
        case .zone:
            selectInZone()
        case .ladder:
            break // ladder selection no longer does anything
        default:
            break
        }
        setNeedsDisplay()
    }

    func adjustCursor(mark: Mark) {
        let anchorPosition = mark.getAnchorPosition()
        let theRegion = ladder.region(ofMark: mark)
        let scaledAnchorPositionY = transformToScaledViewPosition(regionPosition: anchorPosition, region: theRegion).y
        cursorViewDelegate.moveCursor(cursorViewPositionX: anchorPosition.x)
        cursorViewDelegate.setCursorHeight(anchorPositionY: scaledAnchorPositionY)
    }

    /// - Parameters:
    ///   - position: position of, say a tap on the screen
    ///   - mark: mark to check for proximity
    ///   - region: region in which mark is located
    ///   - accuracy: how close does it have to be?
    func nearMark(position: CGPoint, mark: Mark, region: Region, accuracy: CGFloat) -> Bool {
        let scaledViewMarkSegment = transformToScaledViewSegment(regionSegment: mark.segment, region: region)
        let distance = Geometry.distanceSegmentToPoint(segment: scaledViewMarkSegment, point: position)
        return distance < accuracy
    }

    func positionIsNearMark(position: CGPoint) -> Bool {
        return getLocationInLadder(position: position).specificLocation == .mark
    }

    /// Determine which anchor a point is closest to.
    /// - Parameters:
    ///   - point: a point in ladder view coordinates
    ///   - mark: mark to check for proximity
    ///   - region: region in which mark is located
    func nearestAnchor(position: CGPoint, mark: Mark) -> Anchor? {
        let region = ladder.region(ofMark: mark)
        let regionPoint = transformToRegionPosition(scaledViewPosition: position, region: region)
        let proximalDistance = CGPoint.distanceBetweenPoints(mark.segment.proximal, regionPoint)
        let middleDistance = CGPoint.distanceBetweenPoints(mark.midpoint(), regionPoint)
        let distalDistance = CGPoint.distanceBetweenPoints(mark.segment.distal, regionPoint)
        let minimumDistance = min(proximalDistance, middleDistance, distalDistance)
        if minimumDistance == proximalDistance {
            return .proximal
        }
        else if minimumDistance == middleDistance {
            return .middle
        }
        else if minimumDistance == distalDistance {
            return .distal
        }
        else {
            return nil
        }
    }

    func addMarkToActiveRegion(scaledViewPositionX: CGFloat) -> Mark? {
        os_log("addMarkToActiveRegion(scaledViewPositionX:) - LadderView", log: OSLog.touches, type: .info)
        return addMarkToActiveRegion(regionPositionX: transformToRegionPositionX(scaledViewPositionX: scaledViewPositionX))
    }

    func addMarkToActiveRegion(regionPositionX: CGFloat) -> Mark? {
        os_log("addMarkToActiveRegion(regionPositionX:) - LadderView", log: OSLog.touches, type: .info)
        guard let activeRegion = activeRegion else {
            return nil
        }
        let mark = ladder.addMark(at: regionPositionX, toRegion: activeRegion)
        mark.mode = .attached
        return mark
    }

    @available(*, deprecated, message: "Used for setting anchor depending on tap location, not used.")
    func getAnchor(regionDivision: RegionDivision) -> Anchor? {
        let anchor: Anchor?
        switch regionDivision {
        case .proximal:
            anchor = .proximal
        case .middle:
            anchor = .middle
        case .distal:
            anchor = .distal
        case .none:
            anchor = nil
        }
        return anchor
    }

    func toggleAnchor(mark: Mark?) {
        ladder.toggleAnchor(mark: mark)
    }

    // This is already done when attachedMark is set in the ladder, so...
    // FIXME: This still appears necessary.  Need fundamental analysis of mark highlighting, linking.
    func setAttachedMarkAndLinkedMarksModes() {
        os_log("setAttachedMarkAndLinkedMarksModes( - LadderView", log: OSLog.deprecated, type: .debug)
        if let attachedMark = ladder.attachedMark {
            let linkedMarkIDs = attachedMark.linkedMarkIDs
            // Note that the order below is important.  An attached mark can be in its own linkedMarks.  But we always want the attached mark to have an .attached highlight.
            ladder.normalizeAllMarks()
            ladder.setModeForMarkIDs(mode: .linked, markIDs: linkedMarkIDs)

            attachedMark.mode = .attached
        }
    }

    // FIXME: Not used?
    func setAttachedMarkAndNearbyMarksMode(nearbyMarkIDs: LinkedMarkIDs) {
        os_log("setAttachedMarkAndNearbyMarksMode( - LadderView", log: OSLog.deprecated, type: .debug)
        if let attachedMark = ladder.attachedMark {

            // Note that the order below is important.  An attached mark can be in its own linkedMarks.  But we always want the attached mark to have an .attached highlight.
            ladder.normalizeAllMarks()
            ladder.setModeForMarkIDs(mode: .linked, markIDs: nearbyMarkIDs)
            attachedMark.mode = .attached
        }
    }

    func attachMark(_ mark: Mark?) {
        os_log("attachMark(_:) - LadderView", log: OSLog.action, type: .info)
        ladder.attachedMark = mark
    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        os_log("doubleTap(tap:) - LadderView", log: OSLog.touches, type: .info)
        guard !marksAreHidden else { return }
        switch mode {
        case .normal:
            deleteOrAddMark(position: tap.location(in: self), cursorViewDelegate: cursorViewDelegate)
            setNeedsDisplay()
        case .select:
            deleteMarkSelectMode(position: tap.location(in: self))
            setNeedsDisplay()
        default:
            break
        }
    }

    // Double tap just deletes in Select mode, doesn't add mark.
    func deleteMarkSelectMode(position: CGPoint) {
        let tapLocationInLadder = getLocationInLadder(position: position)
        if tapLocationInLadder.specificLocation == .mark {
            if let mark = tapLocationInLadder.mark {
                undoablyDeleteMark(mark: mark)
            }
        }
    }

    /// Deletes mark if there is one at position.  Returns true if position corresponded to a mark.
    /// - Parameter position: position of potential mark
    func deleteOrAddMark(position: CGPoint, cursorViewDelegate: CursorViewDelegate) {
        os_log("deleteMark(position:cursofViewDelegate:) - LadderView", log: OSLog.debugging, type: .debug)
        let tapLocationInLadder = getLocationInLadder(position: position)
        activeRegion = tapLocationInLadder.region
        // Don't allow adding or deleting marks in label area, though ok to have label double tap set active region.
        guard tapLocationInLadder.specificLocation != .label else { return }
        if tapLocationInLadder.specificLocation == .mark {
            if let mark = tapLocationInLadder.mark {
                undoablyDeleteMark(mark: mark)
            }
        } else if let region = tapLocationInLadder.region {
            let scaledPositionX = transformToRegionPositionX(scaledViewPositionX: tapLocationInLadder.unscaledPosition.x)
            let mark = ladder.addMark(at: scaledPositionX, toRegion: region)
            normalizeAllMarks()
            undoablyAddMark(mark: mark)
            attachMark(mark)
            cursorViewDelegate.moveCursor(cursorViewPositionX: scaledPositionX)
            cursorViewDelegate.cursorIsVisible = true
            cursorViewDelegate.setCursorHeight()
            cursorViewDelegate.refresh()
        }
    }

    // See https://stackoverflow.com/questions/36491789/using-nsundomanager-how-to-register-undos-using-swift-closures/36492619#36492619
    func undoablyDeleteMark(mark: Mark) {
        os_log("undoablyDeleteMark(mark:region:) - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.redoablyUndeleteMark(mark: mark)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)

        ladder.deleteMark(mark)
        let linkedMarks = ladder.getLinkedMarksFromLinkedMarkIDs(mark.linkedMarkIDs)
        let region = ladder.region(ofMark: mark)
        updateMarkersAndRegionIntervals(region)
        hideCursorAndNormalizeAllMarks()
        // ?no need to link nearby marks, but need to update links of neighboring marks
        assessBlockAndImpulseOrigin(marks: linkedMarks.allMarks)
    }

    func redoablyUndeleteMark(mark: Mark) {
        os_log("redoablyUndeleteMark(mark:region:) - LadderView", log: OSLog.debugging, type: .debug)

        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.undoablyDeleteMark(mark: mark)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        let region = ladder.region(ofMark: mark)
        ladder.addMark(mark, toRegion: region)
        mark.mode = .normal
        updateMarkersAndRegionIntervals(region)
        hideCursorAndNormalizeAllMarks()
        let newNearbyMarks = getNearbyMarkIDs(mark: mark)
        snapToNearbyMarks(mark: mark, nearbyMarks: newNearbyMarks)
        linkNearbyMarks(mark: mark, nearbyMarks: newNearbyMarks)
    }

    private func undoablyAddMark(mark: Mark) {
        os_log("undoablyAddMark(mark:) - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.undoablyDeleteMark(mark: mark)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        updateMarkersAndRegionIntervals(ladder.region(ofMark: mark))
        assessBlockAndImpulseOrigin(mark: mark)
        let linkedMarks = ladder.getLinkedMarksFromLinkedMarkIDs(mark.linkedMarkIDs)
        assessBlockAndImpulseOrigin(marks: linkedMarks.allMarks)
    }

    private func normalModeDrag(_ pan: UIPanGestureRecognizer) {
        let position = pan.location(in: self)
        let state = pan.state
        let locationInLadder = getLocationInLadder(position: position)

        if state == .began {
            isDragging = true
            currentDocument?.undoManager?.beginUndoGrouping()
            // Activate region and get regions proximal and distal.
            if let region = locationInLadder.region {
                regionOfDragOrigin = region
                regionProximalToDragOrigin = ladder.regionBefore(region: region)
                regionDistalToDragOrigin = ladder.regionAfter(region: region)
                activeRegion = region
            }
            if let regionOfDragOrigin = regionOfDragOrigin {
                if let mark = locationInLadder.mark, mark.mode == .attached { // move attached mark
                    movingMark = mark
                    setAttachedMarkAndLinkedMarksModes()
                    // NB: Need to move it nowhere, to let undo get back to starting position!
                    if let anchorPosition = getMarkScaledAnchorPosition(mark) {
                        moveMark(mark: mark, scaledViewPosition: anchorPosition)
                    }
                }
                else {  // We need to make a new mark.
                    hideCursorAndNormalizeAllMarks()
                    unattachAttachedMark()
                    // Get the third of region for endpoint of new mark.
                    dragOriginDivision = locationInLadder.regionDivision
                    switch dragOriginDivision {
                    case .proximal:
                        dragCreatedMark = addMarkToActiveRegion(scaledViewPositionX: position.x)
                        dragCreatedMark?.segment.proximal.y = 0
                        dragCreatedMark?.segment.distal.y = 0.5
                    case .middle:
                        dragCreatedMark = addMarkToActiveRegion(scaledViewPositionX: position.x)
                        // TODO: REFACTOR
                        dragCreatedMark?.segment.proximal.y = (position.y - regionOfDragOrigin.proximalBoundaryY) / (regionOfDragOrigin.distalBoundaryY - regionOfDragOrigin.proximalBoundaryY)
                        dragCreatedMark?.segment.distal.y = 0.75
                    case .distal:
                        dragCreatedMark = addMarkToActiveRegion(scaledViewPositionX: position.x)
                        dragCreatedMark?.segment.proximal.y = 0.5
                        dragCreatedMark?.segment.distal.y = 1
                    case .none:
                        assert(false, "Making a mark with a .none regionDivision!")
                    }
                    if let dragCreatedMark = dragCreatedMark {
                        undoablyAddMark(mark: dragCreatedMark)
                    }
                    dragCreatedMark?.mode = .attached
                }
            }
        }
        if state == .changed {
            if let mark = movingMark {
                moveMark(mark: mark, scaledViewPosition: position)
                highlightNearbyMarks(mark)
            }
            else if regionOfDragOrigin == locationInLadder.region, let regionOfDragOrigin = regionOfDragOrigin {
                switch dragOriginDivision {
                case .proximal:
                    dragCreatedMark?.segment.distal = transformToRegionPosition(scaledViewPosition: position, region: regionOfDragOrigin)
                case .distal:
                    dragCreatedMark?.segment.proximal = transformToRegionPosition(scaledViewPosition: position, region: regionOfDragOrigin)
                case .middle:
                    dragCreatedMark?.segment.distal = transformToRegionPosition(scaledViewPosition: position, region: regionOfDragOrigin)
                default:
                    break
                }
                highlightNearbyMarks(dragCreatedMark)
            }
            updateMarkersAndRegionIntervals(activeRegion)
        }
        if state == .ended {
//            currentDocument?.undoManager.endUndoGrouping()
            isDragging = false
            if let movingMark = movingMark {
                swapEndsIfNeeded(mark: movingMark)
                let newNearbyMarks = getNearbyMarkIDs(mark: movingMark)
                snapToNearbyMarks(mark: movingMark, nearbyMarks: newNearbyMarks)
                linkNearbyMarks(mark: movingMark, nearbyMarks: newNearbyMarks)
            }
            else if let dragCreatedMark = dragCreatedMark {
                if dragCreatedMark.height < lowerLimitMarkHeight && dragCreatedMark.width < lowerLimitMarkWidth {
                    undoablyDeleteMark(mark: dragCreatedMark)
                }
                else {
                    swapEndsIfNeeded(mark: dragCreatedMark)
                    let newNearbyMarks = getNearbyMarkIDs(mark: dragCreatedMark)
                    snapToNearbyMarks(mark: dragCreatedMark, nearbyMarks: newNearbyMarks)
                    linkNearbyMarks(mark: dragCreatedMark, nearbyMarks: newNearbyMarks)
                }
            }
            currentDocument?.undoManager?.endUndoGrouping()
            if !cursorViewDelegate.cursorIsVisible {
                normalizeAllMarks()
            }
            dragCreatedMark?.mode = .normal
            movingMark = nil
            dragCreatedMark = nil
            regionOfDragOrigin = nil
            regionProximalToDragOrigin = nil
            regionDistalToDragOrigin = nil
            dragOriginDivision = .none
        }
        cursorViewDelegate.refresh()
        setNeedsDisplay()
    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        guard !marksAreHidden else { return }
        switch mode {
        case .select:
            selectModeDrag(pan)
        case .normal:
            normalModeDrag(pan)
        default:
            break
        }
    }

    func selectModeDrag(_ pan: UIPanGestureRecognizer) {
        if isDraggingSelectedMarks {
            selectModeMarksDrag(pan)
        } else {
            selectModeZoneDrag(pan)
        }
    }

    func selectModeMarksDrag(_ pan: UIPanGestureRecognizer) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        ladder.hideZone()
        let location = pan.location(in: self)
        let state = pan.state
        if state == .began {
            isDragging = true
            currentDocument?.undoManager.beginUndoGrouping()
            for mark in selectedMarks {
                let proximalPositionX = transformToScaledViewPositionX(regionPositionX: mark.segment.proximal.x)
                let distalPositionX = transformToScaledViewPositionX(regionPositionX: mark.segment.distal.x)
                let proximalDiffX = proximalPositionX - location.x
                let distalDiffX = distalPositionX - location.x
                movementDiffs[mark] = (prox: proximalDiffX, distal: distalDiffX)
                setSegment(segment: mark.segment, forMark: mark)
            }
        }
        if state == .changed {
            for mark in selectedMarks {
                if let diff = movementDiffs[mark] {
                    let region = ladder.region(ofMark: mark)
                    let segment = transformToScaledViewSegment(regionSegment: mark.segment, region: region)
                    let newSegment = Segment(proximal: CGPoint(x: location.x + diff.prox, y: segment.proximal.y), distal: CGPoint(x: location.x + diff.distal, y: segment.distal.y))
                    let newRegionSegment = transformToRegionSegment(scaledViewSegment: newSegment, region: region)
                    setSegment(segment: newRegionSegment, forMark: mark)
                }
            }
        }
        if state == .ended {
            isDragging = false
            movementDiffs.removeAll()
            currentDocument?.undoManager.endUndoGrouping()
        }
        setNeedsDisplay()
    }

    func selectModeZoneDrag(_ pan: UIPanGestureRecognizer) {
        let position = pan.location(in: self)
        let state = pan.state
        let regionPositionX = transformToRegionPositionX(scaledViewPositionX: position.x)
        let locationInLadder = getLocationInLadder(position: position)
        guard let region = locationInLadder.region else { return }
        if state == .began {
            isDragging = true
            // normalize all regions that the zone goes through
//            ladder.setAllRegionsWithMode(.normal)
            region.mode = .normal
            zone = Zone()
            zone.isVisible = true
            zone.startingRegion = region
            zone.regions.insert(region)
            zone.start = regionPositionX
            zone.end = regionPositionX
        }
        if state == .changed {
            if !zone.regions.contains(region) {
                region.mode = .normal
                self.zone.regions.insert(region)
            }
            zone.end = regionPositionX
            selectInZone()
        }
        if state == .ended {
            isDragging = false
            selectInZone()
        }
        setNeedsDisplay()
    }

    func selectInZone() {
        let zoneMin = min(zone.start, zone.end)
        let zoneMax = max(zone.start, zone.end)
        for region in zone.regions {
            for mark in region.marks {
                if (mark.segment.proximal.x >= zoneMin
                        || mark.segment.distal.x >= zoneMin)
                    && (mark.segment.proximal.x <= zoneMax
                            || mark.segment.distal.x <= zoneMax) {
                    mark.mode = .selected
                } else {
                    mark.mode = .normal
                }
            }
        }
    }

    func setModeInZone(mode: Mark.Mode) {
        let zoneMin = min(zone.start, zone.end)
        let zoneMax = max(zone.start, zone.end)
        for region in zone.regions {
            for mark in region.marks {
                if (mark.segment.proximal.x > zoneMin
                        || mark.segment.distal.x > zoneMin)
                    && (mark.segment.proximal.x < zoneMax
                            || mark.segment.distal.x < zoneMax) {
                    mark.mode = mode
                }
            }
        }
    }

    private func swapEndsIfNeeded(mark: Mark) {
        let proximalY = mark.segment.proximal.y
        let distalY = mark.segment.distal.y
        if proximalY > distalY {
            mark.swapEnds()
        }
    }

    func swapEndsIfNeeded() {
        ladder.regions.forEach {
            region in region.marks.forEach {
                mark in self.swapEndsIfNeeded(mark: mark)
            }
        }
    }


    func moveAttachedMark(position: CGPoint) {
        if let attachedMark = ladder.attachedMark {
            moveMark(mark: attachedMark, scaledViewPosition: position)
            highlightNearbyMarks(attachedMark)
        }
    }

    func fixBoundsOfAttachedMark() {
        if let attachedMark = ladder.attachedMark {
            fixBoundsOfMark(attachedMark)
        }
    }

    private func fixBoundsOfMark(_ mark: Mark) {
        mark.segment = mark.segment.normalized()
    }

    func moveMark(mark: Mark, scaledViewPosition: CGPoint) {
        guard let activeRegion = activeRegion else { return }
        let regionPosition = transformToRegionPosition(scaledViewPosition: scaledViewPosition, region: activeRegion)
        if cursorViewDelegate.cursorIsVisible {
            undoablyMoveMark(movement: cursorViewDelegate.cursorMovement(), mark: mark, regionPosition: regionPosition)
        }
        updateMarkersAndRegionIntervals(activeRegion)
    }

    private func undoablyMoveMark(movement: Movement, mark: Mark, regionPosition: CGPoint) {
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: {target in
            target.undoablyMoveMark(movement: movement, mark: mark, regionPosition: regionPosition)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        moveMark(movement: movement, mark: mark, regionPosition: regionPosition)
    }

    private func moveMark(movement: Movement, mark: Mark, regionPosition: CGPoint) {
        mark.move(movement: movement, to: regionPosition)
        moveLinkedMarks(forMark: mark)
        adjustCursor(mark: mark)
        cursorViewDelegate.refresh()
    }

    private func moveLinkedMarks(forMark mark: Mark) {
        //os_log("moveLinkedMarked(forMark:)", log: .action, type: .info)
        for proximalMark in ladder.getMarkSet(fromMarkIdSet: mark.linkedMarkIDs.proximal) {
            if mark == proximalMark { break }
            var segment = proximalMark.segment
            segment.distal.x = mark.segment.proximal.x
            setSegment(segment: segment, forMark: proximalMark)
        }
        for distalMark in ladder.getMarkSet(fromMarkIdSet: mark.linkedMarkIDs.distal) {
            if mark == distalMark { break }
            var segment = distalMark.segment
            segment.proximal.x = mark.segment.distal.x
            setSegment(segment: segment, forMark: distalMark)
        }
        for middleMark in ladder.getMarkSet(fromMarkIdSet:mark.linkedMarkIDs.middle) {
            if mark == middleMark { break }
            print("****middleMark", middleMark.id)
            var segment = middleMark.segment
            let distanceToProximal = Geometry.distanceSegmentToPoint(segment: mark.segment, point: middleMark.segment.proximal)
            let distanceToDistal = Geometry.distanceSegmentToPoint(segment: mark.segment, point: middleMark.segment.distal)
            if distanceToProximal < distanceToDistal {
                let x = mark.segment.getX(fromY: middleMark.segment.proximal.y)
                if let x = x {
                    segment.proximal.x = x
                }
            }
            else {
                let x = mark.segment.getX(fromY: middleMark.segment.distal.y)
                    if let x = x {
                        segment.distal.x = x
                }
            }
            setSegment(segment: segment, forMark: middleMark)
            print("middle mark segment", segment)
        }
        setNeedsDisplay()
    }

    func setSelectedMark(position: CGPoint) {
        let locationInLadder = getLocationInLadder(position: position)
        if let mark = locationInLadder.mark {
            normalizeAllMarks()
            mark.mode = .selected
        }
    }

    func undoablySetMarkStyle(mark: Mark, style: Mark.Style) {
        let originalStyle = mark.style
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetMarkStyle(mark: mark, style: originalStyle)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        mark.style = style
    }

    func setSelectedMarksStyle(style: Mark.Style) {
        let selectedMarks: [Mark] = ladder.allMarksWithMode(.selected)
        currentDocument?.undoManager.beginUndoGrouping()
        selectedMarks.forEach { mark in self.undoablySetMarkStyle(mark: mark, style: style) }
        currentDocument?.undoManager.endUndoGrouping()
    }

    func setSelectedMarksBlockSetting(value: Mark.Endpoint) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        currentDocument?.undoManager.beginUndoGrouping()
        selectedMarks.forEach { mark in self.undoablySetManualBlock(mark: mark, value: value) }
        currentDocument?.undoManager.endUndoGrouping()
    }

    func undoablySetManualBlock(mark: Mark, value: Mark.Endpoint) {
        let originalBlock = mark.blockSetting
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetManualBlock(mark: mark, value: originalBlock)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        mark.blockSetting = value
        assessBlock(mark: mark)
    }

    func setSelectedMarksImpulseOriginSetting(value: Mark.Endpoint) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        currentDocument?.undoManager.beginUndoGrouping()
        selectedMarks.forEach { mark in self.undoablySetImpulseOriginSetting(mark: mark, value: value) }
        currentDocument?.undoManager.endUndoGrouping()
    }

    func undoablySetImpulseOriginSetting(mark: Mark, value: Mark.Endpoint) {
        let originalImpulseOriginSetting = mark.impulseOriginSetting
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetImpulseOriginSetting(mark: mark, value: originalImpulseOriginSetting)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        mark.impulseOriginSetting = value
        assessImpulseOrigin(mark: mark)
    }

    func setSelectedMarksEmphasis(emphasis: Mark.Emphasis) {
        let selectedMarks: [Mark] = ladder.allMarksWithMode(.selected)
        currentDocument?.undoManager.beginUndoGrouping()
        selectedMarks.forEach { mark in self.undoablySetMarkEmphasis(mark: mark, emphasis: emphasis) }
        currentDocument?.undoManager.endUndoGrouping()
    }

    func undoablySetMarkEmphasis(mark: Mark, emphasis: Mark.Emphasis) {
        let originalEmphasis = mark.emphasis
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetMarkEmphasis(mark: mark, emphasis: originalEmphasis)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        mark.emphasis = emphasis
    }

    func undoablySetRegionStyle(region: Region, style: Mark.Style) {
        let originalStyle = region.style
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetRegionStyle(region: region, style: originalStyle)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        region.style = style
    }

    func setSelectedRegionsStyle(style: Mark.Style) {
        let selectedRegions: [Region] = ladder.allRegionsWithMode(.selected)
        currentDocument?.undoManager.beginUndoGrouping()
        selectedRegions.forEach { region in self.undoablySetRegionStyle(region: region, style: style) }
        currentDocument?.undoManager.endUndoGrouping()
    }

    func dominantMarkStyleOfRegions(regions: [Region]) -> Mark.Style? {
        let count = regions.count
        for value in Mark.Style.allCases {
            if regions.filter({ $0.style == value }).count == count {
                return value
            }
        }
        return nil
    }

    func dominantStyleOfMarks(marks: [Mark]) -> Mark.Style? {
        guard marks.count > 0 else { return nil }
        let count = marks.count
        for value in Mark.Style.allCases {
            if marks.filter({ $0.style == value }).count == count {
                return value
            }
        }
        return nil
    }

    func dominantEmphasisOfMarks(marks: [Mark]) -> Mark.Emphasis? {
        guard marks.count > 0 else { return nil }
        let count = marks.count
        for value in Mark.Emphasis.allCases {
            if marks.filter({ $0.emphasis == value }).count == count {
                return value
            }
        }
        return nil
    }

    func dominantBlockSettingOfMarks(marks: [Mark]) -> Mark.Endpoint? {
        guard marks.count > 0 else { return nil }
        let count = marks.count
        for value in Mark.Endpoint.allCases {
            if marks.filter({ $0.blockSetting == value }).count == count {
                return value
            }
        }
        return nil
    }

    func dominantImpulseOriginOfMarks(marks: [Mark]) -> Mark.Endpoint? {
        guard marks.count > 0 else { return nil }
        let count = marks.count
        for value in Mark.Endpoint.allCases {
            if marks.filter({ $0.impulseOriginSetting == value }).count == count {
                return value
            }
        }
        return nil
    }

    func noSelectionExists() -> Bool {
        for region in ladder.regions {
            if region.mode == .selected {
                return false
            }
            for mark in region.marks {
                if mark.mode == .selected {
                    return false
                }
            }
        }
        return true
    }

    // MARK: - draw

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(UIColor.label.cgColor)
        context.setLineWidth(1)
        let ladderWidth: CGFloat = rect.width
        for (index, region) in ladder.regions.enumerated() {
            let regionRect = CGRect(x: leftMargin, y: region.proximalBoundaryY, width: ladderWidth, height: region.distalBoundaryY - region.proximalBoundaryY)
            let lastRegion = index == ladder.regions.count - 1
            drawRegion(rect: regionRect, context: context, region: region, offset: offsetX, scale: scale, lastRegion: lastRegion)
        }
        if mode == .select {
            drawZone(context: context)
        }
        if ladderIsLocked {
            showLockLadderWarning(rect: rect)
        }
        if marksAreHidden {
            showMarksAreHiddenWarning(rect: rect)
        }
    }

    func startZoning() {
        zone = Zone()
    }

    func endZoning() {
        zone.isVisible = false
        zone = Zone()
    }

    fileprivate func drawZone(context: CGContext) {
        guard ladder.zone.isVisible else { return }
        let start = transformToScaledViewPositionX(regionPositionX: zone.start)
        let end = transformToScaledViewPositionX(regionPositionX: zone.end)
        for region in zone.regions {
            let zoneRect = CGRect(x: start, y: region.proximalBoundaryY, width: end - start, height: region.distalBoundaryY - region.proximalBoundaryY)
            context.addRect(zoneRect)
            context.setFillColor(zoneColor.cgColor)
            context.setAlpha(0.2)
            context.drawPath(using: .fillStroke)
        }
        context.setAlpha(1.0)
    }

    // TODO: implement fitting longer label text into labels
    fileprivate func drawLabel(rect: CGRect, region: Region, context: CGContext) {
        let stringRect = CGRect(x: 0, y: rect.origin.y, width: rect.origin.x, height: rect.height)
        // TODO: refactor out constant attributes.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 18.0),
            .foregroundColor: region.mode == .active ? activeColor : selectedColor
        ]
        let text = region.name
        let labelText = NSAttributedString(string: text, attributes: attributes)
        let size: CGSize = text.size(withAttributes: attributes)
        let labelRect = CGRect(x: 0, y: rect.origin.y + (rect.height - size.height) / 2, width: rect.origin.x, height: size.height)

        context.addRect(stringRect)
        context.setStrokeColor(activeColor.cgColor)
        if region.mode == .labelSelected {
            context.setFillColor(selectedColor.cgColor)
            context.setAlpha(0.2)
        } else {
            context.setFillColor(UIColor.secondarySystemBackground.cgColor)
        }
        context.setLineWidth(1)
        context.drawPath(using: .fillStroke)
        context.setAlpha(1.0)
        labelText.draw(in: labelRect)

        // FIXME: Raise up label a bit to allow room for description
        guard showLabelDescription != .invisible else { return }
        let descriptionAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 12.0),
            .foregroundColor: region.mode == .active ? activeColor : selectedColor
        ]
        let descriptionText = NSAttributedString(string: region.longDescription, attributes: descriptionAttributes)

        let descriptionSize: CGSize = region.longDescription.size(withAttributes: descriptionAttributes)
        if showLabelDescription == .visibility || (showLabelDescription == .visibleIfFits && descriptionSize.width < stringRect.width) {
            let descriptionRect = CGRect(x: 0, y: labelRect.minY + labelRect.height, width: rect.origin.x, height: stringRect.height - labelRect.height)

            descriptionText.draw(in: descriptionRect)
        }

    }

    fileprivate func drawRegionArea(context: CGContext, rect: CGRect, region: Region) {
        // Draw top ladder line
        context.setStrokeColor(UIColor.label.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
        context.addLine(to: CGPoint(x: rect.width, y: rect.origin.y))
        context.strokePath()

        let regionRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height)

        // Highlight region if selected
        if region.mode == .active {
            context.setAlpha(0.2)
            context.addRect(regionRect)
            context.setFillColor(activeColor.cgColor)
            context.drawPath(using: .fillStroke)
        }
        if region.mode == .selected {
            context.setAlpha(0.2)
            context.addRect(regionRect)
            context.setFillColor(selectedColor.cgColor)
            context.drawPath(using: .fillStroke)
        }
        context.setAlpha(1)
    }

    fileprivate func drawMark(mark: Mark, region: Region, context: CGContext) {
        // Don't draw outside bounds of region, fix out of bounds segments at end of mark movement.
        let normalizedSegment = mark.segment.normalized()
        let segment = transformToScaledViewSegment(regionSegment: normalizedSegment, region: region)
        // Don't bother drawing marks in margin.
        if segment.proximal.x <= leftMargin && segment.distal.x <= leftMargin {
            return
        }
        // The two endpoints of the mark to be drawn
        var p1 = CGPoint()
        var p2 = CGPoint()
        if segment.proximal.x > leftMargin && segment.distal.x > leftMargin {
            p1 = segment.proximal
            p2 = segment.distal
        }
        else if segment.proximal.x < leftMargin {
            p1 = getTruncatedPosition(segment: segment) ?? segment.proximal
            p2 = segment.distal
        }
        else {
            p1 = getTruncatedPosition(segment: segment) ?? segment.distal
            p2 = segment.proximal
        }
        context.setStrokeColor(getMarkColor(mark: mark))
        // FIXME: Do we need both stroke and fill?
        context.setFillColor(getMarkColor(mark: mark))
        context.setLineWidth(mark.emphasis == .bold ? markLineWidth + 1 :  markLineWidth)
        context.move(to: p1)
        context.addLine(to: p2)
        if mark.style == .dashed {
            let dashes: [CGFloat] = [8, 8]
            context.setLineDash(phase: 0, lengths: dashes)
        }
        else if mark.style == .dotted {
            let dots: [CGFloat] = [4, 4]
            context.setLineDash(phase: 0, lengths: dots)
        }
        else { // draw solid line
            context.setLineDash(phase: 0, lengths: [])
        }
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])

        drawBlock(context: context, mark: mark, segment: segment)
        drawImpulseOrigin(context: context, mark: mark, segment: segment)
        drawPivots(forMark: mark, segment: Segment(proximal: p1, distal: p2), context: context)
        drawConductionTime(forMark: mark, segment: segment, context: context)
        drawIntervals(region: region, context: context)

        drawProxEnd(forMark: mark, segment: segment, context: context)
        drawEarliestPoint(forMark: mark, segment: segment, context: context)
        drawConductionDirection(forMark: mark, segment: segment, context: context)

        context.setStrokeColor(UIColor.label.cgColor)
    }

    fileprivate func drawIntervals(region: Region, context: CGContext) {
        guard showIntervals else { return }
        guard region.marks.count < maxMarksForIntervals else { return }
        guard let calibration = calibration, calibration.isCalibrated else { return }
        if let index = ladder.index(ofRegion: region), let intervals = ladderIntervals[index] {
            for interval in intervals {
                if let firstProximalX = interval.proximalBoundary?.first, let secondProximalX = interval.proximalBoundary?.second {
                    let scaledFirstX = transformToScaledViewPositionX(regionPositionX: firstProximalX)
                    let scaledSecondX = transformToScaledViewPositionX(regionPositionX: secondProximalX)
                    let value = (scaledSecondX - scaledFirstX)
                    let text = "\(formatValue(value, usingCalFactor: calibration.currentCalFactor))"
                    let size = text.size(withAttributes: measurementTextAttributes)
                    if size.width + intervalMargin < value { // don't crowd measurements
                        // Center the origin.
                        let halfwayPosition = (scaledFirstX + scaledSecondX) / 2.0
                        var origin = CGPoint(x: halfwayPosition, y: region.proximalBoundaryY)
                        origin = CGPoint(x: origin.x - size.width / 2, y: origin.y)
                        drawIntervalText(origin: origin, size: size, text: text, context: context, attributes: measurementTextAttributes)
                    }
                }
                if let firstDistalX = interval.distalBoundary?.first, let secondDistalX = interval.distalBoundary?.second {
                    let scaledFirstX = transformToScaledViewPositionX(regionPositionX: firstDistalX)
                    let scaledSecondX = transformToScaledViewPositionX(regionPositionX: secondDistalX)
                    let value = (scaledSecondX - scaledFirstX)
                    let text = "\(formatValue(value, usingCalFactor: calibration.currentCalFactor))"
                    let size = text.size(withAttributes: measurementTextAttributes)
                    if size.width + intervalMargin < value {
                        // Center the origin
                        let halfwayPosition = (scaledFirstX + scaledSecondX) / 2.0
                        var origin = CGPoint(x: halfwayPosition, y: region.distalBoundaryY)
                        origin = CGPoint(x: origin.x - size.width / 2, y: origin.y - size.height)
                        drawIntervalText(origin: origin, size: size, text: text, context: context, attributes: measurementTextAttributes)
                    }
                }
            }
        }
    }

    func formatValue(_ value: CGFloat?, usingCalFactor calFactor: CGFloat) -> Int {
        return lround(Double(value ?? 0) * Double(calFactor))
    }

    private func drawIntervalText(origin: CGPoint, size: CGSize, text: String, context: CGContext, attributes: [NSAttributedString.Key: Any]) {
        let textRect = CGRect(origin: origin, size: size)
        if textRect.minX > leftMargin {
            text.draw(in: textRect, withAttributes: attributes)
            context.strokePath()
        }
    }

    // Most of the time, only need to update intervals in affected region.
    func updateRegionIntervals(_ region: Region?) {
        guard let region = region else { return }
        guard showIntervals else { return }
        guard let calibration = calibration, calibration.isCalibrated else { return }
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                if let index = self.ladder.index(ofRegion: region) {
                    self.ladderIntervals[index] = self.ladder.regionIntervals(region: region)
                    self.setNeedsDisplay()
                }
            }
        }
    }

    // When view appears, all intervals needed to be calculated.
    func updateLadderIntervals() {
        guard showIntervals else { return }
        guard let calibration = calibration, calibration.isCalibrated else { return }
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                self.ladderIntervals = self.ladder.ladderIntervals()
                self.setNeedsDisplay()
            }
        }
    }

    func updateMarkers() {
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                let marks = self.ladder.allMarks()
                var markerPoints: [CGPoint] = []
                for mark in marks {
                    markerPoints.append(mark.segment.proximal)
                    markerPoints.append(mark.segment.distal)
                }
                self.cursorViewDelegate.setMarkerPositions(at: markerPoints)
                self.cursorViewDelegate.refresh()
            }
        }
    }

    func updateMarkersAndRegionIntervals(_ region: Region?) {
        updateMarkers()
        updateRegionIntervals(region)
        setNeedsDisplay()
    }

    func assessBlockAndImpulseOrigin(mark: Mark?) {
        if let mark = mark {
            self.assessBlock(mark: mark)
            self.assessImpulseOrigin(mark: mark)
        }
    }

    // FIXME: need to make this work for attached middle marks.
    func assessBlockAndImpulseOrigin(marks: MarkSet) {
        for mark in marks {
            assessBlock(mark: mark)
            assessImpulseOrigin(mark: mark)
        }
    }

    func assessBlock(mark: Mark) {
        if mark.blockSetting == .auto {
            mark.blockSite = .none
            if mark.early == .none {
                return  // for now, ignore vertical marks
            }
            if mark.linkedMarkIDs.middle.count > 0
                && mark.late == ladder.markLinkage(mark: mark, linkedMarksIDs: mark.linkedMarkIDs) {
                mark.blockSite = .none
            } else if mark.segment.proximal.y > blockMin
                && mark.late == .proximal {
                mark.blockSite = .proximal
            } else if mark.segment.distal.y < blockMax
                        && mark.late == .distal {
                mark.blockSite = .distal
            }
        } else {
            mark.blockSite = mark.blockSetting
        }
    }

    func assessImpulseOrigin(mark: Mark) {
        if mark.impulseOriginSetting == .auto {
            mark.impulseOriginSite = .none
            if mark.linkedMarkIDs.middle.count > 0
                && mark.early == ladder.markLinkage(mark: mark, linkedMarksIDs: mark.linkedMarkIDs) {
                mark.impulseOriginSite = .none
            } else if mark.linkedMarkIDs.proximal.count == 0 && (mark.early == .proximal || mark.early == .none) {
                mark.impulseOriginSite = .proximal
            } else if mark.linkedMarkIDs.distal.count == 0 && mark.early == .distal {
                mark.impulseOriginSite = .distal
            }
        }
        else {
            mark.impulseOriginSite = mark.impulseOriginSetting
        }
    }

    func assessGlobalImpulseOrigin() {
        let marks = ladder.allMarks()
        for mark in marks {
            assessImpulseOrigin(mark: mark)
        }
    }

    func regionValueFromCalibratedValue(_ value: CGFloat, usingCalFactor calFactor: CGFloat) -> CGFloat {
        let x1: CGFloat = 0
        let x2: CGFloat  = value
        let regionX1 = transformToRegionPositionX(scaledViewPositionX: x1)
        let regionX2 = transformToRegionPositionX(scaledViewPositionX: x2)
        let diff = regionX2 - regionX1
        return diff / calFactor
    }

    func showLockLadderWarning(rect: CGRect) {
        let text = L("LADDER LOCK")
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0),
            .foregroundColor: UIColor.white, .backgroundColor: UIColor.systemRed,

        ]
        let lockRect = CGRect(x: rect.origin.x + 5, y: rect.origin.y + 5, width: rect.size.width, height: rect.size.height)
        text.draw(in: lockRect, withAttributes: attributes)
    }


    func showMarksAreHiddenWarning(rect: CGRect) {
        let text = L("MARKS ARE HIDDEN")
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0),
            .foregroundColor: UIColor.white, .backgroundColor: UIColor.systemRed,

        ]
        let size = text.size(withAttributes: attributes)
        let hiddenMarksRect = CGRect(x: rect.size.width - size.width - 5, y: rect.origin.y + 5, width: rect.size.width, height: rect.size.height)
        text.draw(in: hiddenMarksRect, withAttributes: attributes)
    }

    func getTruncatedPosition(segment: Segment) -> CGPoint? {
        let intersection = Geometry.intersection(ofLineFrom: CGPoint(x: leftMargin, y: 0), to: CGPoint(x: leftMargin, y: viewHeight), withLineFrom: segment.proximal, to: segment.distal)
        return intersection
    }

    func drawFilledCircle(context: CGContext, position: CGPoint, radius: CGFloat) {
        let rectangle = CGRect(x: position.x, y: position.y, width: radius, height: radius)
        context.addEllipse(in: rectangle)
        context.drawPath(using: .fillStroke)
    }

    func drawArrowHead(context: CGContext, start: CGPoint, end: CGPoint, pointerLineLength: CGFloat, arrowAngle: CGFloat) {
        context.move(to: end)
        let startEndAngle = atan((end.y - start.y) / (end.x - start.x)) + ((end.x - start.x) < 0 ? CGFloat(Double.pi) : 0)
        let arrowLine1 = CGPoint(x: end.x + pointerLineLength * cos(CGFloat(Double.pi) - startEndAngle + arrowAngle), y: end.y - pointerLineLength * sin(CGFloat(Double.pi) - startEndAngle + arrowAngle))
        let arrowLine2 = CGPoint(x: end.x + pointerLineLength * cos(CGFloat(Double.pi) - startEndAngle - arrowAngle), y: end.y - pointerLineLength * sin(CGFloat(Double.pi) - startEndAngle - arrowAngle))

        context.addLine(to: arrowLine1)
        context.move(to: end)
        context.addLine(to: arrowLine2)
        context.strokePath()
    }

    func drawProxEnd(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard showProxEnd else { return }
        drawFilledCircle(context: context, position: segment.proximal, radius: 10)
    }

    func drawEarliestPoint(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard showEarliestPoint else { return }
        if mark.earliestPoint == mark.segment.proximal {
            drawFilledCircle(context: context, position: segment.proximal, radius: 20)
        } else {
            drawFilledCircle(context: context, position: segment.distal, radius: 20)
        }
    }

    func drawConductionDirection(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard showArrows else { return }
        switch mark.late {
        case .distal:
            drawArrowHead(context: context, start: segment.proximal, end: segment.distal, pointerLineLength: 20, arrowAngle: arrowHeadAngle)
        case .proximal:
            drawArrowHead(context: context, start: segment.distal, end: segment.proximal, pointerLineLength: 20, arrowAngle: arrowHeadAngle)
        case .none, .auto, .random:
            break // this is undecided unless manually set
        }
    }

    func drawPivots(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard showPivots else { return }
        // We only show pivots when cursor is attached.
        guard mark.mode == .attached else { return }
        let pivots = ladder.pivotPoints(forMark: mark)
        guard pivots.count > 0 else { return }
        var position: CGPoint = CGPoint.zero
        for pivot in pivots {
            switch pivot {
            case .proximal:
                position = segment.proximal
            case .distal:
                position = segment.distal
            default:
                assert(false, "pivot != .proximal or .distal!")
            }
            if (position.x > leftMargin) {
                drawPivot(context: context, position: position)
            }
        }
    }

    func drawConductionTime(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard let calibration = calibration, calibration.isCalibrated, showConductionTimes, mark.showMeasurementText else { return }
        let normalizedSegment = mark.segment.normalized()
            let segment = self.transformToScaledViewSegment(regionSegment: normalizedSegment, region: self.ladder.region(ofMark: mark))
            let value = lround(Double(self.cursorViewDelegate.markMeasurement(segment: segment)))
        if hideZeroCT && value < 1 {
            return
        }
        var text = ""
        if debugMarkMode {
            text = String(mark.id.uuidString.prefix(8) + " \(mark.impulseOriginSite)")
        } else {
            text = "\(value)"
        }
        var origin = segment.midpoint
        let size = text.size(withAttributes: measurementTextAttributes)
        // Center the origin.
        origin = CGPoint(x: origin.x + 10, y: origin.y - size.height / 2)
        let textRect = CGRect(origin: origin, size: size)
        if textRect.minX > leftMargin {
            text.draw(in: textRect, withAttributes: measurementTextAttributes)
            context.strokePath()
        }
    }

    func drawPivot(context: CGContext, position: CGPoint) {
        let radius: CGFloat = 5.0
        drawX(context: context, position: position, radius: radius)
    }

    private func drawX(context: CGContext, position: CGPoint, radius: CGFloat) {
        let x = position.x
        let y = position.y
        context.move(to: CGPoint(x: x - radius, y: y - radius))
        context.addLine(to: CGPoint(x: x + radius, y: y + radius))
        context.move(to: CGPoint(x: x + radius, y: y - radius))
        context.addLine(to: CGPoint(x: x - radius, y: y + radius))
        context.strokePath()
    }

    func drawBlock(context: CGContext, mark: Mark, segment: Segment) {
        guard showBlock else { return }
        let blockLength: CGFloat = 20
        let blockSeparation: CGFloat = 5
        switch mark.blockSite {
        case .none:
            return
        case .distal:
            context.move(to: CGPoint(x: segment.distal.x - blockLength / 2, y: segment.distal.y))
            context.addLine(to: CGPoint(x: segment.distal.x + blockLength / 2, y: segment.distal.y))
            if doubleLineBlockMarker {
                context.move(to: CGPoint(x: segment.distal.x - blockLength / 2, y: segment.distal.y + blockSeparation))
                context.addLine(to: CGPoint(x: segment.distal.x + blockLength / 2, y: segment.distal.y + blockSeparation))
            }
        case .proximal:
            context.move(to: CGPoint(x: segment.proximal.x - blockLength / 2, y: segment.proximal.y))
            context.addLine(to: CGPoint(x: segment.proximal.x + blockLength / 2, y: segment.proximal.y))
            if doubleLineBlockMarker {
                context.move(to: CGPoint(x: segment.proximal.x - blockLength / 2, y: segment.proximal.y - blockSeparation))
                context.addLine(to: CGPoint(x: segment.proximal.x + blockLength / 2, y: segment.proximal.y - blockSeparation))
            }
        case .auto, .random:
            fatalError("Block site set to auto or random.")
        }
        context.strokePath()
    }

    func drawImpulseOrigin(context: CGContext, mark: Mark, segment: Segment) {
        guard showImpulseOrigin else { return }
        let separation: CGFloat = 10
        let radius: CGFloat = 5
        switch mark.impulseOriginSite {
        case .none:
            return
        case .distal:
            drawFilledCircle(context: context, position: CGPoint(x: segment.distal.x - radius / 2, y: segment.distal.y + separation - radius), radius: radius)
        case .proximal:
            drawFilledCircle(context: context, position: CGPoint(x: segment.proximal.x - radius / 2, y: segment.proximal.y - separation), radius: radius)
        case .auto, .random:
            fatalError("Impulse origin site set to auto or random.")
        }
    }

    private func getMarkLineWidth(_ mark: Mark) -> CGFloat {
        return markLineWidth
    }

    private func getMarkColor(mark: Mark) -> CGColor {
        switch mark.mode {
        case .linked:
            return linkedColor.cgColor
        case .attached:
            return attachedColor.cgColor
        case .selected:
            return selectedColor.cgColor
        case .connected:
            return connectedColor.cgColor
        case .normal:
            return normalColor.cgColor
        }
    }

    fileprivate func drawMarks(region: Region, context: CGContext,  rect: CGRect) {
        // Draw marks
        for mark: Mark in region.marks {
            drawMark(mark: mark, region: region, context: context)

        }
    }

    fileprivate func drawBottomLine(context: CGContext, lastRegion: Bool, rect: CGRect) {
        // Draw bottom line of region if it is the last region of the ladder.
        context.setLineWidth(1)
        if lastRegion {
            context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height))
            context.addLine(to: CGPoint(x: rect.width, y: rect.origin.y + rect.height))
        }
        context.strokePath()
    }

    func drawRegion(rect: CGRect, context: CGContext, region: Region, offset: CGFloat, scale: CGFloat, lastRegion: Bool) {
        drawLabel(rect: rect, region: region, context: context)
        drawRegionArea(context: context, rect: rect, region: region)
        if !marksAreHidden {
            drawMarks(region: region, context: context, rect: rect)
        }
        drawBottomLine(context: context, lastRegion: lastRegion, rect: rect)
    }

    func normalizeRegions() {
        ladder.normalizeRegions()
    }

    func normalizeAllMarks() {
        ladder.normalizeAllMarks()
    }

    func normalizeLadder() {
        ladder.normalize()
    }

    func clearSelectedLabels() {
        ladder.clearSelectedLabels()
    }

    func resetSize(setActiveRegion: Bool = true, width: CGFloat? = nil) {
        os_log("resetSize() - LadderView", log: .action, type: .info)
        viewHeight = self.frame.height
        if let width = width { // only reset width if asked
            viewMaxWidth = width
        }
        initializeRegions(setActiveRegion: setActiveRegion)
        cursorViewDelegate.setCursorHeight()
    }

    @objc func deleteSelectedMarks() {
        os_log("deleteSelectedMarks() - LadderView", log: OSLog.debugging, type: .debug)
        let selectedMarks = ladder.allMarksWithMode(.selected)
        selectedMarks.forEach { mark in self.undoablyDeleteMark(mark: mark) }
        hideCursorAndNormalizeAllMarks()
        cursorViewDelegate.refresh()
        setNeedsDisplay()
    }

    @objc func deleteAllInSelectedRegion() {
        os_log("deleteAllInRegion() - LadderView", log: OSLog.debugging, type: .debug)
        let selectedRegions = ladder.allRegionsWithMode(.selected)
        // assume only one selected region
        guard selectedRegions.count > 0 else { return }
        if let selectedRegion = selectedRegions.first {
            currentDocument?.undoManager?.beginUndoGrouping()
            for mark in selectedRegion.marks {
                undoablyDeleteMark(mark: mark)
            }
            currentDocument?.undoManager?.endUndoGrouping()
            hideCursorAndNormalizeAllMarks()
            cursorViewDelegate.refresh()
            setNeedsDisplay()
        }
    }

    func selectedRegion() -> Region? {
        let selectedRegions = ladder.allRegionsWithMode(.selected)
        // assume only one selected region
        guard selectedRegions.count > 0 else { return nil }
        if let region = selectedRegions.first {
            return region
        } else {
            return nil
        }
    }

    func selectedLabelRegion() -> Region? {
        let selectedRegions = ladder.allRegionsWithMode(.labelSelected)
        // assume only one selected region
        guard selectedRegions.count > 0 else { return nil }
        if let region = selectedRegions.first {
            return region
        } else {
            return nil
        }
    }

    @objc func deleteAllInLadder() {
        os_log("deleteAllInLadder() - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.beginUndoGrouping()
        for region in ladder.regions {
            for mark in region.marks {
                undoablyDeleteMark(mark: mark)
            }
        }
        currentDocument?.undoManager?.endUndoGrouping()
        hideCursorAndNormalizeAllMarks()
        cursorViewDelegate.refresh()
        setNeedsDisplay()
    }

    @objc func unlinkSelectedMarks() {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        // FIXME: need this here?
        normalizeAllMarks()
        selectedMarks.forEach { mark in unlinkMarks(mark: mark) }
    }

    func unlinkAllMarks() {
        ladder.unlinkAllMarks()
    }

    func linkAllMarks() {
        // scan all marks, link them if possible
//        ladder.unlinkAllMarks()
//        let marks = ladder.allMarks()
//        for mark in marks {
//
//            _ = nearbyMarkIds(mark: mark, nearbyDistance: nearbyMarkAccuracy / scale)
//        }
    }

    func unlinkMarks(mark: Mark) {
        // First remove all backlinks to this mark.
        for m in ladder.allMarks() {
            m.linkedMarkIDs.remove(id: mark.id)
        }
        // Now clear all links of this mark.
        mark.linkedMarkIDs = LinkedMarkIDs()
    }

    func soleSelectedMark() -> Mark? {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        if selectedMarks.count == 1 {
            return selectedMarks.first
        }
        return nil
    }

    func straightenToEndpoint(_ endpoint: Mark.Endpoint) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        currentDocument?.undoManager.beginUndoGrouping()
        selectedMarks.forEach { mark in
            let originalSegment = mark.segment
            currentDocument?.undoManager.registerUndo(withTarget: self, handler: { target in
                self.setSegment(segment: originalSegment, forMark: mark)
            })
            NotificationCenter.default.post(name: .didUndoableAction, object: nil)
            let segment: Segment
            switch endpoint {
            case .proximal:
                segment = Segment(proximal: mark.segment.proximal, distal: CGPoint(x: mark.segment.proximal.x, y: mark.segment.distal.y))
            case .distal:
                segment = Segment(proximal: CGPoint(x: mark.segment.distal.x, y: mark.segment.proximal.y), distal: mark.segment.distal)
            case .none, .auto, .random:
                fatalError("Endpoint.none, .random, or .auto inappopriately passed to straightenToEndPoint()")
            }
            self.setSegment(segment: segment, forMark: mark)
        }
        currentDocument?.undoManager.endUndoGrouping()
    }

    func adjustY(_ value: CGFloat, endpoint: Mark.Endpoint, adjustment: Adjustment) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        selectedMarks.forEach { mark in
            let originalSegment = mark.segment
            currentDocument?.undoManager.registerUndo(withTarget: self, handler: { target in
                self.setSegment(segment: originalSegment, forMark: mark)
            })
            NotificationCenter.default.post(name: .didUndoableAction, object: nil)
            let segment: Segment
            switch adjustment {
            case .trim:
                if endpoint == .proximal {
                    segment = Segment(proximal: CGPoint(x: Geometry.evaluateX(knowingY: value, fromSegment: mark.segment), y: value), distal: mark.segment.distal)
                } else {
                    segment = Segment(proximal: mark.segment.proximal, distal: CGPoint(x: Geometry.evaluateX(knowingY: value, fromSegment: mark.segment), y: value))
                }
            case .adjust:
                if endpoint == .proximal {
                    segment = Segment(proximal: CGPoint(x: mark.segment.proximal.x, y: value), distal: mark.segment.distal)
                } else {
                    segment = Segment(proximal: mark.segment.proximal, distal: CGPoint(x: mark.segment.distal.x, y: value))
                }
            }
            setSegment(segment: segment, forMark: mark)
        }
    }

    func meanCL() throws -> CGFloat {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        // FIXME: is calibration ever nil??
        guard let calibration = calibration else {
            fatalError("calibration is nil")
        }
        if !calibration.isCalibrated {
            throw LadderError.notCalibrated
        }
        if selectedMarks.count <= 1 {
            throw LadderError.tooFewMarks
        }
        if ladder.marksAreInDifferentRegions(selectedMarks) {
            throw LadderError.marksInDifferentRegions
        }
        if ladder.marksAreNotContiguous(selectedMarks) {
            throw LadderError.marksNotContiguous
        }
        return ladder.meanCL(selectedMarks)
    }

    func checkForMovement() throws {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        if selectedMarks.count < 1 {
            throw LadderError.tooFewMarks
        }
    }

    func checkForRhythm() throws {
        guard let calibration = calibration else {
            fatalError("calibration is nil")
        }
        if !calibration.isCalibrated {
            throw LadderError.notCalibrated
        }
        let zone = ladder.zone
        if zone.isVisible {
            if zone.regions.count > 1 {
                throw LadderError.tooManyRegions
            }
        }
        let regions = ladder.allRegionsWithMode(.selected)
        if regions.count > 1 {
            throw LadderError.tooManyRegions
        }
    }

    func checkForRepeatCL() throws {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        if selectedMarks.count != 2 {
            throw LadderError.requireTwoMarks
        }
        if ladder.marksAreInDifferentRegions(selectedMarks) {
            throw LadderError.marksInDifferentRegions
        }
//        if ladder.marksAreNotContiguous(selectedMarks) {
//            throw LadderError.marksNotContiguous
//        }
        if !ladder.marksAreParallel(selectedMarks[0], selectedMarks[1]) {
            throw LadderError.marksNotParallel
        }
        // FIXME: appropriate short interval
        if ladder.difference(selectedMarks[0], selectedMarks[1]) < 20 {
            throw LadderError.intervalTooShort
        }
    }

    func performRepeatCL(time: TemporalRelation) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        guard selectedMarks.count == 2 else { return }
        currentDocument?.undoManager.beginUndoGrouping()

        func repeatCLAfter() {
            var nextSegment = secondMark.segment
            while nextSegment.proximal.x < regionEnd && nextSegment.distal.x < regionEnd {
                nextSegment.proximal.x += proxCL
                nextSegment.distal.x += proxCL
                let newMark = ladder.addMark(fromSegment: nextSegment, toRegion: region)
                newMark.mode = .selected
                undoablyAddMark(mark: newMark)
            }
        }

        func repeatCLBefore() {
            var nextSegment = firstMark.segment
            while nextSegment.proximal.x > regionStart && nextSegment.distal.x > regionStart {
                nextSegment.proximal.x -= proxCL
                nextSegment.distal.x -= proxCL
                let newMark = ladder.addMark(fromSegment: nextSegment, toRegion: region)
                newMark.mode = .selected
                undoablyAddMark(mark: newMark)
            }
        }

        let mark1 = selectedMarks[0]
        let mark2 = selectedMarks[1]
        let region = ladder.region(ofMark: mark1)
        let regionStart: CGFloat = 0
        let regionEnd: CGFloat = viewMaxWidth
        let proxCL = abs(mark2.segment.proximal.x - mark1.segment.proximal.x)
        let secondMark = mark2 > mark1 ? mark2 : mark1
        let firstMark = mark2 < mark1 ? mark2 : mark1
        print("firstMark = \(firstMark), secondMark = \(secondMark)")
        switch time {
        case .before:
            repeatCLBefore()
        case .after:
            repeatCLAfter()
        case .both:
            repeatCLAfter()
            repeatCLBefore()
        }
        setNeedsDisplay()
        currentDocument?.undoManager.endUndoGrouping()
    }

    func fillWithRhythm(_ rhythm: Rhythm) {
        guard let calFactor = calibration?.currentCalFactor else { return }
        currentDocument?.undoManager.beginUndoGrouping()
        func applyCL(start: CGFloat, end: CGFloat, region: Region?, deleteExtantMarks: Bool = false) {
            guard let region = region else { return }
            if deleteExtantMarks {
                deleteMarksInRegion(region, start: start, end: end)
            }
            var regionCL: CGFloat = 0
            if rhythm.regularity == .regular {
                regionCL = regionValueFromCalibratedValue(rhythm.meanCL, usingCalFactor: calFactor)
            }
            else if rhythm.regularity == .fibrillation {
                // get average CL from min and max values
                regionCL = regionValueFromCalibratedValue((rhythm.maxCL + rhythm.minCL) / 2, usingCalFactor: calFactor)
            }
            var positionX = start
            while positionX < end {
                let mark = ladder.addMark(at: positionX, toRegion: region)
                var impulseOrigin: Mark.Endpoint = .none
                if rhythm.regularity == .fibrillation && rhythm.randomizeConductionTime {
                    let ct = randomizeConductionTime(range: rhythm.minimumCT...rhythm.maximumCT, calFactor: calFactor)
                    impulseOrigin = randomizeImpulseEndpoint(endpoint: rhythm.impulseOrigin)
                    if impulseOrigin == .proximal {
                        mark.segment.distal.x += ct
                    } else if impulseOrigin == .distal {
                        mark.segment.proximal.x += ct
                    }
                }
                if rhythm.regularity == .fibrillation && rhythm.randomizeImpulseOrigin {
                    if impulseOrigin == .proximal {
                        mark.segment.proximal.y = randomizeImpulseOrigin(range: 0...1.0)
                    } else if impulseOrigin == .distal {
                        mark.segment.distal.y = randomizeImpulseOrigin(range: 0...1.0)
                    }
                }
                if rhythm.regularity == .fibrillation {
                    positionX += randomizeCycleLength(range: Double(rhythm.minCL)...Double(rhythm.maxCL), calFactor: calFactor)

                } else {
                    positionX += regionCL
                }
                undoablyAddMark(mark: mark)
            }
            if zone.isVisible {
                selectInZone()
            } else {
                ladder.setMarksWithMode(.selected, inRegion: region)
            }
            setNeedsDisplay()
        }
        let selectedRegions = ladder.allRegionsWithMode(.selected)
        if ladder.zone.isVisible {
            let start = zone.start
            let end = zone.end
            applyCL(start: start, end: end, region: zone.startingRegion, deleteExtantMarks: rhythm.replaceExistingMarks)
        } else if selectedRegions.count == 1 {
            let start: CGFloat = 0
            let end = viewMaxWidth
            applyCL(start: start, end: end, region: selectedRegions[0], deleteExtantMarks: rhythm.replaceExistingMarks)
        }
        currentDocument?.undoManager.endUndoGrouping()
    }

    func randomizeCycleLength(range: ClosedRange<Double>, calFactor: CGFloat) -> CGFloat {
        let cl = Double.random(in: range)
        return regionValueFromCalibratedValue(CGFloat(cl), usingCalFactor: calFactor)
    }

    func randomizeConductionTime(range: ClosedRange<Double>, calFactor: CGFloat) -> CGFloat {
        let ct = Double.random(in: range)
        return regionValueFromCalibratedValue(CGFloat(ct), usingCalFactor: calFactor)
    }

    func randomizeImpulseOrigin(range: ClosedRange<Double>) -> CGFloat {
        let io = Double.random(in: range)
        return CGFloat(io)
    }

    func randomizeImpulseEndpoint(endpoint: Mark.Endpoint) -> Mark.Endpoint {
        guard endpoint == .random else { return endpoint }
        let randomN = Int.random(in: 0...1)
        return randomN == 0 ? .proximal : .distal
    }

    func deleteMarksInRegion(_ region: Region, start: CGFloat, end: CGFloat) {
        for mark in region.marks {
            if (mark.segment.proximal.x > start || mark.segment.distal.x > start)
                && (mark.segment.proximal.x < end || mark.segment.distal.x < end) {
                undoablyDeleteMark(mark: mark)
            }
        }
    }

    func moveMarks(_ diff: CGFloat) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        let regionDiff = transformToRegionPositionX(scaledViewPositionX: diff)
        for mark in selectedMarks {
            let newSegment = Segment(proximal: CGPoint(x: mark.segment.proximal.x + regionDiff, y: mark.segment.proximal.y), distal: CGPoint(x: mark.segment.distal.x + regionDiff, y: mark.segment.distal.y))
            setSegment(segment: newSegment, forMark: mark)
        }
    }

    func adjustCL(cl: CGFloat) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        var proxX = selectedMarks[0].segment.proximal.x
        var distalX = selectedMarks[0].segment.distal.x
        for i in 1..<selectedMarks.count {
            let originalSegment = selectedMarks[i].segment
            currentDocument?.undoManager.registerUndo(withTarget: self, handler: { target in
                self.setSegment(segment: originalSegment, forMark: selectedMarks[i])
            })
            NotificationCenter.default.post(name: .didUndoableAction, object: nil)
            proxX += cl
            distalX += cl
            let newSegment = Segment(proximal: CGPoint(x: proxX, y: selectedMarks[i].segment.proximal.y), distal: CGPoint(x: distalX, y: selectedMarks[i].segment.distal.y))
            self.setSegment(segment: newSegment, forMark: selectedMarks[i])
        }
    }

    func slantSelectedMarks(angle: CGFloat, endpoint: Mark.Endpoint) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        selectedMarks.forEach { mark in
            let originalSegment = mark.segment
            currentDocument?.undoManager.registerUndo(withTarget: self, handler: { target in
                self.setSegment(segment: originalSegment, forMark: mark)
            })
            NotificationCenter.default.post(name: .didUndoableAction, object: nil)
            slantMark(angle: angle, mark: mark, endpoint: endpoint)
        }
    }

    func slantMark(angle: CGFloat, mark: Mark, endpoint: Mark.Endpoint = .proximal) {
        let region = ladder.region(ofMark: mark)
        let segment = transformToScaledViewSegment(regionSegment: mark.segment, region: region)
        let height = segment.distal.y - segment.proximal.y
        let delta = Geometry.rightTriangleBase(withAngle: angle, height: height)
        // We add delta to proximal x, not distal x, because we always start with a vertical mark.
        let newSegment: Segment
        switch endpoint {
        case .proximal:
            newSegment = Segment(proximal: segment.proximal, distal: CGPoint(x: segment.proximal.x + delta, y: segment.distal.y))
        case .distal:
            newSegment = Segment(proximal: CGPoint(x: segment.distal.x + delta, y: segment.proximal.y), distal: segment.distal)
        case .none, .random, .auto:
            fatalError("Endpoint.none, .random, or .auto inappopriately passed to slantMark()")
        }
        setSegment(segment: transformToRegionSegment(scaledViewSegment: newSegment, region: region), forMark: mark)
    }

    func slantAngle(mark: Mark, endpoint: Mark.Endpoint) -> CGFloat { 
        let region = ladder.region(ofMark: mark)
        let segment = transformToScaledViewSegment(regionSegment: mark.segment, region: region)
        if endpoint == .proximal {
            if (segment.proximal.x < segment.distal.x) {
                return Geometry.oppositeAngle(p1: segment.proximal, p2: segment.distal)
            } else {
                return  Geometry.oppositeAngle(p1: segment.distal, p2: segment.proximal)
            }
        } else {
            if (segment.proximal.x > segment.distal.x) {
                return Geometry.oppositeAngle(p1: segment.proximal, p2: segment.distal)
            } else {
                return  Geometry.oppositeAngle(p1: segment.distal, p2: segment.proximal)
            }
        }
    }

    private func setSegment(segment: Segment, forMark mark: Mark) {
        let originalSegment = mark.segment
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.setSegment(segment: originalSegment, forMark: mark)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        mark.segment = segment
        updateMarkersAndRegionIntervals(ladder.region(ofMark: mark))
        assessBlockAndImpulseOrigin(mark: mark)
    }

    func undoablySetLabel(_ label: String, description: String, forRegion region: Region) {
        let originalName = region.name
        let originalDescription = region.longDescription
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetLabel(originalName, description: originalDescription, forRegion: region)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        region.name = label
        region.longDescription = description
        setNeedsDisplay()
    }

    // TODO: skeleton for add/remove region
    // region = new region to add.  Index is where to add.  E.g.
    // 0 is before first region, shift other regions forward by 1
    // If N is last region index, add to N + 1, as long as N + 1 < max number of regions.
    // So need to calculate index before calling, and make sure it is legit.
    func undoablyAddRegion(_ region: Region, atIndex index: Int) {
        let originalRegion = region
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablyRemoveRegion(originalRegion)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        ladder.regions.insert(region, at: index)
        initializeRegions()

        // TODO: reindexing needed?
        //        ladderView.ladder.clearLinkedMarks
        //        ladderView.ladder.linkMarks
        // TODO: need relink mark function
        ladder.reindexMarks()
        // also need to regroup marks
        setNeedsDisplay()
    }

    func undoablyRemoveRegion(_ region: Region) {
        assert(ladder.regions.count > Ladder.minRegionCount)
        let originalRegion = region
        let index = ladder.index(ofRegion: originalRegion)!
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablyAddRegion(region, atIndex: index)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        ladder.removeRegion(region)
        initializeRegions()
        setNeedsDisplay()
    }

    func addRegion(relation: RegionRelation) {
        guard ladder.regions.count < Ladder.maxRegionCount else { return }
        guard relation == .after || relation == .before else { return }
        guard let selectedRegion = selectedLabelRegion() else { return }
        guard var selectedIndex = ladder.index(ofRegion: selectedRegion) else { return }
        if relation == .after {
            selectedIndex += 1
        }
        var selectedRegionTemplate = selectedRegion.regionTemplate()
        selectedRegionTemplate.name = ""
        selectedRegionTemplate.description = ""
        let newRegion = Region(template: selectedRegionTemplate)
        undoablyAddRegion(newRegion, atIndex: selectedIndex)
    }

    func removeRegion() {
        // Can't remove last region
        guard ladder.regions.count > Ladder.minRegionCount else { return }
        guard let selectedRegion = selectedLabelRegion() else { return }
        undoablyRemoveRegion(selectedRegion)
    }

    func setRegionHeight(_ height: Int, forRegion region: Region) {
        let originalRegion = region
        let originalHeight = region.unitHeight
        currentDocument?.undoManager.registerUndo(withTarget: self) {target in
            target.setRegionHeight(originalHeight, forRegion: originalRegion)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        region.unitHeight = height
        initializeRegions()
        setNeedsDisplay()
    }
}

// MARK: - LadderViewDelegate protocol

protocol LadderViewDelegate: AnyObject {
    func getRegionProximalBoundary(view: UIView) -> CGFloat
    func getRegionDistalBoundary(view: UIView) -> CGFloat
    func getRegionMidPoint(view: UIView) -> CGFloat
    func getAttachedMarkLadderViewPositionY(view: UIView) -> CGPoint?
    func getPositionYInView(positionY: CGFloat, view: UIView) -> CGFloat
    func getTopOfLadder(view: UIView) -> CGFloat
    func getTopOfLadderView(view: UIView) -> CGFloat

    func refresh()
    func setActiveRegion(regionNum: Int)
    func hasActiveRegion() -> Bool
    func deleteAttachedMark()
    func linkMarksNearbyAttachedMark()
    func addAttachedMark(scaledViewPositionX: CGFloat)
    func unattachAttachedMark()
//    func linkNearbyMarks(mark: Mark)
    func moveAttachedMark(position: CGPoint)
    func fixBoundsOfAttachedMark()
    func attachedMarkAnchor() -> Anchor?
    func assessBlockAndImpulseOrigin(mark: Mark?)
    func getAttachedMarkScaledAnchorPosition() -> CGPoint?
    func setAttachedMarkAndLinkedMarksModes()
    func toggleAttachedMarkAnchor()
    func convertPosition(_: CGPoint, toView: UIView) -> CGPoint
    func updateMarkers()
    func assessBlockAndImpulseOriginAttachedMark()
}

// MARK: LadderViewDelegate implementation

extension LadderView: LadderViewDelegate {

    // MARK: - LadderView delegate methods
    // convert region upper boundary to view's coordinates and return to view
    func getRegionProximalBoundary(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: activeRegion?.proximalBoundaryY ?? 0)
        return convert(position, to: view).y
    }

    func getAttachedMarkLadderViewPositionY(view: UIView) -> CGPoint? {
        guard let position = anchorLadderViewPosition(ofMark: ladder.attachedMark) else {
            return nil
        }
        return convert(position, to: view)
    }

    func anchorRegionPosition(ofMark mark: Mark) -> CGPoint {
        let anchor = mark.anchor
        let anchorPosition: CGPoint
        switch anchor {
        case .proximal:
            anchorPosition = mark.segment.proximal
        case .middle:
            anchorPosition = mark.midpoint()
        case .distal:
            anchorPosition = mark.segment.distal
        }
        return anchorPosition
    }

    func anchorLadderViewPosition(ofMark mark: Mark?) -> CGPoint? {
        guard let mark = mark else { return nil }
        let region = ladder.region(ofMark: mark)
        var anchorPosition = anchorRegionPosition(ofMark: mark)
        anchorPosition = transformToScaledViewPosition(regionPosition: anchorPosition, region: region)
        return anchorPosition
    }

    func getTopOfLadder(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: ladder.regions[0].proximalBoundaryY)
        return convert(position, to: view).y
    }

    func getTopOfLadderView(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: 0)
        return convert(position, to: view).y
    }

    func convertPosition(_ position: CGPoint, toView view: UIView) -> CGPoint {
        return convert(position, to: view)
    }

    func getRegionMidPoint(view: UIView) -> CGFloat {
        guard let activeRegion = activeRegion else { return 0 }
        let position = CGPoint(x: 0, y: (activeRegion.distalBoundaryY -  activeRegion.proximalBoundaryY) / 2 + activeRegion.proximalBoundaryY)
        return convert(position, to: view).y
    }

    func getRegionDistalBoundary(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: activeRegion?.distalBoundaryY ?? 0)
        return convert(position, to: view).y
    }

    func refresh() {
        setNeedsDisplay()
    }

    func setActiveRegion(regionNum: Int) {
        activeRegion = ladder.region(atIndex: regionNum)
    }

    func hasActiveRegion() -> Bool {
        return activeRegion != nil && activeRegion?.mode == .active
    }

    func addAttachedMark(scaledViewPositionX positionX: CGFloat) {
        guard let activeRegion = activeRegion else {
            fatalError("activeRegion is nil in addAttachedMark(scaledViewPositionX positionX: CGFloat).")
        }
        ladder.attachedMark = ladder.addMark(at: positionX / scale, toRegion: activeRegion)
        if let attachedMark = ladder.attachedMark {
            undoablyAddMark(mark: attachedMark)
        }
    }

    func linkMarksNearbyAttachedMark() {
        guard let attachedMark = ladder.attachedMark else { return }
        // FIXME: out of place
        swapEndsIfNeeded(mark: attachedMark)
        let newNearbyMarks = getNearbyMarkIDs(mark: attachedMark)
        snapToNearbyMarks(mark: attachedMark, nearbyMarks: newNearbyMarks)
        linkNearbyMarks(mark: attachedMark, nearbyMarks: newNearbyMarks)
    }

    func assessBlockAndImpulseOriginAttachedMark() {
        assessBlockAndImpulseOrigin(mark: ladder.attachedMark)
        if let attachedMark = ladder.attachedMark {
            let linkedMarks = ladder.getLinkedMarksFromLinkedMarkIDs(attachedMark.linkedMarkIDs)
            assessBlockAndImpulseOrigin(marks: linkedMarks.allMarks)
        }
    }

    func reregisterAllMarks() {
        ladder.reregisterAllMarks()
    }

    func linkConnectedMarks() {
        guard snapMarks else { return }
        ladder.linkConnectedMarks()
    }

    func getNearbyMarkIDs(mark: Mark) -> LinkedMarkIDs {
        guard snapMarks else { return LinkedMarkIDs() }
        let minimum: CGFloat = nearbyMarkAccuracy / scale
        let nearbyMarkIDs = getNearbyMarkIDs(mark: mark, nearbyDistance: minimum)
        return nearbyMarkIDs
    }


    func highlightNearbyMarks(_ mark: Mark?) {
        guard snapMarks else { return }
        guard let mark = mark else { return }
        ladder.normalizeAllMarksExceptAttachedMark()
        let nearbyDistance = nearbyMarkAccuracy / scale
        setModeOfNearbyMarks(mark: mark, nearbyDistance: nearbyDistance)
    }

    func setModeOfNearbyMarks(mark: Mark, nearbyDistance: CGFloat) {
        let region = ladder.region(ofMark: mark)
        if let proximalRegion = ladder.regionBefore(region: region) {
            for neighboringMark in proximalRegion.marks {
                if assessCloseness(ofMark: mark, toNeighboringMark: neighboringMark, usingNearbyDistance: nearbyDistance) {
                    neighboringMark.mode = .linked
                }
            }
        }
        if let distalRegion = ladder.regionAfter(region: region) {
            for neighboringMark in distalRegion.marks {
                if assessCloseness(ofMark: mark, toNeighboringMark: neighboringMark, usingNearbyDistance: nearbyDistance) {
                    neighboringMark.mode = .linked

                }
            }
        }
        // check in the same region ("middle region", same as activeRegion)
        for neighboringMark in region.marks {
            if assessCloseness(ofMark: mark, toNeighboringMark: neighboringMark, usingNearbyDistance: nearbyDistance) {
                neighboringMark.mode = .linked
            }
        }
    }

    // Returns linked mark ids of marks close to passed in mark.
    func getNearbyMarkIDs(mark: Mark, nearbyDistance: CGFloat) -> LinkedMarkIDs {
        let region = ladder.region(ofMark: mark)
        var proximalMarkIds = MarkIdSet()
        var distalMarkIds = MarkIdSet()
        var middleMarkIds = MarkIdSet()
        if let proximalRegion = ladder.regionBefore(region: region) {
            for neighboringMark in proximalRegion.marks {
                if assessCloseness(ofMark: mark, toNeighboringMark: neighboringMark, usingNearbyDistance: nearbyDistance) {
                    proximalMarkIds.insert(neighboringMark.id)
                }
            }
        }
        if let distalRegion = ladder.regionAfter(region: region) {
            for neighboringMark in distalRegion.marks {
                if assessCloseness(ofMark: mark, toNeighboringMark: neighboringMark, usingNearbyDistance: nearbyDistance) {
                    distalMarkIds.insert(neighboringMark.id)
                }
            }
        }
        // check in the same region ("middle region", same as activeRegion)
        for neighboringMark in region.marks {
            if assessCloseness(ofMark: mark, toNeighboringMark: neighboringMark, usingNearbyDistance: nearbyDistance) {
                middleMarkIds.insert(neighboringMark.id)
            }
        }
        return LinkedMarkIDs(proximal: proximalMarkIds, middle: middleMarkIds, distal: distalMarkIds)
    }

    func assessCloseness(ofMark mark: Mark, toNeighboringMark neighboringMark: Mark, usingNearbyDistance nearbyDistance: CGFloat) -> Bool {
        guard mark != neighboringMark else { return false }
        let region = ladder.region(ofMark: mark)
        let neighboringRegion = ladder.region(ofMark: neighboringMark)
        // parallel marks in the same region are by definition not close
        if (region == neighboringRegion) && (Geometry.areParallel(mark.segment, neighboringMark.segment)) {
            return false
        }
        var isClose = false
        // To get minimum distance between two line segments, must get minimum distances between each segment and each endpoint of the other segment, and take minimum of all those.
        let ladderViewPositionNeighboringMarkSegment = transformToScaledViewSegment(regionSegment: neighboringMark.segment, region: neighboringRegion)
        let ladderViewPositionMarkProximal = transformToScaledViewPosition(regionPosition: mark.segment.proximal, region: region)
        let ladderViewPositionMarkDistal = transformToScaledViewPosition(regionPosition: mark.segment.distal, region: region)
        let distanceToNeighboringMarkSegmentProximal = Geometry.distanceSegmentToPoint(segment: ladderViewPositionNeighboringMarkSegment, point: ladderViewPositionMarkProximal)
        let distanceToNeighboringMarkSegmentDistal = Geometry.distanceSegmentToPoint(segment: ladderViewPositionNeighboringMarkSegment, point: ladderViewPositionMarkDistal)

        let ladderViewPositionMarkSegment = transformToScaledViewSegment(regionSegment: mark.segment, region: region)
        let ladderViewPositionNeighboringMarkProximal = transformToScaledViewPosition(regionPosition: neighboringMark.segment.proximal, region: neighboringRegion)
        let ladderViewPositionNeighboringMarkDistal = transformToScaledViewPosition(regionPosition: neighboringMark.segment.distal, region: neighboringRegion)
        let distanceToMarkSegmentProximal = Geometry.distanceSegmentToPoint(segment: ladderViewPositionMarkSegment, point: ladderViewPositionNeighboringMarkProximal)
        let distanceToMarkSegmentDistal = Geometry.distanceSegmentToPoint(segment: ladderViewPositionMarkSegment, point: ladderViewPositionNeighboringMarkDistal)

        if distanceToNeighboringMarkSegmentProximal < nearbyDistance
            || distanceToNeighboringMarkSegmentDistal < nearbyDistance
            || distanceToMarkSegmentProximal < nearbyDistance
            || distanceToMarkSegmentDistal < nearbyDistance {
            isClose = true
        }
        return isClose
    }

    func snapToNearbyMarks(mark: Mark, nearbyMarks: LinkedMarkIDs) {
        guard snapMarks else { return }
        // get the new segment to snap to, then set it undoably.
        var segment = mark.segment
        if nearbyMarks.proximal.count > 0 {
            // Only need to snap to one proximal and distal mark.
            if let markToSnap = ladder.lookup(id: nearbyMarks.proximal.first!) {
                segment.proximal.x = markToSnap.segment.distal.x
                segment.proximal.y = 0
            }
        }
        if nearbyMarks.distal.count > 0 {
            if let markToSnap = ladder.lookup(id: nearbyMarks.distal.first!) {
                segment.distal.x = markToSnap.segment.proximal.x
                segment.distal.y = 1.0
            }
        }
        // Potentially can link to more than one middle marks.
        for middleMarkID in nearbyMarks.middle {
            if let middleMark = ladder.lookup(id: middleMarkID) {
                // FIXME: this doesn't work for vertical mark.
                var distanceToProximal = Geometry.distanceSegmentToPoint(segment: middleMark.segment, point: mark.segment.proximal)
                distanceToProximal = min(distanceToProximal, Geometry.distanceSegmentToPoint(segment: mark.segment, point: middleMark.segment.proximal))
                var distanceToDistal = Geometry.distanceSegmentToPoint(segment: middleMark.segment, point: mark.segment.distal)
                distanceToDistal = min(distanceToDistal, Geometry.distanceSegmentToPoint(segment: mark.segment, point: middleMark.segment.distal))
                if distanceToProximal < distanceToDistal {
                    let x = middleMark.segment.getX(fromY: mark.segment.proximal.y)
                    if let x = x {
                        segment.proximal.x = x
                    }
                }
                else {
                    let x = middleMark.segment.getX(fromY: mark.segment.distal.y)
                    if let x = x {
                        segment.distal.x = x
                    }
                }
            }
        }
        setSegment(segment: segment, forMark: mark)
        if mark.anchor == .proximal {
            cursorViewDelegate.moveCursor(cursorViewPositionX: mark.segment.proximal.x)
        } else if mark.anchor == .middle {
            cursorViewDelegate.moveCursor(cursorViewPositionX: mark.midpoint().x)
        } else if mark.anchor == .distal {
            cursorViewDelegate.moveCursor(cursorViewPositionX: mark.segment.distal.x)
        }
    }

    func linkNearbyMarks(mark: Mark, nearbyMarks: LinkedMarkIDs) {
        guard snapMarks else { return }
        currentDocument?.undoManager?.registerUndo(withTarget: self) { target in
            target.unlinkNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        // Need to link all of them
        for proximalMark in nearbyMarks.proximal {
            mark.linkedMarkIDs.proximal.insert(proximalMark)
            let proxMark = ladder.lookup(id: proximalMark)
            proxMark?.linkedMarkIDs.distal.insert(mark.id)
        }
        for middleMark in nearbyMarks.middle {
            mark.linkedMarkIDs.middle.insert(middleMark)
            let middleMark = ladder.lookup(id: middleMark)
            middleMark?.linkedMarkIDs.middle.insert(mark.id)
        }
        for distalMark in nearbyMarks.distal {
            mark.linkedMarkIDs.distal.insert(distalMark)
            let distalMark = ladder.lookup(id: distalMark)
            distalMark?.linkedMarkIDs.proximal.insert(mark.id)
        }
        // FIXME: Trial
        assessBlockAndImpulseOrigin(mark: mark)
        let linkedMarks = ladder.getLinkedMarksFromLinkedMarkIDs(mark.linkedMarkIDs)
        assessBlockAndImpulseOrigin(marks: linkedMarks.allMarks)
    }

    func unlinkNearbyMarks(mark: Mark, nearbyMarks: LinkedMarkIDs) {
        guard snapMarks else { return }
        currentDocument?.undoManager?.registerUndo(withTarget: self) { target in
            target.linkNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        for proximalMark in nearbyMarks.proximal {
            mark.linkedMarkIDs.proximal.remove(proximalMark)
            let proxMark = ladder.lookup(id: proximalMark)
            proxMark?.linkedMarkIDs.distal.remove(mark.id)
        }
        for middleMark in nearbyMarks.middle {
            mark.linkedMarkIDs.middle.remove(middleMark)
            let middleMark = ladder.lookup(id: middleMark)
            middleMark?.linkedMarkIDs.middle.remove(mark.id)
        }
        for distalMark in nearbyMarks.distal {
            mark.linkedMarkIDs.distal.remove(distalMark)
            let distalMark = ladder.lookup(id: distalMark)
            distalMark?.linkedMarkIDs.proximal.remove(mark.id)
        }
        // FIXME: Trial
        assessBlockAndImpulseOrigin(mark: mark)
        let linkedMarks = ladder.getLinkedMarksFromLinkedMarkIDs(mark.linkedMarkIDs)
        assessBlockAndImpulseOrigin(marks: linkedMarks.allMarks)
    }

    func getPositionYInView(positionY: CGFloat, view: UIView) -> CGFloat {
        let point = CGPoint(x: 0, y: positionY)
        return convert(point, to: view).y
    }

    func getAttachedMarkScaledAnchorPosition() -> CGPoint? {
        return getMarkScaledAnchorPosition(ladder.attachedMark)
    }

    func getMarkScaledAnchorPosition(_ mark: Mark?) -> CGPoint? {
        guard let mark = mark, let activeRegion = activeRegion else { return nil}
        return transformToScaledViewPosition(regionPosition: mark.getAnchorPosition(), region: activeRegion)
    }

    func attachedMarkAnchor() -> Anchor? {
        guard let attachedMark = ladder.attachedMark else { return nil }
        return attachedMark.anchor
    }

    func unattachAttachedMark() {
        // FIXME: Why is this part of unattachedAttachedMark??
//        assessBlockAndImpulseOrigin(mark: ladder.attachedMark)
        ladder.attachedMark = nil
    }

    func deleteAttachedMark() {
        os_log("deleteAttachedMark() - LadderView", log: OSLog.debugging, type: .debug)
        if let mark = ladder.attachedMark {
            undoablyDeleteMark(mark: mark)
        }
    }

    func toggleAttachedMarkAnchor() {
        toggleAnchor(mark: ladder.attachedMark)
        if let attachedMark = ladder.attachedMark {
            adjustCursor(mark: attachedMark)
        }
    }

    func selectAllMarks() {
        ladder.setAllMarksWithMode(.selected)
        for region in ladder.regions {
            region.mode = .selected
        }
        ladder.zone.isVisible = false
        setNeedsDisplay()
    }

    func clearSelection() {
        ladder.setAllMarksWithMode(.normal)
        for region in ladder.regions {
            region.mode = .normal
        }
        ladder.zone.isVisible = false
        setNeedsDisplay()
    }

    func saveState() {
        os_log("saveState() - LadderView", log: .default, type: .default)
        savedActiveRegion = activeRegion
        activeRegion = nil
    }

    func restoreState() {
        os_log("restoreState() - LadderView", log: .default, type: .default)
        activeRegion = savedActiveRegion
    }

    // Debug
    func debugPrintAttachedMark() {
        if let attachedMark = ladder.attachedMark {
            print("****attached mark", attachedMark.debugDescription)
        } else {
            print("****no attached mark")
        }
    }
}

// MARK: - enums

enum TextVisibility: Int, Codable {
    case visibility
    case invisible
    case visibleIfFits
}

enum Adjustment {
    case adjust
    case trim
}

enum LadderError: Error {
    case notCalibrated
    case tooFewMarks
    case requireTwoMarks
    case marksInDifferentRegions
    case marksNotContiguous
    case tooManyRegions
    case marksIntersect
    case marksNotVertical
    case intervalTooShort
    case marksNotParallel

    public var errorDescription: String? {
        switch self {
        case .notCalibrated:
            return L("Diagram is not calibrated.  You must calibrate first.")
        case .tooFewMarks:
            return L("There are too few marks.  You need to select at least 2 marks.")
        case .requireTwoMarks:
            return L("Exactly two marks must be selected.")
        case .marksInDifferentRegions:
            return L("Selected marks are in different regions.  Marks must me in the same region..")
        case .marksNotContiguous:
            return L("Marks are not contiguous.  Selected marks must be contiguous.")
        case .tooManyRegions:
            return L("Rhythm can only be set in one region at a time.")
        case .marksIntersect:
            return L("Marks cannot intersect")
        case .marksNotVertical:
            return L("Marks must be vertical.")
        case .intervalTooShort:
            return L("Interval is too short.")
        case .marksNotParallel:
            return L("Marks are not parallel.")
        }
    }
}


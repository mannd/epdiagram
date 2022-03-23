//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import OSLog
import CoreMedia

/// A view that manages and displays the ladder.
final class LadderView: ScaledView {

    // For debugging
    #if DEBUG  // Change this for debugging impulse origins and block
    var showProxEnd = false
    var showEarliestPoint = false
    var debugMarkMode = false
    var showPivots = false
    #else  // Don't ever change these.  They must all be FALSE.
    var showProxEnd = false
    var showEarliestPoint = false
    var debugMarkMode = false
    var showPivots = false
    #endif

    // Constants
    private let ladderPaddingMultiplier: CGFloat = 0.5
    private let accuracy: CGFloat = 20
    private let lowerLimitMarkHeight: CGFloat = 0.1
    private let lowerLimitMarkWidth: CGFloat = 20
    private let nearbyMarkAccuracy: CGFloat = 15
    private let arrowHeadAngle = CGFloat(Double.pi / 6)
    private let maxRegionMeasurements = 20
    private let intervalMargin: CGFloat = 10
    /// If more than this number of marks in a region, don't draw intervals
    private let maxMarksForIntervals = 200   // We may revisit this limit in the future.
    private let minRepeatCLInterval: CGFloat = 20
    private let draggedMarkSnapToBoundaryMargin: CGFloat = 0.05

    let measurementTextFontSize: CGFloat = 15.0
    let labelTextFontSize: CGFloat = 18.0
    let descriptionTextFontSize: CGFloat = 12.0
    /// Affects how far mark label and conduction time are away from the mark.
    let labelOffset: CGFloat = 12.0

    lazy var measurementTextAttributes: [NSAttributedString.Key: Any] = {
        let textFont = UIFont.systemFont(ofSize: measurementTextFontSize, weight: UIFont.Weight.medium)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: UIColor.label,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
        ]
        return attributes
    }()

    lazy var leftJustifiedMeasurementTextAttributes: [NSAttributedString.Key: Any] = {
        let textFont = UIFont.systemFont(ofSize: measurementTextFontSize, weight: UIFont.Weight.medium)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: UIColor.label,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
        ]
        return attributes
    }()

    lazy var labelTextAttributes: [NSAttributedString.Key: Any] = {
        let textFont = UIFont.systemFont(ofSize: labelTextFontSize, weight: UIFont.Weight.heavy)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: textFont,
        ]
        return attributes
    }()

    lazy var descriptionTextAttributes: [NSAttributedString.Key: Any] = {
        let textFont = UIFont.systemFont(ofSize: descriptionTextFontSize, weight: UIFont.Weight.regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: textFont,
        ]
        return attributes
    }()

    // set by preferences
    var markLineWidth: CGFloat = CGFloat(Preferences.markLineWidth)
    var showImpulseOrigin = Preferences.showImpulseOrigin
    var impulseOriginContiguous = Preferences.impulseOriginContiguous
    var impulseOriginLarge = Preferences.impulseOriginLarge
    var showBlock = Preferences.showBlock
    var showArrows = Preferences.showArrows
    var showIntervals = Preferences.showIntervals
    var showConductionTimes = Preferences.showConductionTimes
    var showMarkLabels = Preferences.showMarkLabels
    var snapMarks = Preferences.snapMarks
    var defaultMarkStyle = Mark.Style(rawValue: Preferences.markStyle)! {
        didSet {
            ladder.defaultMarkStyle = defaultMarkStyle
        }
    }
    var labelDescriptionVisibility = TextVisibility(rawValue: Preferences.labelDescriptionVisibility)!
    var marksAreHidden: Bool = Preferences.hideMarks
    var doubleLineBlockMarker: Bool = Preferences.doubleLineBlockMarker
    var rightAngleBlockMarker: Bool = Preferences.rightAngleBlockMarker
    var hideZeroCT: Bool = Preferences.hideZeroCT
    var showPeriods: Bool = Preferences.showPeriods
    var periodPosition: PeriodPosition = PeriodPosition(rawValue: Preferences.periodPosition)!
    var periodTransparency: CGFloat = CGFloat(Preferences.periodTransparency)
    var periodTextJustification = TextJustification(rawValue: Preferences.periodTextJustification)!
    var periodOverlapMark: Bool = Preferences.periodOverlapMark
    var declutterIntervals: Bool = Preferences.declutterIntervals

    // colors set by preferences
    var activeColor = Preferences.defaultActiveColor
    var attachedColor = Preferences.defaultAttachedColor
    var connectedColor = Preferences.defaultConnectedColor
    var selectedColor = Preferences.defaultSelectedColor
    var linkedColor = Preferences.defaultLinkedColor
    var periodColor = Preferences.defaultPeriodColor

    var normalColor = UIColor.label  // normalColor is fixed

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
    private var dragCreatedMark: Mark?
    private var dragOriginDivision: RegionDivision = .none
    var isDragging: Bool = false
    var isDraggingSelectedMarks: Bool = false
    var diffs: [Mark: CGFloat] = [:]
    var movementDiffs: [Mark: (prox: CGFloat, distal: CGFloat)] = [:]

    var ladderIntervals: [Int: [Interval]] = [:]

    var copiedMarks: [Mark] = []
    var patternMarks: [Mark] = []
    var selectedMarksPeriods: [Period] = []

    private var savedActiveRegion: Region?
    private var savedMode: Mode = .normal

    // array of two unscaled tap positions, corresponding with connected mark array
    private var connectedMarkTapPositions: [CGPoint] = []

    var mode: Mode = .normal

    var isActivated: Bool = true {
        didSet {
            isUserInteractionEnabled = isActivated
            alpha = isActivated ? 1.0 : 0.4
        }
    }

    var leftMargin: CGFloat = 0
    var viewHeight: CGFloat = 0
    // viewMaxWidth is width of image, or width of ladderView if no image is present
    var viewMaxWidth: CGFloat = 0 {
        didSet {
            if viewMaxWidth == 0 { // no image loaded, so use frame.width
                viewMaxWidth = frame.width
            }
        }
    }
    private var regionUnitHeight: CGFloat = 0

    weak var cursorViewDelegate: CursorViewDelegate! // Note IUO.
    weak var currentDocument: DiagramDocument?

    override var canBecomeFirstResponder: Bool { return true }

    // MARK: - init

    required init?(coder aDecoder: NSCoder) {
        print("****LadderView init*****")
        os_log("init(coder:) - LadderView", log: .viewCycle, type: .info)
        super.init(coder: aDecoder)
        setupView()
    }

    // used for unit testing
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    deinit {
        print("*****LadderView deinit()******")
    }

    func reset() {
        os_log("reset() - LadderView", log: .action, type: .info)
    }

    private func setupView() {
        os_log("setupView() - LadderView", log: .action, type: .info)
        viewHeight = self.frame.height
        initializeRegions()
        removeConnectedMarks()

        // Set up touches.
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTapRecognizer)

        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        self.addGestureRecognizer(doubleTapRecognizer)

        let draggingPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handleDrag))
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
        // We make the middle division the largest division.  Anything dragged within the outer division boundary snaps to the boundary.
        let outerDivisionBoundaryFraction: CGFloat = 0.2
        // We make the proximal and distal divisions smaller...
        if positionY < region.proximalBoundaryY + outerDivisionBoundaryFraction * (region.distalBoundaryY - region.proximalBoundaryY) {
            return .proximal
        }
        else if positionY < region.proximalBoundaryY + (1 - outerDivisionBoundaryFraction) * (region.distalBoundaryY - region.proximalBoundaryY) {
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
                // An alternative would be to use RegionDivision to position the anchor rather than
                // just toggle the anchor with each tap, but RegionDivision is somewhat imprecise
                // so we have committed to taps toggling the anchor.
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
        os_log("connect(marksToConnect:) - LadderView", log: OSLog.touches, type: .info)

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
        } else if abs(regionDifference) == 1 {
            if regionDifference > 0 {
                // If first and secondRegionIndex aren't out of range, markRegion can't be either.
                let markRegion = ladder.region(atIndex: secondRegionIndex)
                let segment = Segment(proximal: CGPoint(x: marks[0].segment.distal.x, y: 0), distal: transformToRegionPosition(scaledViewPosition: connectedMarkTapPositions[1], region: markRegion))

                let mark = ladder.addMark(fromSegment: segment, toRegion: markRegion)
                undoablyAddMark(mark: mark)
                let nearbyMarks = getNearbyMarkIDs(mark: mark)
                snapToNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
                return mark
            }
            if regionDifference < 0 {
                let markRegion = ladder.region(atIndex: firstRegionIndex)
                let segment = Segment(proximal: CGPoint(x: marks[1].segment.distal.x, y: 0), distal: transformToRegionPosition(scaledViewPosition: connectedMarkTapPositions[0], region: markRegion))
                let mark = ladder.addMark(fromSegment: segment, toRegion: markRegion)
                undoablyAddMark(mark: mark)
                let nearbyMarks = getNearbyMarkIDs(mark: mark)
                snapToNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
                return mark
            }
        }
        return nil
    }

    private func connectTappedMark(_ mark: Mark, position: CGPoint) {
        os_log("connectTappedMark(mark:) - LadderView", log: OSLog.touches, type: .info)

        switch ladder.connectedMarks.count {
        case 2...:
            ladder.connectedMarks.removeAll()
            connectedMarkTapPositions.removeAll()
            normalizeAllMarks()
            ladder.connectedMarks.append(mark)
            connectedMarkTapPositions.append(position)
            mark.mode = .connected
            return
        case 0:
            ladder.connectedMarks.append(mark)
            connectedMarkTapPositions.removeAll()
            connectedMarkTapPositions.append(position)
            mark.mode = .connected
            return
        case 1:
            guard mark != ladder.connectedMarks[0] else { return }
            // different mark tapped
            // what region is the mark in?
            connectedMarkTapPositions.append(position)
            let markRegionIndex = ladder.regionIndex(ofMark: mark)
            let firstMarkRegionIndex = ladder.regionIndex(ofMark: ladder.connectedMarks[0])
            let regionDistance = abs(markRegionIndex - firstMarkRegionIndex)
            if regionDistance > 0 && regionDistance < 3 {
                ladder.connectedMarks.append(mark)
                mark.mode = .connected
                if let connectedMark = connect(marksToConnect: ladder.connectedMarks) {
                    ladder.connectedMarks.append(connectedMark)
                    connectedMark.mode = .connected
                    linkConnectedMarks()
                    assessBlockAndImpulseOriginOfMark(connectedMark)
                }
            } else {
                ladder.connectedMarks.removeAll()
                connectedMarkTapPositions.removeAll()
            }
        default:
            assertionFailure("Impossible connected mark count.")
        }
    }

    func removeConnectedMarks() {
        os_log("removeConnectedMarks() - LadderView", log: OSLog.touches, type: .info)

        ladder.connectedMarks.removeAll()
    }

    fileprivate func addBlockedMark(newMark: Mark, tapRegionPosition: CGPoint, endPoint: Mark.Endpoint) {
        os_log("addBlockedMark(newMark) - LadderView", log: OSLog.touches, type: .info)

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
        os_log("connectTappedMarkToBlockedMark(position:region:) - LadderView", log: OSLog.touches, type: .info)

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
        os_log("connectModeSingleTap(_:) - LadderView", log: OSLog.touches, type: .info)

        if let mark = tapLocationInLadder.mark {
            connectTappedMark(mark, position: tapLocationInLadder.unscaledPosition)
        }
        else if let region = tapLocationInLadder.region {
            connectTappedMarkToBlockedMark(position: tapLocationInLadder.unscaledPosition, region: region)
        }
        setNeedsDisplay()
    }

    private func selectModeSingleTap(_ tapLocationInLadder: LocationInLadder) {
        if copiedMarks.count > 0 {
            pasteMarks(tapLocationInLadder: tapLocationInLadder)
            return
        }
        if patternMarks.count > 0 {
            repeatPattern(tapLocationInLadder: tapLocationInLadder, justOnce: true)
            return
        }
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

    func attachMark(_ mark: Mark?) {
        os_log("attachMark(_:) - LadderView", log: OSLog.action, type: .info)
        ladder.attachedMark = mark
    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        os_log("doubleTap(tap:) - LadderView", log: OSLog.touches, type: .info)
        guard !marksAreHidden else { return }
        if patternMarks.count > 0 {
            let position = tap.location(in: self)
            let tapLocationInLadder = getLocationInLadder(position: position)
            repeatPattern(tapLocationInLadder: tapLocationInLadder, justOnce: false)

            return
        }
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
        currentDocument?.undoManager.beginUndoGrouping()
        if tapLocationInLadder.specificLocation == .mark {
            if let mark = tapLocationInLadder.mark {
                undoablyDeleteMark(mark: mark)
            }
        }
        currentDocument?.undoManager.endUndoGrouping()
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

    private func undoablyAddMark(mark: Mark) {
        os_log("undoablyAddMark(mark:) - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.undoablyDeleteMark(mark: mark)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        // We don't snap or link nearby marks, calling function must do that.
        updateMarkersAndRegionIntervals(ladder.region(ofMark: mark))
        assessBlockAndImpulseOriginOfMark(mark)
    }

    // See https://stackoverflow.com/questions/36491789/using-nsundomanager-how-to-register-undos-using-swift-closures/36492619#36492619
    func undoablyDeleteMark(mark: Mark) {
        os_log("undoablyDeleteMark(mark:region:) - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.redoablyUndeleteMark(mark: mark)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        let nearbyMarks = getNearbyMarkIDs(mark: mark)
        unlinkNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
        ladder.deleteMark(mark)
        let region = ladder.region(ofMark: mark)
        updateMarkersAndRegionIntervals(region)
        hideCursorAndNormalizeAllMarks()
        if mode == .select {
            ladder.normalizeRegions()
            ladder.hideZone()
        }
    }

    func redoablyUndeleteMark(mark: Mark) {
        os_log("redoablyUndeleteMark(mark:region:) - LadderView", log: OSLog.debugging, type: .debug)

        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.undoablyDeleteMark(mark: mark)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        let region = ladder.region(ofMark: mark)
        ladder.addMark(mark, toRegion: region, newMark: false)
        mark.mode = .normal
        updateMarkersAndRegionIntervals(region)
        hideCursorAndNormalizeAllMarks()
        if mode == .select {
            ladder.normalizeRegions()
            ladder.hideZone()
        }
        let nearbyMarks = getNearbyMarkIDs(mark: mark)
        snapToNearbyMarks(mark: mark, nearbyMarks: mark.linkedMarkIDs)
        linkNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
        assessBlockAndImpulseOriginOfMark(mark)
    }

    // multi-mark variants of above

    private func undoablyAddMarks(marks: [Mark]) {
        os_log("undoablyAddMark(mark:) - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.undoablyDeleteMarks(marks: marks)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        // We just set up undo/redo with this method.
        // Assessment of block, IO and intervals is done outside of this procdure.
    }

    func undoablyDeleteMarks(marks: [Mark]) {
        os_log("undoablyDeleteMark(mark:region:) - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.redoablyUndeleteMarks(marks: marks)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        unlinkAllMarks()
        for mark in marks {
            ladder.deleteMark(mark)
        }
        hideCursorAndNormalizeAllMarks()
        if mode == .select {
            ladder.normalizeRegions()
            ladder.hideZone()
        }
        relinkAllMarks()
        updateMarkersAndLadderIntervals()
    }

    func redoablyUndeleteMarks(marks: [Mark]) {
        os_log("redoablyUndeleteMark(mark:region:) - LadderView", log: OSLog.debugging, type: .debug)

        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.undoablyDeleteMarks(marks: marks)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        unlinkAllMarks()
        for mark in marks {
            let region = ladder.region(ofMark: mark)
            ladder.addMark(mark, toRegion: region, newMark: false)
            mark.mode = .normal
            // Won't bother snapping when moving multiple marks, it is too processor intense
        }
        hideCursorAndNormalizeAllMarks()
        if mode == .select {
            ladder.normalizeRegions()
            ladder.hideZone()
        }
        relinkAllMarks()
        updateMarkersAndLadderIntervals()
    }

    // remove marks that overlap with the marks passed to this function
    func removeOverlappingMarks(with marks: [Mark]) {
        for mark in marks {
            for otherMark in ladder.region(ofMark: mark).marks {
                if otherMark != mark && otherMark.segment == mark.segment {
                    undoablyDeleteMark(mark: otherMark)
                }
            }
        }
    }

    func removeAllOverlappingMarks() {
        removeOverlappingMarks(with: ladder.allMarks())
    }

    // MARK: dragging

    /// Handle dragging (panning) on LadderView, depending on mode
    /// - Parameter gesture: gesture passed by gesture recognizer
    @objc func handleDrag(gesture: UIPanGestureRecognizer) {
        guard !marksAreHidden else { return }
        switch mode {
        case .select:
            handleSelectModeDrag(gesture)
        case .normal:
            handleNormalModeDrag(gesture)
        default:
            break
        }
    }

    /// This method handles moving attached marks and also creating marks using dragging
    ///
    /// The movement process is complex, involving moving the mark along with its linked marks,
    /// moving the cursor in parallel, highlighting nearby marks,
    /// and snapping to nearby marks at the end of the move, as well as updating intervals as well as block
    /// and impulse origin of the moving mark and its linked marks.
    ///
    /// For an attached mark, the order of events is:
    ///    move the mark, linked marks, and cursor
    ///    update markers and intervals while moving
    ///    highlight nearby marks while moving
    ///    at end of movement, snap to the nearby marks and add the nearby marks to the linked marks
    ///    assess block and impulse origin of mark and linked marks
    ///
    /// All of the above is completely undoably and redoably.
    ///
    /// This method should probably be refactored to separate out the two functions: moving the attached
    /// mark, and creating a free-form mark.  Also, setNeedsDisplay() is called many times indirectly and
    /// possibly unnecessarily, but I very much doubt iOS cares about extra setNeedsDisplay() calls.
    /// - Parameter gesture: gesture passed by gesture recognizer
    private func handleNormalModeDrag(_ gesture: UIPanGestureRecognizer) {
        let position = gesture.location(in: self)
        let state = gesture.state
        let locationInLadder = getLocationInLadder(position: position)

        if state == .began {
            isDragging = true
            currentDocument?.undoManager?.beginUndoGrouping()
            if let region = locationInLadder.region {
                regionOfDragOrigin = region
                activeRegion = region
            }
            if let regionOfDragOrigin = regionOfDragOrigin {
                if let mark = locationInLadder.mark, mark.mode == .attached { // move attached mark
                    movingMark = mark
                    // NB: Need to move it nowhere, to let undo get back to starting position!
                    if let anchorPosition = getMarkScaledAnchorPosition(mark) {
                        moveMark(mark: mark, scaledViewPosition: anchorPosition) // calls setNeedsDisplay() -- undoable
                    }
                }
                else {  // We need to make a new mark.
                    hideCursorAndNormalizeAllMarks() // doesn't call setNeedsDisplay()
                    unattachAttachedMark() // doesn't call setNeedsDisplay()
                    // Get the third of region for endpoint of new mark.
                    dragOriginDivision = locationInLadder.regionDivision
                    switch dragOriginDivision {
                    case .proximal:
                        dragCreatedMark = addMarkToActiveRegion(scaledViewPositionX: position.x)
                        dragCreatedMark?.segment.proximal.y = 0
                        dragCreatedMark?.segment.distal.y = 0.5
                    case .middle:
                        dragCreatedMark = addMarkToActiveRegion(scaledViewPositionX: position.x)
                        dragCreatedMark?.segment.proximal.y = regionOfDragOrigin.relativeYPosition(y: position.y) ?? 0
                        dragCreatedMark?.segment.distal.y = 0.75
                    case .distal:
                        dragCreatedMark = addMarkToActiveRegion(scaledViewPositionX: position.x)
                        dragCreatedMark?.segment.proximal.y = 0.5
                        dragCreatedMark?.segment.distal.y = 1
                    case .none:
                        assert(false, "Making a mark with a .none regionDivision!")
                    }
                    if let dragCreatedMark = dragCreatedMark {
                        // undoablyAddMark updates block, IO, region markers and intervals.
                        // Block and IO are not updated while when dragging, so until the drag is
                        // complete, the IO symbol is always at the start of the drag, and there is
                        // no block symbol.  To avoid this, we set IO setting to .none, so the IO
                        // symbol is not drawn until we finish the drag.
                        dragCreatedMark.impulseOriginSetting = .none
                        undoablyAddMark(mark: dragCreatedMark) // indirectly calls setNeedsDisplay()
                    }
                }
            }
        }
        if state == .changed {
            if let mark = movingMark {
                // moveMark() indirectly calls setSegment() for mark and linked marks, which undoably
                // assesses Block and IO of mark and linked marks, and assesses intervals and markers
                // in regions of the marks and linked marks.
                moveMark(mark: mark, scaledViewPosition: position) // calls setNeedsDisplay() - undoable
                highlightNearbyMarks(mark) // doesn't call setNeedsDisplay()
            }
            else if regionOfDragOrigin == locationInLadder.region, let regionOfDragOrigin = regionOfDragOrigin {
                // We set the segments directly here, as we don't need to undo setting these segments;
                // the undo action for a drag created mark is simply to delete it.
                switch dragOriginDivision {
                case .proximal, .middle:
                    dragCreatedMark?.segment.distal = transformToRegionPosition(scaledViewPosition: position, region: regionOfDragOrigin)
                case .distal:
                    dragCreatedMark?.segment.proximal = transformToRegionPosition(scaledViewPosition: position, region: regionOfDragOrigin)
                default:
                    break
                }
                highlightNearbyMarks(dragCreatedMark) // doesn't call setNeedsDisplay()
                // A drag created mark only affects intervals in the active region, and has no
                // linked marks, so just update the active region markers and intervals.
                updateMarkersAndRegionIntervals(activeRegion) // calls setNeedsDisplay()
            }
        }
        if state == .ended {
            isDragging = false
            if let movingMark = movingMark {
                swapEndpointsIfNeeded(mark: movingMark) // undoable
                let newNearbyMarks =
                    getNearbyMarkIDs(mark: movingMark)
                snapToNearbyMarks(mark: movingMark, nearbyMarks: newNearbyMarks) // indirect setNeedsDisplay() - undoable
                linkNearbyMarks(mark: movingMark, nearbyMarks: newNearbyMarks) // doesn't call setNeedsDisplay()
            }
            else if let dragCreatedMark = dragCreatedMark {
                if dragCreatedMark.height < lowerLimitMarkHeight && dragCreatedMark.width < lowerLimitMarkWidth {
                    // Need to undoably delete here, or else undo and redo restores the tiny mark.
                    undoablyDeleteMark(mark: dragCreatedMark) // indirect setNeedsDisplay()
                }
                else {
                    swapEndpointsIfNeeded(mark: dragCreatedMark)
                    dragCreatedMark.impulseOriginSetting = .auto
                    // Check if close to boundary
                    if dragCreatedMark.segment.proximal.y < draggedMarkSnapToBoundaryMargin {
                        var segment = dragCreatedMark.segment
                        segment.proximal.y = 0
                        setSegment(segment: segment, forMark: dragCreatedMark) // calls setNeedsDisplay()
                    }
                    if dragCreatedMark.segment.distal.y < 1.0 && dragCreatedMark.segment.distal.y > (1.0 - draggedMarkSnapToBoundaryMargin) {
                        var segment = dragCreatedMark.segment
                        segment.distal.y = 1.0
                        setSegment(segment: segment, forMark: dragCreatedMark) // calls setNeedsDisplay()
                    }
                    let newNearbyMarks = getNearbyMarkIDs(mark: dragCreatedMark)
                    snapToNearbyMarks(mark: dragCreatedMark, nearbyMarks: newNearbyMarks) // calls setNeedsDisplay()
                    linkNearbyMarks(mark: dragCreatedMark, nearbyMarks: newNearbyMarks) // doesn't call setNeedsDisplay() -- undoable
                    assessBlockAndImpulseOriginOfMark(dragCreatedMark) // doesn't call setNeedsDisplay()
                }
            }
            currentDocument?.undoManager.endUndoGrouping()
            if !cursorViewDelegate.cursorIsVisible {
                normalizeAllMarks() // doesn't call setNeedsDisplay()
            }
            movingMark = nil
            dragCreatedMark = nil
            regionOfDragOrigin = nil
            dragOriginDivision = .none
        }
        cursorViewDelegate.refresh()
        setNeedsDisplay() // Need to reassess earlier redundant calls to setNeedsDisplay()
    }



    /// Handle dragging in select (edit) mode
    /// - Parameter gesture: gesture passed by gesture recognizer
    func handleSelectModeDrag(_ gesture: UIPanGestureRecognizer) {
        if isDraggingSelectedMarks {
            handleSelectModeMarksDrag(gesture)
        } else {
            handleSelectModeZoneDrag(gesture)
        }
    }

    // Consider change to setSegments() instead of setSegment().
    func handleSelectModeMarksDrag(_ gesture: UIPanGestureRecognizer) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        ladder.hideZone()
        let location = gesture.location(in: self)
        let state = gesture.state
        if state == .began {
            isDragging = true
            currentDocument?.undoManager.beginUndoGrouping()
            for mark in selectedMarks {
                // we don't unlink marks during block movement, they stay linked
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

    /// Handles dragging in select mode, except when the move marks feature is active
    ///
    /// When draggin in select mode, we want to create a zone, with the marks within the zone selected.
    /// A zone is very similar to a highlighted selection in a word processor, except when zone encompass
    /// multiple regions, they can't deselect the region by reversing the direction of the drag.  This is a limitation
    /// that could be programmed around, but probably not worth the effort.
    /// - Parameter gesture: gesture passed in by the gesture recognizer
    func handleSelectModeZoneDrag(_ gesture: UIPanGestureRecognizer) {
        let position = gesture.location(in: self)
        let state = gesture.state
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

    @available(*, deprecated, message: "Not used in production or test code at present.")
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

    /// Enforces that a mark segment proximal y coordinate is always `<=` the distal y coordinate
    ///
    /// This is an undoable/redoable method.
    /// - Parameter mark: mark whose segment endpoints will be swapped if necessary
    private func swapEndpointsIfNeeded(mark: Mark) {
        os_log("swapEndsIfNeeded(mark:) - LadderView", log: .default, type: .default)

        let proximalY = mark.segment.proximal.y
        let distalY = mark.segment.distal.y
        if proximalY > distalY {
            undoablySwapEndpoints(mark: mark)
        }
    }

    private func undoablySwapEndpoints(mark: Mark) {
        os_log("undoablyUnswapEnds(mark:) - LadderView", log: .default, type: .default)

        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySwapEndpoints(mark: mark)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        mark.swapEnds()
        mark.swapAnchors()
    }

    func swapEndpointsIfNeededOfAllMarks() {
        os_log("swapEndsIfNeeded() - LadderView", log: .default, type: .default)

        ladder.regions.forEach {
            region in region.marks.forEach {
                mark in self.swapEndpointsIfNeeded(mark: mark)
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
            moveMark(movement: cursorViewDelegate.cursorMovement(), mark: mark, regionPosition: regionPosition)
        }
    }

    func moveMark(movement: Movement, mark: Mark, regionPosition: CGPoint) {
        let segment = Mark.segmentAfterMovement(mark: mark, movement: movement, to: regionPosition)
        setSegment(segment: segment, forMark: mark)
        moveLinkedMarks(forMark: mark)
        adjustCursor(mark: mark)
        setNeedsDisplay()
        cursorViewDelegate.refresh()
    }

    private func moveLinkedMarks(forMark mark: Mark) {
        //os_log("moveLinkedMarked(forMark:)", log: .action, type: .info)
        for proximalMark in ladder.getMarkSet(fromMarkIdSet: mark.linkedMarkIDs.proximal) {
            if mark == proximalMark { break }
            var segment = proximalMark.segment
            segment.distal.x = mark.segment.proximal.x
            // We use setSegment() and not setSegments() in this method because the number of linked marks is going to be small, so no difference in performance is anticipated.
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
        }
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

    func setSelectedMarksLabel(labelPosition: Mark.LabelPosition) {
        guard let vc = findViewController() as? DiagramViewController else { return }
        let selectedMarks: [Mark] = ladder.allMarksWithMode(.selected)
        let selectedMarksLabels: [String?]
        switch labelPosition {
        case .left:
            selectedMarksLabels = selectedMarks.map { $0.leftLabel }
        case .proximal:
            selectedMarksLabels = selectedMarks.map { $0.proximalLabel }
        case .distal:
            selectedMarksLabels = selectedMarks.map { $0.distalLabel }
        }
        let dominantLabel = dominantStringOfStringArray(strings: selectedMarksLabels)
        UserAlert.showEditMarkLabelAlert(viewController: vc, defaultLabel: dominantLabel) { [weak self]  label in
            guard let self = self else { return }
            self.currentDocument?.undoManager.beginUndoGrouping()
            selectedMarks.forEach { mark in self.undoablySetMarkLabel(mark: mark, label: label, labelPosition: labelPosition) }
            self.currentDocument?.undoManager.endUndoGrouping()
            self.refresh()
        }
    }

    func undoablySetMarkLabel(mark: Mark, label: String?, labelPosition: Mark.LabelPosition) {
        let originalLabel: String?
        switch labelPosition {
        case .left:
            originalLabel = mark.leftLabel
        case .proximal:
            originalLabel = mark.proximalLabel
        case .distal:
            originalLabel = mark.distalLabel
        }
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetMarkLabel(mark: mark, label: originalLabel, labelPosition: labelPosition)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        switch labelPosition {
        case .left:
            mark.leftLabel = label
        case .proximal:
            mark.proximalLabel = label
        case .distal:
            mark.distalLabel = label
        }
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
        let selectedRegions: [Region] = ladder.allRegionsWithMode(.labelSelected)
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

    /// If a string array contains identical strings, returns that string, otherwise returns nil.
    /// - Parameter strings: strings to be tested, which can be nil
    /// - Returns: Either the "dominant" string or nil
    func dominantStringOfStringArray(strings: [String?]) -> String? {
        let count = strings.count
        for string in strings {
            if strings.filter({ $0 == string }).count == count {
                return string
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

    fileprivate func drawRegionLabel(rect: CGRect, region: Region, context: CGContext) {
        let stringRect = CGRect(x: 0, y: rect.origin.y, width: rect.origin.x, height: rect.height)
        labelTextAttributes[.foregroundColor] = region.mode == .active ? activeColor : selectedColor
        let text = region.name
        let labelText = NSAttributedString(string: text, attributes: labelTextAttributes)
        let size: CGSize = text.size(withAttributes: labelTextAttributes)
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

        guard labelDescriptionVisibility != .invisible else { return }
        descriptionTextAttributes[.foregroundColor] = region.mode == .active ? activeColor : selectedColor
        let descriptionText = NSAttributedString(string: region.longDescription, attributes: descriptionTextAttributes)

        let descriptionSize: CGSize = region.longDescription.size(withAttributes: descriptionTextAttributes)
        if labelDescriptionVisibility == .visibility || (labelDescriptionVisibility == .visibleIfFits && descriptionSize.width < stringRect.width) {
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
        // Needed so impulse origin circles are filled in.
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

        #if DEBUG  // These are only used for debugging, don't include in release
        drawPivots(forMark: mark, segment: Segment(proximal: p1, distal: p2), context: context)
        drawProxEnd(segment: segment, context: context)
        drawEarliestPoint(forMark: mark, segment: segment, context: context)
        #endif

        drawBlock(context: context, mark: mark, segment: segment)
        drawImpulseOrigin(context: context, mark: mark, segment: segment)
        drawConductionDirection(forMark: mark, segment: segment, context: context)
        drawConductionTime(forMark: mark, segment: segment, context: context)
        drawLabels(forMark: mark, segment: segment, context: context)

        // reset line color to neutral label color
        context.setStrokeColor(UIColor.label.cgColor)
    }

    fileprivate func drawIntervals(region: Region, context: CGContext) {
        guard showIntervals else { return }
        guard region.marks.count < maxMarksForIntervals else { return }
        guard let calibration = calibration, calibration.isCalibrated else { return }
        if let index = ladder.index(ofRegion: region), let intervals = ladderIntervals[index] {
            let isLastRegion = index == ladder.regions.count - 1 // TODO: refactor this to method or property
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

                if !isLastRegion && declutterIntervals { continue }

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
                        // Draw last region interval below bottom ladder line when decluttering intervals.
                        if isLastRegion && declutterIntervals {
                            origin = CGPoint(x: origin.x - size.width / 2, y: origin.y)
                        } else {
                            // Normally without decluttering we draw all intervals within the ladder.
                            origin = CGPoint(x: origin.x - size.width / 2, y: origin.y - size.height)
                        }
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

    func updateMarkersAndLadderIntervals() {
        updateMarkers()
        updateLadderIntervals()
        setNeedsDisplay()
    }

    func assessBlockAndImpulseOriginOfMark(_ mark: Mark) {
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                let linkedMarks = self.ladder.getLinkedMarksFromLinkedMarkIDs(mark.linkedMarkIDs)
                self.assessBlockAndImpulseOrigin(mark: mark)
                self.assessBlockAndImpulseOrigin(marks: linkedMarks.allMarks)
            }
        }
    }


    func assessBlockAndImpulseOrigin(mark: Mark?) {
        if let mark = mark {
            self.assessBlock(mark: mark)
            self.assessImpulseOrigin(mark: mark)
        }
        self.setNeedsDisplay()
    }

    func assessBlockAndImpulseOrigin(marks: MarkSet) {
                for mark in marks {
                    self.assessBlock(mark: mark)
                    self.assessImpulseOrigin(mark: mark)
                }
                self.setNeedsDisplay()
    }

    func assessBlockAndImpulseOriginOfMarks(_ marks: [Mark]) {
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                for mark in marks {
                    self.assessBlock(mark: mark)
                    self.assessImpulseOrigin(mark: mark)
                }
                self.setNeedsDisplay()
            }
        }
    }

    func assessBlockAndImpulseOriginForAllMarks() {
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                for mark in self.ladder.allMarks() {
                    self.assessBlock(mark: mark)
                    self.assessImpulseOrigin(mark: mark)
                }
                self.setNeedsDisplay()
            }
        }
    }

    func assessGlobalImpulseOrigin() {
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                let marks = self.ladder.allMarks()
                for mark in marks {
                    self.assessImpulseOrigin(mark: mark)
                }
            }

        }
    }

    func assessBlock(mark: Mark) {
        guard snapMarks else { return }
        if mark.blockSetting == .auto {
            mark.blockSite = mark.lateEndpoint
            if mark.latestPoint.y < 0.01 || mark.latestPoint.y > 0.99 {
                mark.blockSite = .none
            } else {
                for middleMarkID in mark.linkedMarkIDs.middle {
                    if let middleMark = ladder.lookup(id: middleMarkID) {
                        if Geometry.distanceSegmentToPoint(segment: middleMark.segment, point: mark.latestPoint) < 0.01 {
                            mark.blockSite = .none
                            break
                        }
                    }
                }
            }
        } else {
            mark.blockSite = mark.blockSetting
        }
    }

    func assessImpulseOrigin(mark: Mark) {
        guard snapMarks else { return }
        if mark.impulseOriginSetting == .auto {
            mark.impulseOriginSite = mark.earlyEndpoint
            if mark.earlyEndpoint == .proximal && mark.linkedMarkIDs.proximal.count > 0 {
                mark.impulseOriginSite = .none
            } else if  mark.earlyEndpoint == .distal && mark.linkedMarkIDs.distal.count > 0 {
                mark.impulseOriginSite = .none
            } else {
                for middleMarkID in mark.linkedMarkIDs.middle {
                    if let middleMark = ladder.lookup(id: middleMarkID) {
                        if Geometry.distanceSegmentToPoint(segment: middleMark.segment, point: mark.earliestPoint) < 0.01 {
                            mark.impulseOriginSite = .none
                            break
                        }
                    }
                }
            }
            // Handle special case of vertical mark, which defaults to having proximal impulse origin.
            if mark.impulseOriginSite == .none
                && mark.earlyEndpoint == .none
                && mark.linkedMarkIDs.proximal.count == 0 {
                mark.impulseOriginSite = .proximal
            }
        } else {
            mark.impulseOriginSite = mark.impulseOriginSetting
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

    func drawArrowHead(context: CGContext, start: CGPoint, end: CGPoint, pointerLineLength: CGFloat, arrowAngle: CGFloat, offset: CGFloat = 0) {
        var end = end
        if offset > 0 {
            end = getOffsetPoint(start: start, end: end, offset: offset)
        }
        let startEndAngle = atan((end.y - start.y) / (end.x - start.x)) + ((end.x - start.x) < 0 ? CGFloat(Double.pi) : 0)
        let arrowLine1 = normalizePoint(CGPoint(x: end.x + pointerLineLength * cos(CGFloat(Double.pi) - startEndAngle + arrowAngle), y: end.y - pointerLineLength * sin(CGFloat(Double.pi) - startEndAngle + arrowAngle)))
        let arrowLine2 = normalizePoint(CGPoint(x: end.x + pointerLineLength * cos(CGFloat(Double.pi) - startEndAngle - arrowAngle), y: end.y - pointerLineLength * sin(CGFloat(Double.pi) - startEndAngle - arrowAngle)))
        context.move(to: end)
        context.addLine(to: arrowLine1)
        context.move(to: end)
        context.addLine(to: arrowLine2)
        context.strokePath()
    }

    // see https://math.stackexchange.com/questions/175896/finding-a-point-along-a-line-a-certain-distance-away-from-another-point
    private func getOffsetPoint(start: CGPoint, end: CGPoint, offset: CGFloat) -> CGPoint {
        let distance = Segment(proximal: start, distal: end).length
        let x = end.x - (offset * (start.x - end.x)) / distance
        let y = end.y - (offset * (start.y - end.y)) / distance
        return CGPoint(x: x, y: y)
    }

    // For debugging only
    func drawProxEnd(segment: Segment, context: CGContext) {
        guard showProxEnd else { return }
        drawFilledCircle(context: context, position: segment.proximal, radius: 10)
    }

    // For debugging only
    func drawEarliestPoint(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard showEarliestPoint else { return }
        if mark.earliestPoint == mark.segment.proximal {
            drawFilledCircle(context: context, position: segment.proximal, radius: 20)
        } else {
            drawFilledCircle(context: context, position: segment.distal, radius: 20)
        }
    }

    // For debugging only
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

    func drawConductionDirection(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard showArrows else { return }
        let arrowLineLength: CGFloat = 20
        switch mark.lateEndpoint {
        case .distal:
            drawArrowHead(context: context, start: segment.proximal, end: segment.distal, pointerLineLength: arrowLineLength, arrowAngle: arrowHeadAngle)
        case .proximal:
            drawArrowHead(context: context, start: segment.distal, end: segment.proximal, pointerLineLength: arrowLineLength, arrowAngle: arrowHeadAngle)
        case .none, .auto, .random:
            break // this is undecided unless manually set
        }
    }


    func drawConductionTime(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard let calibration = calibration, calibration.isCalibrated, showConductionTimes else { return }
        let value = lround(conductionTime(fromSegment: segment))
        if hideZeroCT && value < 1 {
            return
        }
        var text = ""
        if debugMarkMode {
            text = String(mark.id.uuidString.prefix(4)) + String(mark.impulseOriginSite.rawValue)
        } else {
            text = "\(value)"
        }
        var origin = segment.midpoint
        let size = text.size(withAttributes: measurementTextAttributes)
        // Center the origin.
        origin = CGPoint(x: origin.x + labelOffset, y: origin.y - size.height / 2)
        let textRect = CGRect(origin: origin, size: size)
        if textRect.minX > leftMargin {
            text.draw(in: textRect, withAttributes: measurementTextAttributes)
            context.strokePath()
        }
    }

    func drawLabels(forMark mark: Mark, segment: Segment, context: CGContext) {
        // Don't draw over earliest point
        guard showMarkLabels else { return }
        for labelPosition in Mark.LabelPosition.allCases {
            drawLabel(forMark: mark, labelPosition: labelPosition, segment: segment, context: context)
        }
    }

    func drawLabel(forMark mark: Mark, labelPosition: Mark.LabelPosition, segment: Segment, context: CGContext) {
        let label: String?
        switch labelPosition {
        case .left:
            label = mark.leftLabel
        case .proximal:
            label = mark.proximalLabel
        case .distal:
            label = mark.distalLabel
        }
        guard let label = label, !label.isEmpty else { return }
        let text = label
        var origin: CGPoint
        let size = text.size(withAttributes: measurementTextAttributes)
        // Center the origin.
        switch labelPosition {
        case .left:
            origin = segment.midpoint
            origin = CGPoint(x: origin.x - labelOffset - size.width, y: origin.y - size.height / 2)
        case .proximal:
            origin = segment.proximal
            origin = CGPoint(x: origin.x - size.width / 2, y: origin.y - size.height - labelOffset)
        case .distal:
            origin = segment.distal
            origin = CGPoint(x: origin.x - size.width / 2, y: origin.y + size.height - labelOffset)
        }
        let textRect = CGRect(origin: origin, size: size)
        if textRect.minX > leftMargin {
            text.draw(in: textRect, withAttributes: measurementTextAttributes)
            context.strokePath()
        }
    }

    func drawPeriods(region: Region, context: CGContext) {
        guard let calibration = calibration, calibration.isCalibrated else { return }
        guard showPeriods else { return }
        let periodHeight: CGFloat = 20.0
        for mark in region.marks {
            let numPeriods = numPeriodsFit(forMark: mark, inRegion: region, withHeight: periodHeight)
            var startY: CGFloat
            switch periodPosition {
            case .top:
                startY = region.proximalBoundaryY
            case .bottom:
                startY = region.distalBoundaryY - CGFloat(numPeriods) * periodHeight
            }
            mark.periods[0..<numPeriods].forEach {
                drawPeriod(period: $0, forMark: mark, regionMarks: region.marks, startY: startY, context: context)
                startY += periodHeight
            }
        }
    }

    private func numPeriodsFit(forMark mark: Mark, inRegion region: Region, withHeight height: CGFloat) -> Int {
        let regionHeight = region.height
        let num = Int(regionHeight / height)
        return min(num, mark.periods.count)
    }

    func drawPeriod(period: Period, forMark mark: Mark, regionMarks: [Mark], startY: CGFloat, context: CGContext) {
        let calFactor = calibration!.currentCalFactor
        let start = mark.earliestPoint.x
        let duration = regionValueFromCalibratedValue(period.duration, usingCalFactor:  calFactor)
        var periodEnd = start + duration

        let resetPeriods = true

        if resetPeriods {
            for m in regionMarks {
                if m.earliestPoint.x > mark.earliestPoint.x && m.earliestPoint.x < periodEnd {
                    periodEnd = m.earliestPoint.x
                }
            }
        }

        let beginning = transformToScaledViewPositionX(regionPositionX: start)
        let end = transformToScaledViewPositionX(regionPositionX: periodEnd)

        var width = end - beginning
        var adjustedStartX = beginning
        // EXAMPLE: let impinging marks show through
        // TODO: is this option worth it?  Maybe just never overlap marks
        if !periodOverlapMark {
            width = width - markLineWidth
            // Lines straddle the path, so divide in half to make fully visible
            adjustedStartX = adjustedStartX + markLineWidth / 2.0 // make sure mark line is visible if it is vertical
        }

        if leftMargin > beginning {
            adjustedStartX = max(beginning, leftMargin)
            width = width - (leftMargin - beginning)
        }
        if adjustedStartX + width < leftMargin {
            return
        }
        // FIXME: Height should be a constant.
        let height = 20.0
        let rect = CGRect(x: adjustedStartX, y: startY, width: width, height: height)
        context.addRect(rect)
        context.setFillColor(period.color.cgColor)
        // Cludgy get rid of border.  Do we want to have a border?
        context.setLineWidth(0)
        context.setAlpha(periodTransparency)
        context.drawPath(using: .fillStroke)
        context.setLineWidth(1.0)
        context.strokePath()
        let text = period.name
        // FIXME: should save original alpha and restore it...
        context.setAlpha(1.0)
        // TODO: determine if text is bigger than rectangle width, and if so, draw text next to rectangle.
        // Or, don't draw text...
        // TODO: preference for left vs center justification, below uses left
        // Adjust rectangle so that text is not stuck against the left side of period rect.
        switch periodTextJustification {
        case .left:
            let textRect = CGRect(x: adjustedStartX + 5, y: startY, width: width - 5, height: height)
            text.draw(in: textRect, withAttributes: leftJustifiedMeasurementTextAttributes)
        case .center:
            text.draw(in: rect, withAttributes: measurementTextAttributes)
        }
    }

    func conductionTime(fromSegment segment: Segment) -> Double {
        guard let calibration = calibration else { return 0 }
        return Double(abs(segment.proximal.x - segment.distal.x) * calibration.currentCalFactor)
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
        if rightAngleBlockMarker {
            drawRightAngleBlock(context: context, mark: mark, segment: segment)
            return
        }
        let blockLength: CGFloat = 20
        let blockSeparation: CGFloat = 5
        switch mark.blockSite {
        case .none:
            return
        case .distal:
            context.move(to: normalizePoint(CGPoint(x: segment.distal.x - blockLength / 2, y: segment.distal.y)))
            context.addLine(to: CGPoint(x: segment.distal.x + blockLength / 2, y: segment.distal.y))
            if doubleLineBlockMarker {
                context.move(to: normalizePoint(CGPoint(x: segment.distal.x - blockLength / 2, y: segment.distal.y + blockSeparation)))
                context.addLine(to: CGPoint(x: segment.distal.x + blockLength / 2, y: segment.distal.y + blockSeparation))
            }
        case .proximal:
            context.move(to: normalizePoint(CGPoint(x: segment.proximal.x - blockLength / 2, y: segment.proximal.y)))
            context.addLine(to: CGPoint(x: segment.proximal.x + blockLength / 2, y: segment.proximal.y))
            if doubleLineBlockMarker {
                context.move(to: normalizePoint(CGPoint(x: segment.proximal.x - blockLength / 2, y: segment.proximal.y - blockSeparation)))
                context.addLine(to: CGPoint(x: segment.proximal.x + blockLength / 2, y: segment.proximal.y - blockSeparation))
            }
        case .auto, .random:
            fatalError("Block site set to auto or random.")
        }
        context.strokePath()
    }

    func drawRightAngleBlock(context: CGContext, mark: Mark, segment: Segment) {
        // By using drawArrowHead, this is equivalent to a 20 point normal block marker line.
        let blockLength: CGFloat = 10
        let blockSeparation: CGFloat = 5
        let rightAngle = Double.pi / 2.0
        var segmentStart: CGPoint
        var segmentEnd: CGPoint
        switch mark.blockSite {
        case .none:
            return
        case .distal:
            segmentStart = segment.proximal
            segmentEnd = segment.distal
        case .proximal:
            segmentStart = segment.distal
            segmentEnd = segment.proximal
        case .auto, .random:
            fatalError("Block site set to auto or random.")
        }
        drawArrowHead(context: context, start: segmentStart, end: segmentEnd, pointerLineLength: blockLength, arrowAngle: rightAngle)
        if doubleLineBlockMarker {
            drawArrowHead(context: context, start: segmentStart, end: segmentEnd, pointerLineLength: blockLength, arrowAngle: rightAngle, offset: blockSeparation)
        }
    }

    private func normalizeX(_ x: CGFloat) -> CGFloat {
        return max(leftMargin, x)
    }

    private func normalizePoint(_ p: CGPoint) -> CGPoint {
        return CGPoint(x: max(leftMargin, p.x), y: p.y)
    }

    func drawImpulseOrigin(context: CGContext, mark: Mark, segment: Segment) {
        guard showImpulseOrigin else { return }
        var radius: CGFloat = 5
        if impulseOriginLarge {
            radius = 10
        }
        var separation: CGFloat = 5 + radius
        if impulseOriginContiguous {
            separation = radius / 2.0
        }
        switch mark.impulseOriginSite {
        case .none:
            return
        case .distal:
            if segment.distal.x < leftMargin { return }
            drawFilledCircle(context: context, position: CGPoint(x: segment.distal.x - radius / 2, y: segment.distal.y + separation - radius), radius: radius)
        case .proximal:
            if segment.proximal.x < leftMargin { return }
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
        drawRegionLabel(rect: rect, region: region, context: context)
        drawRegionArea(context: context, rect: rect, region: region)
        if !marksAreHidden {
            drawMarks(region: region, context: context, rect: rect)
            drawIntervals(region: region, context: context)
            drawPeriods(region: region, context: context)
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
        undoablyDeleteMarks(marks: selectedMarks)
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
                undoablyUnlink(mark: mark)
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
                undoablyUnlink(mark: mark)
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
        currentDocument?.undoManager.beginUndoGrouping()
        selectedMarks.forEach { mark in undoablyUnlink(mark: mark) }
        currentDocument?.undoManager.endUndoGrouping()
    }

    func snapSelectedMarks() {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        currentDocument?.undoManager.beginUndoGrouping()
        selectedMarks.forEach { mark in
            let nearbyMarkIDs = self.getNearbyMarkIDs(mark: mark)
            self.snapToNearbyMarks(mark: mark, nearbyMarks: nearbyMarkIDs)
            linkNearbyMarks(mark: mark, nearbyMarks: nearbyMarkIDs)
            assessBlockAndImpulseOrigin(mark: mark)
        }
        updateMarkersAndLadderIntervals()
        currentDocument?.undoManager.endUndoGrouping()
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
        var segments: [Segment] = []
        unlinkAllMarks()
        selectedMarks.forEach { mark in
            let segment: Segment
            switch endpoint {
            case .proximal:
                segment = Segment(proximal: mark.segment.proximal, distal: CGPoint(x: mark.segment.proximal.x, y: mark.segment.distal.y))
            case .distal:
                segment = Segment(proximal: CGPoint(x: mark.segment.distal.x, y: mark.segment.proximal.y), distal: mark.segment.distal)
            case .none, .auto, .random:
                fatalError("Endpoint.none, .random, or .auto inappopriately passed to straightenToEndPoint()")
            }
            segments.append((segment))
        }
        setSegments(segments: segments, forMarks: selectedMarks)
        relinkAllMarks()
        currentDocument?.undoManager.endUndoGrouping()
    }

    func adjustY(_ value: CGFloat, endpoint: Mark.Endpoint, adjustment: Adjustment) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        var segments: [Segment] = []
        selectedMarks.forEach { mark in
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
            segments.append(segment)
        }
        setSegments(segments: segments, forMarks: selectedMarks)
        updateMarkersAndLadderIntervals()
    }

    func meanCL() throws -> CGFloat {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        // Is calibration ever nil??
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
        // TODO: test
//        if !zone.isVisible && regions.count < 1 {
//            throw LadderError.noRegionSelected
//        }
    }

    func checkForRepeatCL() throws {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        if selectedMarks.count != 2 {
            throw LadderError.requireTwoMarks
        }
        if ladder.marksAreInDifferentRegions(selectedMarks) {
            throw LadderError.marksInDifferentRegions
        }
        if ladder.difference(selectedMarks[0], selectedMarks[1]) < minRepeatCLInterval {
            throw LadderError.intervalTooShort
        }
    }

    /// Check selected marks to see if periods are editable
    ///
    /// For periods to be editable, it is necessary that
    ///  1. At least one mark is selected
    ///  2. All marks are in the same region
    ///  3. All marks have the same periods, or no periods.
    ///  Throws specific error if any of the above conditions is true.
    func checkForPeriods() throws {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        selectedMarksPeriods = []
        if selectedMarks.count == 1 { // 1 mark can always be edited
            selectedMarksPeriods = selectedMarks[0].periods
            return
        }
        if selectedMarks.count < 1 {
            throw LadderError.noMarks
        }
        if ladder.marksAreInDifferentRegions(selectedMarks) {
            throw LadderError.marksInDifferentRegions
        }
        // At this point, at least 2 marks are in selectedMarks.
        let periods = selectedMarks[0].periods
        for mark in selectedMarks {
            if mark.periods.count == 0 { // allow mix of no periods and periods
                continue
            }
            if mark.periods != periods { // but don't allow disimilar periods
                throw LadderError.periodsDontMatch
            }
        }
        // If we reach here without throwing, all marks have the same periods (or none).  Thus...
        selectedMarksPeriods = periods
    }

    func applyPeriods(_ periods: [Period]) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        applyPeriods(periods, toMarks: selectedMarks)
    }

    private func applyPeriods(_ periods: [Period], toMarks marks: [Mark]) {
        for mark in marks {
            undoablySetMarkPeriods(mark: mark, periods: periods)
        }
        refresh()
        // TODO: need to restore select toolbar
    }

    func undoablySetMarkPeriods(mark: Mark, periods: [Period]) {
        let originalPeriods = mark.periods
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetMarkPeriods(mark: mark, periods: originalPeriods)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        mark.periods = periods
    }

    /// Repeats CL and creates new marks.  If marks aren't parallel, uses minimum CL between prox and distal endpoints.
    ///
    /// Exactly two marks must be selected, both in the same region.  Marks don't have to be parallel, but if they are not,
    /// the shorter cyle length is used for the repeat.
    /// - Parameter time: repeat before or after as a `TemporalRelation`
    func performRepeatCL(time: TemporalRelation) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        guard selectedMarks.count == 2 else { return }
        currentDocument?.undoManager.beginUndoGrouping()

        func repeatCLAfter() {
            var nextSegment = secondMark.segment
            var newMarks: [Mark] = []
            while segmentPlusDiffWillBeInBounds(segment: nextSegment, diff: (CL, CL)) {
                nextSegment.proximal.x += CL
                nextSegment.distal.x += CL
                let newMark = ladder.addMark(fromSegment: nextSegment, toRegion: region)
                newMark.mode = .selected
                undoablySetMarkStyle(mark: newMark, style: secondMark.style)
                newMarks.append(newMark)
            }
            undoablyAddMarks(marks: newMarks)
            linkMarks(newMarks)
            updateMarkersAndRegionIntervals(region)
            assessBlockAndImpulseOriginOfMarks(newMarks)
        }

        func repeatCLBefore() {
            var nextSegment = firstMark.segment
            var newMarks: [Mark] = []
            while segmentPlusDiffWillBeInBounds(segment: nextSegment, diff: (-CL, -CL)) {
                nextSegment.proximal.x -= CL
                nextSegment.distal.x -= CL
                let newMark = ladder.addMark(fromSegment: nextSegment, toRegion: region)
                newMark.mode = .selected
                undoablySetMarkStyle(mark: newMark, style: firstMark.style)
                newMarks.append(newMark)
            }
            undoablyAddMarks(marks: newMarks)
            linkMarks(newMarks)
            updateMarkersAndRegionIntervals(region)
            assessBlockAndImpulseOriginOfMarks(newMarks)
        }

        let mark1 = selectedMarks[0]
        let mark2 = selectedMarks[1]
        let region = ladder.region(ofMark: mark1)
        let proxCL = abs(mark2.segment.proximal.x - mark1.segment.proximal.x)
        let distalCL = abs(mark2.segment.distal.x - mark1.segment.distal.x)
        let CL = min(proxCL, distalCL)
        let secondMark = mark2 > mark1 ? mark2 : mark1
        let firstMark = mark2 < mark1 ? mark2 : mark1
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

        @discardableResult
        func applyCL(start: CGFloat, end: CGFloat, region: Region?, deleteExtantMarks: Bool = false) -> [Mark] {
            guard let region = region else { return [] }
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
            var newMarks: [Mark] = []
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
                newMarks.append(mark)
            }
            if zone.isVisible {
                selectInZone()
            } else {
                ladder.setMarksWithMode(.selected, inRegion: region)
            }
            undoablyAddMarks(marks: newMarks)
            return newMarks

        }

        unlinkAllMarks()
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
        relinkAllMarks()
        setNeedsDisplay()
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
        var marksForDeletion: [Mark] = []
        for mark in region.marks {
            if (mark.segment.proximal.x > start || mark.segment.distal.x > start)
                && (mark.segment.proximal.x < end || mark.segment.distal.x < end) {
                marksForDeletion.append(mark)
            }
        }
        undoablyDeleteMarks(marks: marksForDeletion)

    }

    func checkForRepeatPattern() throws {
        guard patternMarks.count > 1 else { throw LadderError.tooFewMarks }
        guard patternMarks.count > 0 else { throw LadderError.noMarks }
    }

    func copyMarks() {
        copiedMarks = ladder.allMarksWithMode(.selected)
    }

    func setPatternMarks() {
        patternMarks = ladder.allMarksWithMode(.selected)
    }

    func repeatPattern(tapLocationInLadder: LocationInLadder, justOnce: Bool = false) {

        @discardableResult func duplicatePattern(joiningMark: Mark?, diff: (proximal: CGFloat, distal: CGFloat))  -> Mark? {
            guard let joiningMark = joiningMark else { return nil }
            var newJoiningMark: Mark?
            for m in patternMarks {
                var segment = m.segment
                m.mode = .normal
                segment.proximal.x += diff.proximal
                segment.distal.x += diff.distal
                let newMark = ladder.addMark(fromSegment: segment, toRegion: ladder.region(ofMark: m))
                undoablySetMarkStyle(mark: newMark, style: m.style)
                if m == joiningMark {
                    newJoiningMark = newMark
                }
                newMarks.append(newMark)
            }
            undoablyAddMarks(marks: newMarks)
            removeOverlappingMarks(with: newMarks)
            // we'll link and update with each duplication, as well as at beginning and end
            linkMarks(newMarks)
            updateMarkersAndLadderIntervals()
            assessBlockAndImpulseOriginOfMarks(newMarks)
            // do it again if you like
            patternMarks = newMarks
            ladder.setModeForMarks(mode: .selected, marks: patternMarks)
            newMarks = []
            return newJoiningMark
        }

        var newMarks: [Mark] = []
        do {
            guard patternMarks.count > 1 else {
                throw(LadderError.tooFewMarks)
            }
            guard let mark = tapLocationInLadder.mark else {
                throw(LadderError.didNotTapAMark)
            }
            let regionOfTappedMark = ladder.region(ofMark: mark)
            // find another mark earlier or later that is parallel
            let sameRegionMarks = patternMarks.filter { ladder.region(ofMark: $0) == regionOfTappedMark }
            guard sameRegionMarks.count > 1 else {
                throw LadderError.onlyOneSelectedMarkInRegion
            }
            let sortedSameRegionMarks = sameRegionMarks.sorted()
            guard sortedSameRegionMarks.first == mark || sortedSameRegionMarks.last == mark else {
                throw LadderError.markNotAtEitherEndOfSelection
            }
            // We don't need to unlink original pattern marks, just leave their links be.
            // Will just link the new ones.
            var otherMark: Mark
            // Note: unwrapped optionals, but they can't be nil per preceding code.
            if mark == sortedSameRegionMarks.last {
                otherMark = sortedSameRegionMarks.first!
            } else {
                otherMark = sortedSameRegionMarks.last!
            }
            guard Geometry.areParallel(mark.segment, otherMark.segment) else {
                throw LadderError.marksNotParallel
            }
            let diff: (proximal: CGFloat, distal: CGFloat) = (mark.segment.proximal.x - otherMark.segment.proximal.x, mark.segment.distal.x - otherMark.segment.distal.x)
            if justOnce {
                if roomForRepeatPattern(withDiff: diff) {
                    duplicatePattern(joiningMark: mark, diff: diff)
                }
            } else {
                var newJoiningMark = duplicatePattern(joiningMark: mark, diff: diff)
                while newJoiningMark != nil && roomForRepeatPattern(withDiff: diff) {
                    newJoiningMark = duplicatePattern(joiningMark: newJoiningMark, diff: diff)
                }
            }
        } catch {
            if let vc = findViewController() as? DiagramViewController {
                vc.showError(title: "Ladder Error", error: error)
            }
        }
    }

    func roomForRepeatPattern(withDiff diff: (proximal: CGFloat, distal: CGFloat)) -> Bool {
        for mark in patternMarks {
            if !segmentPlusDiffWillBeInBounds(segment: mark.segment, diff: diff) {
                return false
            }
        }
        return true
     }

    // Make sure at least a part of a mark will be inbounds and thus can be selected and manipulated.
    func segmentPlusDiffWillBeInBounds(segment: Segment, diff: (proximal: CGFloat, distal: CGFloat)) -> Bool {
        var inBounds = false
        let newSegment = Segment(proximal: CGPoint(x: segment.proximal.x + diff.proximal, y: segment.proximal.y), distal: CGPoint(x: segment.distal.x + diff.distal, y: segment.distal.y))
        inBounds = newSegment.latestPoint.x > 0  && newSegment.earliestPoint.x < viewMaxWidth
        return inBounds
    }

    func pasteMarks(tapLocationInLadder: LocationInLadder) {
        guard copiedMarks.count > 0 else { return }
        guard tapLocationInLadder.specificLocation == .region else { return }
        // get earlies mark.x of copied marks
        var earliestX: CGFloat = copiedMarks[0].earliestPoint.x
        for mark in copiedMarks {
            if mark.earliestPoint.x < earliestX {
                earliestX = mark.earliestPoint.x
            }
        }
        let regionPositionX = transformToRegionPositionX(scaledViewPositionX: tapLocationInLadder.unscaledPosition.x)
        let diff = earliestX - regionPositionX
        var newMarks: [Mark] = []
        for mark in copiedMarks {
            var segment = mark.segment
            segment.proximal.x -= diff
            segment.distal.x -= diff
            let newMark = ladder.addMark(fromSegment: segment, toRegion: ladder.region(ofMark: mark))
            undoablySetMarkStyle(mark: newMark, style: mark.style)
            // TODO: get periods if consistent periods in copied marks and copy periods
            //            newMark.style = mark.style
            newMarks.append(newMark)
        }
        undoablyAddMarks(marks: newMarks)
//        linkMarks(newMarks)
        updateMarkersAndLadderIntervals()
//        assessBlockAndImpulseOriginOfMarks(newMarks)
    }

    func adjustCL(cl: CGFloat) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        guard selectedMarks.count > 0 else { return }
        let region = ladder.region(ofMark: selectedMarks[0])
        var proxX = selectedMarks[0].segment.proximal.x
        var distalX = selectedMarks[0].segment.distal.x
        var segments: [Segment] = []
        segments.append(selectedMarks[0].segment)
        for i in 1..<selectedMarks.count {
            proxX += cl
            distalX += cl
            let newSegment = Segment(proximal: CGPoint(x: proxX, y: selectedMarks[i].segment.proximal.y), distal: CGPoint(x: distalX, y: selectedMarks[i].segment.distal.y))
            segments.append(newSegment)
        }
        setSegments(segments: segments, forMarks: selectedMarks)
        updateMarkersAndRegionIntervals(region)
    }

    func slantSelectedMarks(angle: CGFloat, endpoint: Mark.Endpoint) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        var segments: [Segment] = []
        selectedMarks.forEach { mark in
            segments.append(slantMark(angle: angle, mark: mark, endpoint: endpoint))
        }
        setSegments(segments: segments, forMarks: selectedMarks)
        updateMarkersAndLadderIntervals()
    }

    func slantMark(angle: CGFloat, mark: Mark, endpoint: Mark.Endpoint = .proximal) -> Segment {
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
        return transformToRegionSegment(scaledViewSegment: newSegment, region: region)
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
        // Don't test for minimum segment length here because then small segments can't be moved.
        let originalSegment = mark.segment
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.setSegment(segment: originalSegment, forMark: mark)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        mark.segment = segment
        updateMarkersAndRegionIntervals(ladder.region(ofMark: mark))
        assessBlockAndImpulseOriginOfMark(mark)
    }

    private func setSegments(segments: [Segment], forMarks marks: [Mark]) {
        let originalSegments = marks.map { $0.segment }
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.setSegments(segments: originalSegments, forMarks: marks)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        for i in 0..<marks.count {
            marks[i].segment = segments[i]
        }
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

    func undoablyAddRegion(_ region: Region, atIndex index: Int) {
        unlinkAllMarks()
        let originalRegion = region
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablyRemoveRegion(originalRegion)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        ladder.regions.insert(region, at: index)
        initializeRegions()
        ladder.reindexMarks()
        relinkAllMarks()
        setNeedsDisplay()
    }

    func undoablyRemoveRegion(_ region: Region) {
        assert(ladder.regions.count > Ladder.minRegionCount)
        unlinkAllMarks()
        let originalRegion = region
        let index = ladder.index(ofRegion: originalRegion)!
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablyAddRegion(region, atIndex: index)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        ladder.removeRegion(region)
        initializeRegions()
        ladder.reindexMarks()
        relinkAllMarks()
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
        currentDocument?.undoManager.beginUndoGrouping()
        undoablyAddRegion(newRegion, atIndex: selectedIndex)
        currentDocument?.undoManager.endUndoGrouping()
    }

    func removeRegion() {
        // Can't remove last region
        guard ladder.regions.count > Ladder.minRegionCount else { return }
        guard let selectedRegion = selectedLabelRegion() else { return }
        currentDocument?.undoManager.beginUndoGrouping()
        undoablyRemoveRegion(selectedRegion)
        currentDocument?.undoManager.endUndoGrouping()
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
        // Do we really need to swap here?
        swapEndpointsIfNeeded(mark: attachedMark)
        let newNearbyMarks = getNearbyMarkIDs(mark: attachedMark)
        snapToNearbyMarks(mark: attachedMark, nearbyMarks: newNearbyMarks)
        linkNearbyMarks(mark: attachedMark, nearbyMarks: newNearbyMarks)
    }

    func assessBlockAndImpulseOriginAttachedMark() {
        if let attachedMark = ladder.attachedMark {
            assessBlockAndImpulseOriginOfMark(attachedMark)
        }
    }

    func reregisterAllMarks() {
        ladder.reregisterAllMarks()
    }

    func linkConnectedMarks() {
        guard snapMarks else { return }
        guard ladder.connectedMarks.count == 3 else { return }
        let nearbyMarks0 = getNearbyMarkIDs(mark: ladder.connectedMarks[0])
        let nearbyMarks2 = getNearbyMarkIDs(mark: ladder.connectedMarks[2])
        linkNearbyMarks(mark: ladder.connectedMarks[0], nearbyMarks: nearbyMarks0)
        linkNearbyMarks(mark: ladder.connectedMarks[2], nearbyMarks: nearbyMarks2)
    }

    func getNearbyMarkIDs(mark: Mark) -> LinkedMarkIDs {
        os_log("getNearbyMarkIDs(mark:) - LadderView", log: .default, type: .default)

        guard snapMarks else { return LinkedMarkIDs() }
        let minimum: CGFloat = nearbyMarkAccuracy / scale
        let nearbyMarkIDs = getNearbyMarkIDs(mark: mark, nearbyDistance: minimum)
        return nearbyMarkIDs
    }


    func highlightNearbyMarks(_ mark: Mark?) {
//        os_log("highlightNearbyMarks(mark:) - LadderView", log: .default, type: .default)

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
        var segment = mark.segment
        if nearbyMarks.proximal.count > 0 {
            // Only need to snap to one proximal and distal mark.  There are weird situations
            // where the adjacent region marks are close enough together that more than
            // one is available to snap to (e.g. AFB), but we will ignore that possibility.
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

    /// Relink all marks, as a side effect it assesses block and impulse origin
    func relinkAllMarks() {
        currentDocument?.undoManager?.registerUndo(withTarget: self) { target in
            target.unlinkAllMarks()
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        linkMarks(ladder.allMarks())
        assessBlockAndImpulseOriginOfMarks(ladder.allMarks())
        setNeedsDisplay()
    }

    func linkMarks(_ marks: [Mark]) {
        for mark in marks {
            let nearbyMarks = self.getNearbyMarkIDs(mark: mark)
            self.linkNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
        }
        self.setNeedsDisplay()
    }

    func linkNearbyMarks(mark: Mark, nearbyMarks: LinkedMarkIDs) {
        os_log("linkNearbyMarks(mark:nearbyMarks:) - LadderView", log: .default, type: .default)

        guard snapMarks else { return }

        let filteredProximal = nearbyMarks.proximal.subtracting(mark.linkedMarkIDs.proximal)
        let filteredMiddle = nearbyMarks.middle.subtracting(mark.linkedMarkIDs.middle)
        let filteredDistal = nearbyMarks.distal.subtracting(mark.linkedMarkIDs.distal)
        let filteredNearbyMarks = LinkedMarkIDs(proximal: filteredProximal, middle: filteredMiddle, distal: filteredDistal)
        currentDocument?.undoManager?.registerUndo(withTarget: self) { target in
            target.unlinkNearbyMarks(mark: mark, nearbyMarks: filteredNearbyMarks)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        // Need to link the new marks
        for proximalMarkID in filteredNearbyMarks.proximal {
            mark.linkedMarkIDs.proximal.insert(proximalMarkID)
            let proximalMark = ladder.lookup(id: proximalMarkID)
            proximalMark?.linkedMarkIDs.distal.insert(mark.id)
        }
        for middleMarkID in filteredNearbyMarks.middle {
            mark.linkedMarkIDs.middle.insert(middleMarkID)
            let middleMark = ladder.lookup(id: middleMarkID)
            middleMark?.linkedMarkIDs.middle.insert(mark.id)
        }
        for distalMarkID in filteredNearbyMarks.distal {
            mark.linkedMarkIDs.distal.insert(distalMarkID)
            let distalMark = ladder.lookup(id: distalMarkID)
            distalMark?.linkedMarkIDs.proximal.insert(mark.id)
        }
    }

    /// Undoably unlink linked marks to mark
    ///
    /// Crucially, this method reassesses impulse origin (and block) of each unlinked mark, which allows for undo and redo to work properly.
    /// - Parameters:
    ///   - mark: mark to undergo unlinking
    ///   - nearbyMarks: marks that will be unlinked from the mark
    func unlinkNearbyMarks(mark: Mark, nearbyMarks: LinkedMarkIDs) {
        guard snapMarks else { return }
        currentDocument?.undoManager?.registerUndo(withTarget: self) { target in
            target.linkNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        for proximalMarkID in nearbyMarks.proximal {
            mark.linkedMarkIDs.proximal.remove(proximalMarkID)
            let proximalMark = ladder.lookup(id: proximalMarkID)
            proximalMark?.linkedMarkIDs.distal.remove(mark.id)
            assessBlockAndImpulseOrigin(mark: proximalMark)
        }
        for middleMarkID in nearbyMarks.middle {
            mark.linkedMarkIDs.middle.remove(middleMarkID)
            let middleMark = ladder.lookup(id: middleMarkID)
            middleMark?.linkedMarkIDs.middle.remove(mark.id)
            assessBlockAndImpulseOrigin(mark: middleMark)
        }
        for distalMarkID in nearbyMarks.distal {
            mark.linkedMarkIDs.distal.remove(distalMarkID)
            let distalMark = ladder.lookup(id: distalMarkID)
            distalMark?.linkedMarkIDs.proximal.remove(mark.id)
            assessBlockAndImpulseOrigin(mark: distalMark)
        }
    }

    func unlinkAllMarks() {
        currentDocument?.undoManager?.registerUndo(withTarget: self) { target in
            target.relinkAllMarks()
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        let marks = ladder.allMarks()
        for mark in marks {
            undoablyUnlink(mark: mark)
        }
        assessBlockAndImpulseOriginOfMarks(ladder.allMarks())
        setNeedsDisplay()
    }

    func undoablyUnlink(mark: Mark) {
        let linkedMarkIDs = mark.linkedMarkIDs
        let originalMark = mark
        currentDocument?.undoManager?.registerUndo(withTarget: self) { target in
            target.undoablyLink(mark: originalMark, linkedMarkIDs: linkedMarkIDs)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        unlink(mark: mark)
        updateMarkersAndRegionIntervals(ladder.region(ofMark: mark))
        assessBlockAndImpulseOrigin(mark: mark)
        setNeedsDisplay()
    }

    /// Remove all links to a mark, and remove all backlinks to the mark
    /// - Parameter mark: `Mark` to be unlinked
    func unlink(mark: Mark) {
        // First remove all backlinks to this mark.
        for m in ladder.allMarks() {
            m.linkedMarkIDs.remove(id: mark.id)
        }
        // Now clear all links of this mark.
        mark.linkedMarkIDs = LinkedMarkIDs()
    }

    func undoablyLink(mark: Mark, linkedMarkIDs: LinkedMarkIDs) {
        let originalMark = mark
        currentDocument?.undoManager?.registerUndo(withTarget: self) { target in
            target.undoablyUnlink(mark: originalMark)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        let linkedMarkIDs = getNearbyMarkIDs(mark: mark)
        let linkedMarks = ladder.getLinkedMarksFromLinkedMarkIDs(linkedMarkIDs)
        for linkedMark in linkedMarks.allMarks {
            linkMarks(mark, linkedMark)
        }
        updateMarkersAndRegionIntervals(ladder.region(ofMark: mark))
        assessBlockAndImpulseOrigin(mark: mark)
        setNeedsDisplay()
    }

    private func linkMarks(_ m1: Mark, _ m2: Mark) {
        let regionRelation = Ladder.regionRelationBetweenMarks(mark: m1, otherMark: m2)
        switch regionRelation {
        case .distant:
            return
        case .before:
            m1.linkedMarkIDs.proximal.insert(m2.id)
            m2.linkedMarkIDs.distal.insert(m1.id)
        case .after:
            m1.linkedMarkIDs.distal.insert(m2.id)
            m2.linkedMarkIDs.proximal.insert(m1.id)
        case .same:
            m1.linkedMarkIDs.middle.insert(m2.id)
            m2.linkedMarkIDs.middle.insert(m1.id)
        }
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

enum TextJustification: Int, Codable {
    case left
    case center
}

enum Adjustment {
    case adjust
    case trim
}


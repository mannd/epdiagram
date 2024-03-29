//
//  CursorView.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import OSLog

final class CursorView: ScaledView {
    private let rightMargin: CGFloat = 5 // unused?
    private let alphaValue: CGFloat = 0.8
    private let accuracy: CGFloat = 20 // How close a tap has to be to a cursor in unscaled view to register.

    var calibration: Calibration?

    var lineWidth: CGFloat = CGFloat(Preferences.cursorLineWidth)
    var caliperLineWidth: CGFloat {
        get { caliper.lineWidth }
        set { caliper.lineWidth = newValue }
    }
    var markerLineWidth: CGFloat = CGFloat(Preferences.markLineWidth)

    var cursorColor: UIColor = Preferences.defaultCursorColor
    var caliperColor: UIColor = Preferences.defaultCaliperColor
    var markerColor: UIColor = Preferences.defaultMarkerColor

    // For testing
    var cursorPositionX: CGFloat { cursor.positionX }

    private var cursor: Cursor = Cursor()
    private var rawCursorHeight: CGFloat?

    private var caliper: Caliper = Caliper()
    private var draggedComponent: Caliper.Component?

    private var markerPositions: [CGPoint] = []
    var showMarkers = false {
        didSet {
            if showMarkers {
                ladderViewDelegate.updateMarkers()
            }
        }
    }

    var calFactor: CGFloat {
        get {
            return calibration?.originalCalFactor ?? 1.0
        }
        set(value) {
            guard let calibration = calibration else { return }
            calibration.originalCalFactor = value
        }
    }

    var leftMargin: CGFloat = 0
    var mode: Mode = .normal
    var marksAreHidden: Bool = false
    
    var allowTaps = true // set false to prevent taps from making marks
    var cursorEndPointY: CGFloat = 0

    var imageIsLocked = false

    weak var ladderViewDelegate: LadderViewDelegate! // Note IUO.
    weak var currentDocument: DiagramDocument?

    // MARK: - init

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // used for unit testing
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    deinit {
        print("*****CursorView deinit()******")
    }

    private func setupView() {
        self.isOpaque = false // CursorView is mostly transparent, so let iOS know.
        self.layer.masksToBounds = true // Draw a border around the view.
        self.layer.borderColor = UIColor.label.cgColor
        self.layer.borderWidth = 1
        self.cursor.visible = false

        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTapRecognizer)

        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        self.addGestureRecognizer(doubleTapRecognizer)

        let draggingPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handleDrag(gesture:)))
        self.addGestureRecognizer(draggingPanRecognizer)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress))
        self.addGestureRecognizer(longPressRecognizer)
    }

    // MARK: - draw

    override func draw(_ rect: CGRect) {
        if imageIsLocked {
            showLockImageWarning(rect: rect)
        }
        if showMarkers {
            drawMarkers()
        }
        switch mode {
        case .calibrate:
            drawCaliper(rect)
        case .normal:
            drawCursor(rect)
        case .select:
            break
        default:
            break
        }

    }

    func drawCursor(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            guard cursor.visible else { return }

            let position = scale * cursor.positionX - offsetX // inlined, for efficiency
            let cursorDefaultHeight = ladderViewDelegate.getTopOfLadder(view: self)
            let defaultHeight = cursorDefaultHeight
            let height = (position <= leftMargin) ? defaultHeight : cursor.markIntersectionPositionY
            let endPoint = CGPoint(x: position, y: height)

            context.setStrokeColor(cursorColor.cgColor)
            context.setLineWidth(lineWidth)
            context.setAlpha(alphaValue)
            context.move(to: CGPoint(x: position, y: 0))
            context.addLine(to: endPoint)
            context.strokePath()
            if position > leftMargin {
                drawCircle(context: context, center: endPoint, radius: Cursor.intersectionRadius)
            }
            if cursor.movement == .omnidirectional {
                drawCircle(context: context, center: CGPoint(x: position, y: cursor.positionOmniCircleY), radius: Cursor.omniCircleRadius)
            }
        }
    }

    func drawCaliper(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(caliperColor.cgColor)
            context.setLineWidth(caliperLineWidth)
            context.setAlpha(alphaValue)
            context.move(to: CGPoint(x: caliper.bar1Position, y: 0))
            context.addLine(to: CGPoint(x: caliper.bar1Position, y: caliperMaxY))
            context.move(to: CGPoint(x: caliper.bar2Position, y: 0))
            context.addLine(to: CGPoint(x: caliper.bar2Position, y: caliperMaxY))
            context.move(to: CGPoint(x: caliper.bar1Position, y: caliper.crossbarPosition))
            context.addLine(to: CGPoint(x: caliper.bar2Position, y: caliper.crossbarPosition))
            let text = caliper.text
            let caliperValue = String(format: "%.2f", caliper.value)
            let measureText = "\(caliperValue) points"
            var attributes = [NSAttributedString.Key: Any]()
            let textFont = UIFont(name: "Helvetica Neue Medium", size: 16.0) ?? UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium)
            let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            attributes = [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.foregroundColor: caliperColor
            ]
            let size = text.size(withAttributes: attributes)
            let measureSize = measureText.size(withAttributes: attributes)
            let maxWidth = max(size.width, measureSize.width)
            if maxWidth < caliper.value {
                let textRect = CGRect(origin: CGPoint(x: caliper.bar1Position + (caliper.value - size.width) / 2, y: caliper.crossbarPosition), size: size)
                text.draw(in: textRect, withAttributes: attributes)
                let measureTextRect = CGRect(origin: CGPoint(x: caliper.bar1Position + (caliper.value - measureSize.width) / 2, y: caliper.crossbarPosition - measureSize.height), size: measureSize)
                measureText.draw(in: measureTextRect, withAttributes: attributes)
            }
            context.strokePath()
        }
    }

    func showLockImageWarning(rect: CGRect) {
        let text = L("IMAGE LOCK")
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0),
            .foregroundColor: UIColor.white, .backgroundColor: UIColor.systemRed
        ]
        let lockRect = CGRect(x: rect.origin.x + 5, y: rect.origin.y + 5, width: rect.size.width, height: rect.size.height)
        text.draw(in: lockRect, withAttributes: attributes)
    }

    /// Sets the y coordinate (== height) of the cursor in cursor view coordinates,
    /// based on the mark anchor position in ladder view coordinates
    ///
    /// Is a noop for `nil` value of anchorPositionY, and if there is no attached anchor.
    /// When resizing the ladder view, anchor position is miscalculated on slanted marks.  Rather than recalculate the cursor height it
    /// is easier under these circumstances to hide the cursor when resizing views.
    /// - Parameter anchorPositionY: ladder view mark anchor y coordinate  as `CGFloat?`
    func setCursorHeight(anchorPositionY: CGFloat? = nil) {
        guard let anchor = attachedMarkAnchor() else { return }
        if let anchorPositionY = anchorPositionY {
            let positionY = ladderViewDelegate.getPositionYInView(positionY: anchorPositionY, view: self)
            cursor.markIntersectionPositionY = positionY
        }
        else {
            let cursorHeight = getCursorHeight(anchor: anchor)
            cursor.markIntersectionPositionY = cursorHeight ?? 0
        }
    }

    // Add tiny circle around intersection of cursor and mark.
    /// Draws a circle using center and radius parameters
    /// - Parameters:
    ///   - context: graphics `CGContext`
    ///   - center: center of circle as `CGPoint`
    ///   - radius: radius of circle as `CGFloat`
    private func drawCircle(context: CGContext, center: CGPoint, radius: CGFloat) {
        // Make the circle a little more prominent.
        context.setLineWidth(lineWidth + 1)
        context.addArc(center: center, radius: radius, startAngle: 0.0, endAngle: .pi * 2.0, clockwise: true)
        context.strokePath()
        // Put the line width back the way we found it.
        context.setLineWidth(lineWidth)
    }

    /// Get the anchor of the attached mark
    /// - Returns: `Anchor` of the attached mark, `nil` if no mark is attached
    func attachedMarkAnchor() -> Anchor? {
        return ladderViewDelegate.attachedMarkAnchor()
    }

    private func anchorPositionY(_ anchor: Anchor, _ ladderViewDelegate: LadderViewDelegate) -> CGFloat? {
        let anchorY: CGFloat?
        switch anchor {
        case .proximal:
            anchorY = ladderViewDelegate.getRegionProximalBoundary(view: self)
        case .middle:
            anchorY = ladderViewDelegate.getRegionMidPoint(view: self)
        case .distal:
            anchorY = ladderViewDelegate.getRegionDistalBoundary(view: self)
        }
        return anchorY
    }

    private func getCursorHeight(anchor: Anchor) -> CGFloat? {
        return anchorPositionY(anchor, ladderViewDelegate)
    }

    // MARK: - touches

    // This function passes touch events to the views below if the point is not
    // near the cursor.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if mode == .calibrate {
            return caliper.isNearCaliper(point: point, accuracy: accuracy)
        }
        guard cursor.visible else { return false }
        if isNearCursor(positionX: point.x, accuracy: accuracy) && point.y < ladderViewDelegate.getRegionProximalBoundary(view: self) {
            return true
        }
        return false
    }

    func isNearCursor(positionX: CGFloat, accuracy: CGFloat) -> Bool {
        return positionX < transformToScaledViewPositionX(regionPositionX: cursor.positionX) + accuracy && positionX > transformToScaledViewPositionX(regionPositionX: cursor.positionX) - accuracy
    }

    @objc func singleTap(tap: UITapGestureRecognizer) {
        os_log("singleTap(tap:) - CursorView", log: OSLog.touches, type: .info)
        guard !marksAreHidden else { return }
        guard allowTaps else { return } // Taps do nothing when ladder is locked.
        switch mode {
        case .normal:
            ladderViewDelegate.toggleAttachedMarkAnchor()
            ladderViewDelegate.refresh()
            setNeedsDisplay()
        default:
            break
        }
    }
    
    @objc func doubleTap(tap: UITapGestureRecognizer) {
        os_log("doubleTap(tap:) - CursorView", log: OSLog.touches, type: .info)
        guard !marksAreHidden else { return }
        guard allowTaps else { return } // Taps do nothing when ladder is locked.
        switch mode {
        case .normal:
            ladderViewDelegate.deleteAttachedMark()
            ladderViewDelegate.refresh()
            setNeedsDisplay()
        default:
            break}
    }

    @objc func handleDrag(gesture: UIPanGestureRecognizer) {
        guard !marksAreHidden else { return }
        switch mode {
        case .calibrate:
            calibrateModeDrag(gesture)
        case .normal:
            normalModeDrag(gesture)
        default:
            break
        }
    }

    func normalModeDrag(_ gesture: UIPanGestureRecognizer) {
        guard let attachedMarkAnchorPosition = ladderViewDelegate.getAttachedMarkScaledAnchorPosition() else { return }
        if gesture.state == .began {
            currentDocument?.undoManager?.beginUndoGrouping()
            cursorEndPointY = attachedMarkAnchorPosition.y
            ladderViewDelegate.moveAttachedMark(position: attachedMarkAnchorPosition) // This has to be here for undo to work.
        }
        if gesture.state == .changed {
            let delta = gesture.translation(in: self)
            cursorMove(delta: delta)
            cursorEndPointY += delta.y
            ladderViewDelegate.moveAttachedMark(position: CGPoint(x: transformToScaledViewPositionX(regionPositionX: cursor.positionX), y: cursorEndPointY))
            gesture.setTranslation(CGPoint(x: 0,y: 0), in: self)
        }
        if gesture.state == .ended {
            ladderViewDelegate.linkMarksNearbyAttachedMark()
            currentDocument?.undoManager?.endUndoGrouping()
            ladderViewDelegate.assessBlockAndImpulseOriginAttachedMark()
            cursorEndPointY = 0
        }
        ladderViewDelegate.refresh()
        setNeedsDisplay()
    }

    private func calibrateModeDrag(_ gesture: UIPanGestureRecognizer) {
        // No undo for calibration.
        if gesture.state == .began {
            draggedComponent = caliper.isNearCaliperComponent(point: gesture.location(in: self), accuracy: accuracy)
        }
        else if gesture.state == .changed {
            guard let draggedComponent = draggedComponent else { return }
            let delta = gesture.translation(in: self)
            caliper.move(delta: delta, component: draggedComponent)
            gesture.setTranslation(CGPoint(x: 0,y: 0), in: self)
        }
        else if gesture.state == .ended {
            draggedComponent = nil
        }
        setNeedsDisplay()
    }

    private func cursorMove(delta: CGPoint) {
        // Movement adjusted to scale.
        cursor.move(delta: CGPoint(x: delta.x / scale, y: delta.y))
    }

    @objc func longPress(press: UILongPressGestureRecognizer) {
        if press.state == .began {
            if cursor.movement == .horizontal {
                cursor.movement = .omnidirectional
            }
            else if cursor.movement == .omnidirectional {
                cursor.movement = .horizontal
            }
            let pressPositionY = press.location(in: self).y
            cursor.positionOmniCircleY =  pressPositionY
            setNeedsDisplay()
        }
    }

    func showCalipers() {
        os_log("showCalipers()", log: .action, type: .info)
        let width = self.frame.width
        caliper.bar1Position = width / 3
        caliper.bar2Position = caliper.bar1Position + width / 3
        caliper.crossbarPosition = caliperMaxY / 2
        setNeedsDisplay()
    }

    func newCalibration(zoom: CGFloat) -> Calibration {
        let calibration = Calibration()
        calibration.set(zoom: zoom, value: caliper.value)
        return calibration
    }

    func addMarkWithAttachedCursor(positionX: CGFloat) {
        os_log("addMarkWithAttachedCursor(position:) - CursorView", log: OSLog.debugging, type: .debug)
        // imageScrollView starts at x = 0, contentInset shifts view to right, and the left margin is negative.
        // So ignore positions in left margin.
        if positionX >= 0 {
            moveCursor(cursorViewPositionX: positionX / scale)  // cursor is not affected by offset, only zoom scale
            cursorIsVisible = true
            ladderViewDelegate.addAttachedMark(scaledViewPositionX: positionX)
            setCursorHeight()
            setNeedsDisplay()
        }
    }
}

// MARK: - CursorViewDelegate protocol

protocol CursorViewDelegate: AnyObject {
    var cursorIsVisible: Bool { get set }
    var caliperMaxY: CGFloat { get set }
    var caliperCrossbarPosition: CGFloat { get set }
       
    func refresh()
    func moveCursor(cursorViewPositionX positionX: CGFloat)
    func setCursorHeight(anchorPositionY: CGFloat?)
    func cursorMovement() -> Movement
    func setMarkerPositions(at positions: [CGPoint])
}

extension CursorViewDelegate {
    // Must be declared here, before class definition of setCursorHeight
    func setCursorHeight(anchorPositionY: CGFloat? = nil) {
        return setCursorHeight(anchorPositionY: anchorPositionY)
    }
}

// MARK: - CursorViewDelegate implementation

extension CursorView: CursorViewDelegate {

    var cursorIsVisible: Bool {
        get { cursor.visible }
        set { cursor.visible = newValue }
    }

    var caliperMaxY: CGFloat {
        get { caliper.maxY }
        set { caliper.maxY = newValue }
    }
    var caliperMinY: CGFloat {
        get { caliper.minY }
        set { caliper.minY = newValue }
    }

    var caliperCrossbarPosition: CGFloat {
        get { caliper.crossbarPosition }
        set { caliper.crossbarPosition = newValue }
    }
    var caliperBar1Position: CGFloat {
        get { caliper.bar1Position }
        set { caliper.bar1Position = newValue }
    }
    var caliperBar2Position: CGFloat {
        get { caliper.bar2Position }
        set { caliper.bar2Position = newValue }
    }

    func refresh() {
        setNeedsDisplay()
    }

    func moveCursor(cursorViewPositionX positionX: CGFloat) {
        cursor.positionX = positionX
    }

    func cursorMovement() -> Movement {
        return cursor.movement
    }

    func setMarkerPositions(at positions: [CGPoint]) {
        markerPositions = positions
    }

    func drawMarkers() {
        for position in markerPositions {
            drawMarker(at: position)
        }
    }

    func drawMarker(at regionPosition: CGPoint) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let position = ladderViewDelegate.convertPosition(regionPosition, toView: self)

        let positionX = scale * position.x - offsetX // inlined, for efficiency
        let cursorDefaultHeight = ladderViewDelegate.getTopOfLadderView(view: self)
        let defaultHeight = cursorDefaultHeight
        let height = defaultHeight
//        var height = region.proximalBoundaryY + (regionPosition.0.y * region.height)
//        height = (positionX <= leftMargin) ? defaultHeight : height
        let endPoint = CGPoint(x: positionX, y: height)


        context.setStrokeColor(markerColor.cgColor)
        context.setLineWidth(markerLineWidth)
        context.setAlpha(alphaValue)
        context.move(to: CGPoint(x: positionX, y: 0))
        context.addLine(to: endPoint)
        context.strokePath()
    }
}

//
//  CursorView.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import os.log

protocol CursorViewDelegate: AnyObject {
    var cursorIsVisible: Bool { get set }

    func refresh()
    func moveCursor(cursorViewPositionX positionX: CGFloat)
    func setCursorHeight(anchorPositionY: CGFloat?)
    func setCaliperMaxY(_ maxY: CGFloat)
    func cursorMovement() -> Movement
    func isCalibrated() -> Bool
    func setIsCalibrated(_ value: Bool)
    func markMeasurement(segment: Segment) -> CGFloat
    func intervalMeasurement(value: CGFloat) -> CGFloat
}

extension CursorViewDelegate {
    // Must be declared here, before class definition of setCursorHeight
    func setCursorHeight(anchorPositionY: CGFloat? = nil) {
        return setCursorHeight(anchorPositionY: anchorPositionY)
    }
}

final class CursorView: ScaledView {
    private let rightMargin: CGFloat = 5 // unused?
    private let alphaValue: CGFloat = 0.8
    private let accuracy: CGFloat = 20 // How close a tap has to be to a cursor in unscaled view to register.

    // Parameters that will eventually be preferences.
    var lineWidth: CGFloat = 2
    var color: UIColor = UIColor.systemBlue

    private var cursor: Cursor = Cursor()
    private var rawCursorHeight: CGFloat?

    private var caliper: Caliper = Caliper()
    private var draggedComponent: Caliper.Component?
    var caliperMaxY: CGFloat = 0 {
        didSet {
            caliper.maxY = caliperMaxY
        }
    }

    var calibration: Calibration?

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
    var maxCursorPositionY: CGFloat = 0 {
        didSet {
            cursor.maxPositionOmniCircleY = maxCursorPositionY
        }
    }
    var mode: Mode = .normal

    var allowTaps = true // set false to prevent taps from making marks
    var cursorEndPointY: CGFloat = 0

    var imageIsLocked = false

    weak var ladderViewDelegate: LadderViewDelegate! // Note IUO.

    // MARK: - init

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
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

        let draggingPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.dragging))
        self.addGestureRecognizer(draggingPanRecognizer)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress))
        self.addGestureRecognizer(longPressRecognizer)
    }

    // MARK: - draw

    override func draw(_ rect: CGRect) {
        if imageIsLocked {
            showLockImageWarning(rect: rect)
        }
        if mode == .calibration {
            drawCaliper(rect)
            return
        }
        if let context = UIGraphicsGetCurrentContext() {
            guard cursor.visible else { return }

            let position = scale * cursor.positionX - offsetX // inlined, for efficiency
            let cursorDefaultHeight = ladderViewDelegate.getTopOfLadder(view: self)
            let defaultHeight = cursorDefaultHeight
            let height = (position <= leftMargin) ? defaultHeight : cursor.markIntersectionPositionY
            let endPoint = CGPoint(x: position, y: height)

            context.setStrokeColor(color.cgColor)
            context.setLineWidth(lineWidth)
            context.setAlpha(alphaValue)
            context.move(to: CGPoint(x: position, y: 0))
            context.addLine(to: endPoint)
            context.strokePath()
            if position > leftMargin {
                drawCircle(context: context, center: endPoint, radius: 5)
            }
            if cursor.movement == .omnidirectional {
                drawCircle(context: context, center: CGPoint(x: position, y: cursor.positionOmniCircleY), radius: 20)
            }
        }
    }

    func drawCaliper(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(caliper.color.cgColor)
            context.setLineWidth(lineWidth)
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
            let textFont = UIFont(name: "Helvetica Neue Medium", size: 14.0) ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
            let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            attributes = [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.foregroundColor: caliper.color
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


//    func caliperText(rect: CGRect, textPosition: TextPosition, optimizeTextPosition: Bool) {
//        let text = measurement()
//        paragraphStyle.lineBreakMode = .byTruncatingTail
//        paragraphStyle.alignment = .center
//        var attributes = [NSAttributedString.Key: Any]()
//        attributes = [
//            NSAttributedString.Key.font: textFont,
//            NSAttributedString.Key.paragraphStyle: paragraphStyle,
//            NSAttributedString.Key.foregroundColor: color
//        ]
//        let size = text.size(withAttributes: attributes)
//        let textRect = caliperTextPosition(left: fmin(bar1Position, bar2Position), right: fmax(bar1Position, bar2Position), center: crossBarPosition, size: size, rect: rect, textPosition: textPosition, optimizeTextPosition: optimizeTextPosition)
//        text.draw(in: textRect, withAttributes: attributes)
//    }

    func showLockImageWarning(rect: CGRect) {
        let text = L("IMAGE LOCK")
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0),
            .foregroundColor: UIColor.white, .backgroundColor: UIColor.systemRed
        ]
        let lockRect = CGRect(x: rect.origin.x + 5, y: rect.origin.y + 5, width: rect.size.width, height: rect.size.height)
        text.draw(in: lockRect, withAttributes: attributes)
    }

    func setCursorHeight(anchorPositionY: CGFloat? = nil) {
        if let anchorPositionY = anchorPositionY {
            let positionY = ladderViewDelegate.getPositionYInView(positionY: anchorPositionY, view: self)
            cursor.markIntersectionPositionY = positionY
        }
        else {
            let cursorHeight = getCursorHeight(anchor: getAttachedMarkAnchor())
            cursor.markIntersectionPositionY = cursorHeight ?? 0
        }
    }

    func setCaliperMaxY(_ maxY: CGFloat) {
        caliperMaxY = maxY
    }

    // Add tiny circle around intersection of cursor and mark.
    private func drawCircle(context: CGContext, center: CGPoint, radius: CGFloat) {
        context.addArc(center: center, radius: radius, startAngle: 0.0, endAngle: .pi * 2.0, clockwise: true)
        context.strokePath()
    }

    func getAttachedMarkAnchor() -> Anchor {
        return ladderViewDelegate.getAttachedMarkAnchor()
    }

    private func getAnchorPositionY(_ anchor: Anchor, _ ladderViewDelegate: LadderViewDelegate) -> CGFloat? {
        let anchorY: CGFloat?
        switch anchor {
        case .proximal:
            anchorY = ladderViewDelegate.getRegionProximalBoundary(view: self)
        case .middle:
            anchorY = ladderViewDelegate.getRegionMidPoint(view: self)
        case .distal:
            anchorY = ladderViewDelegate.getRegionDistalBoundary(view: self)
        case .none:
            anchorY = nil
        }
        return anchorY
    }

    private func getCursorHeight(anchor: Anchor) -> CGFloat? {
        return getAnchorPositionY(anchor, ladderViewDelegate)
    }

    // MARK: - touches

    // This function passes touch events to the views below if the point is not
    // near the cursor.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if mode == .calibration {
            return caliper.isNearCaliper(point: point, accuracy: accuracy)
        }
        guard cursor.visible else { return false }
        if isNearCursor(positionX: point.x, accuracy: accuracy) && point.y < ladderViewDelegate.getRegionProximalBoundary(view: self) {
            return true
        }
        return false
    }

    func isNearCursor(positionX: CGFloat, accuracy: CGFloat) -> Bool {
        return positionX < translateToScaledViewPositionX(regionPositionX: cursor.positionX) + accuracy && positionX > translateToScaledViewPositionX(regionPositionX: cursor.positionX) - accuracy
    }

    @objc func singleTap(tap: UITapGestureRecognizer) {
        os_log("singleTap(tap:) - CursorView", log: OSLog.touches, type: .info)
        guard allowTaps else { return }
        // Single tap does nothing during calibration.
        guard mode == .normal else { return }
        ladderViewDelegate.toggleAttachedMarkAnchor()
        ladderViewDelegate.refresh()
        setNeedsDisplay()
    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        os_log("doubleTap(tap:) - CursorView", log: OSLog.touches, type: .info)
//        redoablyUnAddMarkWithAttachedCursor(position: tap.location(in: self))
        ladderViewDelegate.deleteAttachedMark()
        ladderViewDelegate.refresh()
    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        // Don't drag if no attached mark.
        if mode == .calibration {
            dragCaliper(pan: pan)
            return
        }
        guard let attachedMarkAnchorPosition = ladderViewDelegate.getAttachedMarkScaledAnchorPosition() else { return }
        if pan.state == .began {
            self.undoManager?.beginUndoGrouping()
            cursorEndPointY = attachedMarkAnchorPosition.y
            ladderViewDelegate.setAttachedMarkAndGroupedMarksHighlights()
//            ladderViewDelegate.highlightGroupedMarks(highlight: .grouped)
            ladderViewDelegate.moveAttachedMark(position: attachedMarkAnchorPosition) // This has to be here for undo to work.
        }
        if pan.state == .changed {
            let delta = pan.translation(in: self)
            cursorMove(delta: delta)
            cursorEndPointY += delta.y
            ladderViewDelegate.moveAttachedMark(position: CGPoint(x: translateToScaledViewPositionX(regionPositionX: cursor.positionX), y: cursorEndPointY))
            ladderViewDelegate.refresh()
            setNeedsDisplay()
            pan.setTranslation(CGPoint(x: 0,y: 0), in: self)
        }
        if pan.state == .ended {
            self.undoManager?.endUndoGrouping()
            ladderViewDelegate.groupMarksNearbyAttachedMark()
            ladderViewDelegate.refresh()
            cursorEndPointY = 0
        }
    }

    private func dragCaliper(pan: UIPanGestureRecognizer) {
        // No undo for calibration.
        if pan.state == .began {
            draggedComponent = caliper.isNearCaliperComponent(point: pan.location(in: self), accuracy: accuracy)
            caliper.color = UIColor.systemBlue
        }
        else if pan.state == .changed {
            guard let draggedComponent = draggedComponent else { return }
            let delta = pan.translation(in: self)
            caliper.move(delta: delta, component: draggedComponent)
            pan.setTranslation(CGPoint(x: 0,y: 0), in: self)
        }
        else if pan.state == .ended {
            draggedComponent = nil
            caliper.color = UIColor.systemRed
            P("caliper.value = \(caliper.value)")
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
            P("ppy \(pressPositionY),  mcpy \(maxCursorPositionY)")
            cursor.positionOmniCircleY = pressPositionY > maxCursorPositionY ? maxCursorPositionY : pressPositionY
            P("cursor.positionY \(cursor.positionOmniCircleY)")
            setNeedsDisplay()
        }
    }

    func showCalipers() {
        os_log("showCalipers()", log: .action, type: .info)
        mode = .calibration
        let width = self.frame.width
        caliper.bar1Position = width / 3
        caliper.bar2Position = caliper.bar1Position + width / 3
        caliper.crossbarPosition = caliperMaxY / 2
        setNeedsDisplay()
    }

    func setCalibration(zoom: CGFloat) {
        calibration?.set(zoom: zoom, calFactor: Calibration.standardInterval / caliper.value)
        calibration?.isCalibrated = true
        ladderViewDelegate.refresh()
    }

    func putCursor(imageScrollViewPosition position: CGPoint) {
        cursor.positionX = position.x
        cursor.positionOmniCircleY = position.y > maxCursorPositionY ? maxCursorPositionY : position.y
    }

    func addMarkWithAttachedCursor(position: CGPoint) {
        os_log("addMarkWithAttachedCursor(position:) - CursorView", log: OSLog.debugging, type: .debug)
        // imageScrollView starts at x = 0, contentInset shifts view to right, and the left margin is negative.
        if position.x > 0 {
            os_log("scale = %f", log: OSLog.debugging, type: .debug, scale)
            P(">>> scale = \(scale)")
            putCursor(imageScrollViewPosition: CGPoint(x: position.x / scale, y: position.y))
            cursorIsVisible = true
            ladderViewDelegate.addAttachedMark(scaledViewPositionX: position.x)
            setCursorHeight()
            setNeedsDisplay()
        }
    }
}

// MARK: - CursorView delegate methods

extension CursorView: CursorViewDelegate {
    var cursorIsVisible: Bool {
        get { cursor.visible }
        set(newValue) { cursor.visible = newValue }
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

    func isCalibrated() -> Bool {
        return calibration?.isCalibrated ?? false
    }

    func setIsCalibrated(_ value: Bool) {
        calibration?.isCalibrated = value
    }

    func markMeasurement(segment: Segment) -> CGFloat {
        guard let calibration = calibration else { return 0 }
        return abs(segment.proximal.x - segment.distal.x) * calibration.currentCalFactor
    }

    func intervalMeasurement(value: CGFloat) -> CGFloat {
        guard let calibration = calibration else { return 0 }
        return value * calibration.currentCalFactor
    }
}

//
//  SeparatorView.swift
//  EP Diagram
//
//  Created by David Mann on 12/26/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

// After https://gist.github.com/ElegyD/c5af8892de04fa8a33e26fb919972d6a
// Only horizonal type separator used in EP Diagram.

let totalSize: CGFloat = 18
let visibleSize: CGFloat = 8
let margin: CGFloat = (totalSize - visibleSize) / 2
let minSize: CGFloat = 100
let indicatorSize: CGFloat = 36  // indicator in middle of separator

protocol OnConstraintUpdateProtocol: AnyObject {
    func updateConstraintOnBasisOfTouch(touch: UITouch)
}

class SeparatorView: UIView {
    var startConstraint: NSLayoutConstraint?  // vertical position of separator
    weak var primaryView: UIView?  // view above
    weak var secondaryView: UIView? // view below

    // Separator view needs to communicate with the cursor view, thus...
    weak var cursorViewDelegate: CursorViewDelegate?

    var oldPosition: CGFloat = 0  // position of separator before gesture started
    var firstTouch: CGPoint? // point where drag started

    weak var updateListener: OnConstraintUpdateProtocol?

    var showIndicator: Bool = true
    var allowTouches: Bool = true {
        didSet {
            isUserInteractionEnabled = allowTouches
        }
    }

    @discardableResult
    internal static func addSeparatorBetweenViews(primaryView: UIView, secondaryView: UIView, parentView: UIView) -> SeparatorView{
        let separator = HorizontalSeparatorView(primaryView: primaryView, secondaryView: secondaryView)

        separator.setupParentViewConstraints(parentView: parentView)
        parentView.addSubview(separator)
        separator.setupSeparatorConstraints()

        return separator
    }

    init(primaryView: UIView, secondaryView: UIView) {
        print("****separatorView init****")
        self.primaryView = primaryView
        self.secondaryView = secondaryView
        super.init(frame: CGRect.zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isUserInteractionEnabled = true
        self.backgroundColor = .clear
    }

    func setupParentViewConstraints(parentView: UIView) {}

    func setupSeparatorConstraints() {}

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard allowTouches else { return }
        self.firstTouch = touches.first?.location(in: self.superview)
        self.startConstraint!.constant = self.oldPosition
        self.startConstraint!.isActive = true
        cursorViewDelegate?.cursorIsVisible = false
        let ladderView = secondaryView as? LadderView
        ladderView?.normalizeAllMarks()
        ladderView?.refresh()
        cursorViewDelegate?.refresh()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard allowTouches else { return }

        guard let touch = touches.first, let event = event else { return }

        let predictedTouch = event.predictedTouches(for: touch)?.last
        if predictedTouch != nil {
            updateListener?.updateConstraintOnBasisOfTouch(touch: predictedTouch!)
            return
        }
        updateListener?.updateConstraintOnBasisOfTouch(touch: touch)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard allowTouches else { return }

        guard let touch = touches.first else { return }
        updateListener?.updateConstraintOnBasisOfTouch(touch: touch)
        // redraw views.
        let ladderView = secondaryView as? LadderView
        let caliperMaxY = primaryView?.frame.height ?? 0
        ladderView?.resetSize()
        ladderView?.caliperMaxY = caliperMaxY
        ladderView?.refresh()
        cursorViewDelegate?.refresh()
    }

    func drawSeparator(_ rect: CGRect, with color: UIColor) {
        color.set()
        let path = UIBezierPath(rect: rect)
        path.stroke()
        path.fill()
    }

    func drawIndicator(_ rect: CGRect, with color: UIColor) {
        if showIndicator {
            color.set()
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 2.5)
            path.stroke()
            path.fill()
        }
    }
}

final class HorizontalSeparatorView: SeparatorView, OnConstraintUpdateProtocol {
    override init(primaryView: UIView, secondaryView: UIView) {
        super.init(primaryView: primaryView, secondaryView: secondaryView)
        updateListener = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // FIXME: This is never called!
    deinit {
        print("*****SeparatorView deinit()******")
    }

    override func setupSeparatorConstraints() {
        self.heightAnchor.constraint(equalToConstant: totalSize).isActive = true
        self.superview?.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.superview?.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        primaryView?.bottomAnchor.constraint(equalTo: self.topAnchor, constant: margin + visibleSize / 2).isActive = true
        secondaryView?.topAnchor.constraint(equalTo: self.bottomAnchor, constant: -(margin + visibleSize / 2)).isActive = true
        startConstraint = self.topAnchor.constraint(equalTo: self.superview!.topAnchor, constant: 0)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.oldPosition = self.frame.origin.y
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    }

    func updateConstraintOnBasisOfTouch(touch: UITouch) {
        guard let primaryView = primaryView, let secondaryView = secondaryView else { return }
        // calculate where separator should be moved to
        var y: CGFloat = self.oldPosition + touch.location(in: self.superview).y - self.firstTouch!.y
        // make sure the views above and below are not too small
        y = max(y, primaryView.frame.origin.y + minSize - margin)
        y = min(y, secondaryView.frame.origin.y + secondaryView.frame.size.height - (margin + minSize))

        // set constraint
        self.startConstraint!.constant = y
    }

    override func draw(_ rect: CGRect) {
        let separatorRect = CGRect(x: 0, y: margin, width: self.bounds.size.width, height: visibleSize)
        let indicatorRect = CGRect(x: (self.bounds.size.width - indicatorSize) / 2, y: margin + (visibleSize - (visibleSize / 4)) / 2, width: indicatorSize, height: visibleSize / 4)
        // We'll hide the separator and let the ladder view draw it.
        super.drawSeparator(separatorRect, with: .clear)
        super.drawIndicator(indicatorRect, with: .systemRed)
    }
}

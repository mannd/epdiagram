//
//  SeparatorView.swift
//  EP Diagram
//
//  Created by David Mann on 12/26/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

// FIXME: Refactor for EP Diagram.  Eliminate vertical separator, etc.
// After https://gist.github.com/ElegyD/c5af8892de04fa8a33e26fb919972d6a
enum SeparatorType {
    case horizontal
    case vertical
}

let totalSize: CGFloat = 18
let visibleSize: CGFloat = 8
let margin: CGFloat = (totalSize - visibleSize) / 2
let minSize: CGFloat = 100
let indicatorSize: CGFloat = 36  // indicator in middle of separator


protocol OnConstraintUpdateProtocol {
    func updateConstraintOnBasisOfTouch(touch: UITouch)
}

class SeparatorView: UIView {

    var startConstraint: NSLayoutConstraint?  // vertical position of separator
    var primaryView: UIView  // view above
    var secondaryView: UIView // view below

    var oldPosition: CGFloat = 0  // position of separator before gesture started
    var firstTouch: CGPoint? // point where drag started

    var updateListener: OnConstraintUpdateProtocol?

    @discardableResult
    internal static func addSeparatorBetweenViews(separatorType: SeparatorType, primaryView: UIView, secondaryView: UIView, parentView: UIView) -> SeparatorView{
        var separator: SeparatorView
        if separatorType == .horizontal {
            separator = HorizontalSeparatorView(primaryView: primaryView, secondaryView: secondaryView)
        }
        else {
            separator = VerticalSeparatorView(primaryView: primaryView, secondaryView: secondaryView)
        }
        separator.setupParentViewConstraints(parentView: parentView)
        parentView.addSubview(separator)
        separator.setupSeparatorConstraints()

        return separator
    }

    init(primaryView: UIView, secondaryView: UIView) {
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
        self.firstTouch = touches.first?.location(in: self.superview)
        self.startConstraint!.constant = self.oldPosition
        self.startConstraint!.isActive = true
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let event = event else { return }

        let predictedTouch = event.predictedTouches(for: touch)?.last
        if predictedTouch != nil {
            updateListener?.updateConstraintOnBasisOfTouch(touch: predictedTouch!)
            return
        }
        updateListener?.updateConstraintOnBasisOfTouch(touch: touch)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateListener?.updateConstraintOnBasisOfTouch(touch: touch)
        // redraw views.
        let ladderView = secondaryView as? LadderView
        let caliperMaxY = primaryView.frame.height
        ladderView?.resetSize()
        ladderView?.setCaliperMaxY(caliperMaxY)
        ladderView?.refresh()
    }

    func drawSeparator(_ rect: CGRect, with color: UIColor) {
        color.set()
        let path = UIBezierPath(rect: rect)
        path.stroke()
        path.fill()
    }

    func drawIndicator(_ rect: CGRect, with color: UIColor) {
        color.set()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 2.5)
        path.stroke()
        path.fill()
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

    override func setupParentViewConstraints(parentView: UIView) {
//        parentView.leadingAnchor.constraint(equalTo: primaryView.leadingAnchor).isActive = true
//        parentView.trailingAnchor.constraint(equalTo: primaryView.trailingAnchor).isActive = true
//        parentView.leadingAnchor.constraint(equalTo: secondaryView.leadingAnchor).isActive = true
//        parentView.trailingAnchor.constraint(equalTo: secondaryView.trailingAnchor).isActive = true
//        parentView.topAnchor.constraint(equalTo: primaryView.topAnchor).isActive = true
//        let height = secondaryView.heightAnchor.constraint(equalTo: primaryView.heightAnchor)
//        height.priority = .defaultLow
//        height.isActive = true
//        parentView.bottomAnchor.constraint(equalTo: secondaryView.bottomAnchor).isActive = true
    }

    // FIXME: Separator is drawn across width of screen in landscape view.
    // Would like to constrain to Safe Margin Area, but since we have made
    // the separator clear it doesn't matter much.
    override func setupSeparatorConstraints() {
        self.heightAnchor.constraint(equalToConstant: totalSize).isActive = true
        self.superview?.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.superview?.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        primaryView.bottomAnchor.constraint(equalTo: self.topAnchor, constant: margin + visibleSize / 2).isActive = true
        secondaryView.topAnchor.constraint(equalTo: self.bottomAnchor, constant: -(margin + visibleSize / 2)).isActive = true
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
        // calculate where separator should be moved to
        var y: CGFloat = self.oldPosition + touch.location(in: self.superview).y - self.firstTouch!.y
        // make sure the views above and below are not too small
        y = max(y, self.primaryView.frame.origin.y + minSize - margin)
        y = min(y, self.secondaryView.frame.origin.y + self.secondaryView.frame.size.height - (margin + minSize))

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

// Vertical separator not used in EP Diagram.
final class VerticalSeparatorView: SeparatorView, OnConstraintUpdateProtocol {
    override init(primaryView: UIView, secondaryView: UIView) {
           super.init(primaryView: primaryView, secondaryView: secondaryView)
           updateListener = self
       }

       required init?(coder aDecoder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }

       override func setupParentViewConstraints(parentView: UIView) {
           parentView.topAnchor.constraint(equalTo: primaryView.topAnchor).isActive = true
           parentView.topAnchor.constraint(equalTo: secondaryView.topAnchor).isActive = true
           parentView.bottomAnchor.constraint(equalTo: primaryView.bottomAnchor).isActive = true
           parentView.leadingAnchor.constraint(equalTo: secondaryView.leadingAnchor).isActive = true
           parentView.bottomAnchor.constraint(equalTo: secondaryView.bottomAnchor).isActive = true
           parentView.leadingAnchor.constraint(equalTo: primaryView.leadingAnchor).isActive = true
           let width = secondaryView.widthAnchor.constraint(equalTo: primaryView.widthAnchor)
           width.priority = .defaultLow
           width.isActive = true
           parentView.trailingAnchor.constraint(equalTo: secondaryView.trailingAnchor).isActive = true
       }

       override func setupSeparatorConstraints() {
           self.widthAnchor.constraint(equalToConstant: totalSize).isActive = true
           self.superview?.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
           self.superview?.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
           primaryView.trailingAnchor.constraint(equalTo: self.leadingAnchor, constant:  margin + visibleSize / 2).isActive = true
           secondaryView.leadingAnchor.constraint(equalTo: self.trailingAnchor, constant: -(margin + visibleSize / 2)).isActive = true

           startConstraint = self.leadingAnchor.constraint(equalTo: self.superview!.leadingAnchor, constant: 0)
       }

       override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
           self.oldPosition = self.frame.origin.x
           super.touchesBegan(touches, with: event)
       }

       override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
           super.touchesMoved(touches, with: event)
       }

       override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
           super.touchesEnded(touches, with: event)
       }

       func updateConstraintOnBasisOfTouch(touch: UITouch) {
           // calculate where separator should be moved to
           var x: CGFloat = self.oldPosition + touch.location(in: self.superview).x - self.firstTouch!.x

           // make sure the views above and below are not too small
           x = max(x, self.primaryView.frame.origin.x + minSize - margin)
           x = min(x, self.secondaryView.frame.origin.x + self.secondaryView.frame.size.width - (margin + minSize))

           // set constraint
           self.startConstraint!.constant = x
       }

       override func draw(_ rect: CGRect) {
           let separatorRect = CGRect(x: margin, y: 0, width: visibleSize, height: self.bounds.size.height)
           let indicatorRect = CGRect(x: margin + (visibleSize - (visibleSize / 4)) / 2, y: (self.bounds.size.height - indicatorSize) / 2, width: visibleSize / 4, height: indicatorSize)
           super.drawSeparator(separatorRect, with: .white)
           super.drawIndicator(indicatorRect, with: .lightGray)
       }

}

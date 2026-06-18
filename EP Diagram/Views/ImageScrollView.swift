//
//  ImageScrollView.swift
//  EP Diagram
//
//  Created by David Mann on 12/31/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

/// ImageScrollView has a content UIView that wraps a UIImageView, which allows zooming and scrolling of
/// the content view, while the image view can have rotational transforms applied to it separately.
class ImageScrollView: UIScrollView {
    weak var diagramViewControllerDelegate: DiagramViewControllerDelegate?
    private lazy var editMenuInteraction = UIEditMenuInteraction(delegate: self)

    override var canBecomeFirstResponder: Bool { true }

    var leftMargin: CGFloat = 0 // set by DiagramViewController
    var mode: Mode = .normal // set by DiagramViewController
    var isActivated: Bool = true {
        didSet {
            isUserInteractionEnabled = isActivated
            alpha = isActivated ? 1.0 : 0.4
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addInteraction(editMenuInteraction)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addInteraction(editMenuInteraction)
    }

    deinit {
        print("*****ImageScrollView deinit()******")
    }
}

extension ImageScrollView {
    /// Shows a "long press" menu that handles image rotation
    /// - Parameter gestureRecognizer: the long press gesture recognizer, containing the position of the press
    @IBAction func showImageMenu(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard let delegate = diagramViewControllerDelegate, delegate.okToShowLongPressMenu(),
              gestureRecognizer.state == .began,
              contentSize != CGSize.zero else { return }

        delegate.hideCursor()

        let location = gestureRecognizer.location(in: self)
        let configuration = UIEditMenuConfiguration(identifier: nil, sourcePoint: location)
        editMenuInteraction.presentEditMenu(with: configuration)
    }

    // Image menu functions.  Most of these just call the DiagramViewController delegate to do the actual work.

    /// Rotate the UIImageView, parameters passed back to DiagramViewController
    /// - Parameter degrees: degrees (not radians) as `CGFloat`
    func rotateImage(degrees: CGFloat) {
        assert(leftMargin > 0, "Left margin not set")
        diagramViewControllerDelegate?.rotateImage(degrees: degrees)
        setNeedsDisplay()
    }

    /// Show rotate menu as a toolbar
    @objc func showRotateToolbar() {
        diagramViewControllerDelegate?.showRotateToolbar()
    }

    @IBAction func resetMacImage(_ sender: Any) {
        resetImage()
    }

    /// Reset image to a identity transfrom
    @objc func resetImage() {
        diagramViewControllerDelegate?.resetImage()
    }

    /// Closes long press image menu
    @objc func doneAction() {
        self.resignFirstResponder()
    }

    /// Shows PDF menu as a toolbar
    @objc func showPDFToolbar() {
        diagramViewControllerDelegate?.showPDFToolbar()
    }
}


extension ImageScrollView: UIEditMenuInteractionDelegate {
    func editMenuInteraction(
        _ interaction: UIEditMenuInteraction,
        menuFor configuration: UIEditMenuConfiguration,
        suggestedActions: [UIMenuElement]
    ) -> UIMenu? {
        let rotateAction = UIAction(title: L("Rotate")) { [weak self] _ in
            self?.showRotateToolbar()
        }

        let resetAction = UIAction(title: L("Reset")) { [weak self] _ in
            self?.resetImage()
        }

        let doneAction = UIAction(title: L("Done")) { [weak self] _ in
            self?.doneAction()
        }

        var actions: [UIMenuElement] = [rotateAction, resetAction]

        if diagramViewControllerDelegate?.showPDFMenuItems() == true {
            let pdfAction = UIAction(title: L("PDF")) { [weak self] _ in
                self?.showPDFToolbar()
            }
            actions.append(pdfAction)
        }

        actions.append(doneAction)

        return UIMenu(children: actions)
    }
}


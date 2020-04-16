    //
    //  ViewController.swift
    //  EP Diagram
    //
    //  Created by David Mann on 4/29/19.
    //  Copyright © 2019 EP Studios. All rights reserved.
    //

    import UIKit

    final class ViewController: UIViewController {
        @IBOutlet var constraintHamburgerWidth: NSLayoutConstraint!
        @IBOutlet var constraintHamburgerLeft: NSLayoutConstraint!
        @IBOutlet var imageScrollView: UIScrollView!
        @IBOutlet var imageView: UIImageView!
        @IBOutlet var ladderView: LadderView!
        @IBOutlet var cursorView: CursorView!
        @IBOutlet var blackView: BlackView!

        private var separatorView: SeparatorView?
        private var undoButton: UIBarButtonItem = UIBarButtonItem()
        private var redoButton: UIBarButtonItem = UIBarButtonItem()
        private var mainMenuButtons: [UIBarButtonItem]?
        private var selectMenuButtons: [UIBarButtonItem]?
        internal var hamburgerMenuIsOpen = false
        
        // This margin is used for all the views.  As ECGs are always read from left
        // to right, there is no reason to reverse this.
        let leftMargin: CGFloat = 30
        let maxBlackAlpha: CGFloat = 0.4

        override func viewDidLoad() {
            P("viewDidLoad")
            super.viewDidLoad()

            // These 2 views are guaranteed to exist, so the delegates are IUOs.
            cursorView.ladderViewDelegate = ladderView
            ladderView.cursorViewDelegate = cursorView
            imageScrollView.delegate = self

            title = L("EP Diagram", comment: "app name")

            if Common.isRunningOnMac() {
                navigationController?.setNavigationBarHidden(true, animated: false)
//                UIView.setAnimationsEnabled(false) // Mac transitions look better without animation.
            }
            UIView.setAnimationsEnabled(true)

            // Distinguish the two views using slightly different background colors.
            if #available(iOS 13.0, *) {
                imageScrollView.backgroundColor = UIColor.secondarySystemBackground
                ladderView.backgroundColor = UIColor.tertiarySystemBackground
            } else {
                imageScrollView.backgroundColor = UIColor.lightGray
                ladderView.backgroundColor = UIColor.white
            }

            blackView.delegate = self
            blackView.alpha = 0.0
//            blackView.isUserInteractionEnabled = true
            constraintHamburgerLeft.constant = -self.constraintHamburgerWidth.constant;

            // Ensure there is a space for labels at the left margin.
            ladderView.leftMargin = leftMargin
            cursorView.leftMargin = leftMargin

            setMaxCursorPositionY()

            let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
            singleTapRecognizer.numberOfTapsRequired = 1
            imageScrollView.addGestureRecognizer(singleTapRecognizer)

            if #available(iOS 13.0, *) {
                let interaction = UIContextMenuInteraction(delegate: ladderView)
                ladderView.addInteraction(interaction)
            }

            navigationItem.setLeftBarButton(UIBarButtonItem(image: UIImage(named: "hamburger"), style: .plain, target: self, action: #selector(toggleHamburgerMenu)), animated: true)
        }

        @objc func onDidUndoableAction(_ notification: Notification) {
            if notification.name == .didUndoableAction {
                manageButtons()
            }
        }

        override func viewDidAppear(_ animated: Bool) {
            P("viewDidAppear")
            assertDelegatesNonNil()
            // Need to set this here, after view draw, or Mac malpositions cursor at start of app.
            imageScrollView.contentInset = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
            showMainMenu()
            NotificationCenter.default.addObserver(self, selector: #selector(onDidUndoableAction(_:)), name: .didUndoableAction, object: nil)
            manageButtons()
            resetViews()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            NotificationCenter.default.removeObserver(self, name: .didUndoableAction, object: nil)
        }

        // Crash program at compile time if IUO delegates are nil.
        private func assertDelegatesNonNil() {
            assert(cursorView.ladderViewDelegate != nil && ladderView.cursorViewDelegate != nil)
        }

        func showMessage(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L("OK"), style: .cancel, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }

        private func showMainMenu() {
            if mainMenuButtons == nil {
                let calibrateTitle = L("Calibrate", comment: "calibrate button label title")
                let selectTitle = L("Select", comment: "select button label title")
                let undoTitle = L("Undo")
                let redoTitle = L("Redo")
                let calibrateButton = UIBarButtonItem(title: calibrateTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(calibrate))
                let selectButton = UIBarButtonItem(title: selectTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(selectMarks))
                undoButton = UIBarButtonItem(title: undoTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(undo))
                redoButton = UIBarButtonItem(title: redoTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(redo))
                mainMenuButtons = [calibrateButton, selectButton, undoButton, redoButton]
            }
            // Note: set toolbar items this way, not directly (i.e. toolbar.items = something).
            setToolbarItems(mainMenuButtons, animated: false)
            navigationController?.setToolbarHidden(false, animated: false)
        }

        private func showSelectMenu() {
            if selectMenuButtons == nil {
                let textLabelText = "Tap marks to select"
                let textLabel = UILabel()
                textLabel.text = textLabelText
                let textLabelButton = UIBarButtonItem(customView: textLabel)
                let copyTitle = L("Copy", comment: "copy mark button label title")
                let copyButton = UIBarButtonItem(title: copyTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(copyMarks))
                let cancelTitle = L("Cancel")
                let cancelButton = UIBarButtonItem(title: cancelTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancelSelect))
                selectMenuButtons = [textLabelButton, copyButton, cancelButton]
            }
            setToolbarItems(selectMenuButtons, animated: false)
            navigationController?.setToolbarHidden(false, animated: false)
        }

        @objc func toggleHamburgerMenu() {
            if hamburgerMenuIsOpen {
                hideHamburgerMenu()
            }
            else {
                showHamburgerMenu()
            }
        }

        func showHamburgerMenu() {
            constraintHamburgerLeft.constant = 0
            hamburgerMenuIsOpen = true
            navigationController?.setToolbarHidden(true, animated: true)
            separatorView?.isUserInteractionEnabled = false
            self.cursorView.isUserInteractionEnabled = false
            self.separatorView?.isHidden = true
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
                self.blackView.alpha = self.maxBlackAlpha
            })
        }

        func hideHamburgerMenu() {
            self.constraintHamburgerLeft.constant = -self.constraintHamburgerWidth.constant;
            hamburgerMenuIsOpen = false
            navigationController?.setToolbarHidden(false, animated: true)
            separatorView?.isUserInteractionEnabled = true
//            separatorView?.isHidden = false
            self.cursorView.isUserInteractionEnabled = true
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
                self.blackView.alpha = 0
            }, completion: { (finished:Bool) in
                self.separatorView?.isHidden = false })
        }


        @available(*, deprecated, message: "This doesn't seem to do anything.")
        private func centerImage() {
            // This centers image, as opposed to starting with it at the upper left
            // hand corner of the screen.
            if !Common.isRunningOnMac() {
                let newContentOffsetX = (imageScrollView.contentSize.width/2) - (imageScrollView.bounds.size.width/2);
                imageScrollView.contentOffset = CGPoint(x: newContentOffsetX, y: 0)
            }
        }

        // MARK: -  Buttons

        @objc func calibrate() {
            P("calibrate")
        }

        @objc func selectMarks() {
            P("select")
            showSelectMenu()
            ladderView.selectMarkMode = true
        }

        @objc func copyMarks() {
            P("copy")
        }

        @objc func cancelSelect() {
            P("cancel select")
            showMainMenu()
            ladderView.selectMarkMode = false
            ladderView.unhighlightAllMarks()
            ladderView.unselectAllMarks()
            ladderView.setNeedsDisplay()
        }

        @objc func undo() {
            if self.undoManager?.canUndo ?? false {
                self.undoManager?.undo()
                ladderView.setNeedsDisplay()
            }
        }

        @objc func redo() {
            if self.undoManager?.canRedo ?? false {
                self.undoManager?.redo()
                ladderView.setNeedsDisplay()
            }
        }

        func manageButtons() {
            // DispatchQueue here forces UI to finish up its tasks before performing below on the main thread.
            // If not used, undoManager.canUndo/Redo is not updated before this is called.
            DispatchQueue.main.async {
                self.undoButton.isEnabled = self.undoManager?.canUndo ?? false
                self.redoButton.isEnabled = self.undoManager?.canRedo ?? false
            }
        }

        // MARK: - Touches

        private func undoablyAddMarkWithAttachedCursor(position: CGPoint) {
            self.undoManager?.registerUndo(withTarget: self, handler: { target in
                target.redoablyUnAddMarkWithAttachedCursor(position: position)
            })
            NotificationCenter.default.post(name: .didUndoableAction, object: nil)
            addMarkWithAttachedCursor(position: position)
        }

        private func redoablyUnAddMarkWithAttachedCursor(position: CGPoint) {
            self.undoManager?.registerUndo(withTarget: self, handler: { target in
                target.undoablyAddMarkWithAttachedCursor(position: position)
            })
            NotificationCenter.default.post(name: .didUndoableAction, object: nil)
            unAddMarkWithAttachedCursor(position: position)
        }


        private func addMarkWithAttachedCursor(position: CGPoint) {
            P("add mark with attached cursor")
            // imageScrollView starts at x = 0, contentInset shifts view to right, and the left margin is negative.
            if position.x > 0 {
                cursorView.putCursor(imageScrollViewPosition: position)
                cursorView.hideCursor(false)
                cursorView.attachMark(imageScrollViewPositionX: position.x)
                cursorView.setCursorHeight()
                cursorView.setNeedsDisplay()
            }
        }

        private func unAddMarkWithAttachedCursor(position: CGPoint) {
            ladderView.deleteAttachedMark()
            cursorView.hideCursor(true)
            cursorView.setNeedsDisplay()
        }

        @objc func singleTap(tap: UITapGestureRecognizer) {
            if !ladderView.hasActiveRegion() {
                ladderView.setActiveRegion(regionNum: 0)
            }
            if cursorView.cursorIsVisible() {
                ladderView.unattachAttachedMark()
                cursorView.hideCursor(true)
                ladderView.unhighlightAllMarks()
            }
            else {
                let position = tap.location(in: imageScrollView)
                undoablyAddMarkWithAttachedCursor(position: position)
            }
            setViewsNeedDisplay()
        }


        // MARK: - Rotate view

        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            // Remove separatorView when rotating to let original constraints resume.
            // Otherwise, views are not laid out correctly.
            if let separatorView = separatorView {
                separatorView.removeFromSuperview()
            }
            coordinator.animate(alongsideTransition: nil, completion: {
                _ in
                self.resetViews()
            })
        }

        func setMaxCursorPositionY() {
            cursorView.maxCursorPositionY = imageScrollView.frame.height
        }

        private func resetViews() {
            // Add back in separatorView after rotation.
            separatorView = HorizontalSeparatorView.addSeparatorBetweenViews(separatorType: .horizontal, primaryView: imageScrollView, secondaryView: ladderView, parentView: self.view)
            self.ladderView.resetSize()
            // FIXME: save and restore scrollview offset so it is maintained with rotation.
            self.imageView.setNeedsDisplay()
            setMaxCursorPositionY()
            setViewsNeedDisplay()
        }

        func setViewsNeedDisplay() {
            cursorView.setNeedsDisplay()
            ladderView.setNeedsDisplay()
        }


        // MARK: - Save and restore views

        // TODO: Need to implement this functionality.

        override func encodeRestorableState(with coder: NSCoder) {
            P("Encode restorable state")
        }

        override func decodeRestorableState(with coder: NSCoder) {
            P("Decode restorable state")
        }
    }


    extension Notification.Name {
        static let didUndoableAction = Notification.Name("didUndoableAction")
    }



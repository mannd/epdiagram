    //
    //  ViewController.swift
    //  EP Diagram
    //
    //  Created by David Mann on 4/29/19.
    //  Copyright © 2019 EP Studios. All rights reserved.
    //

    import UIKit

    final class ViewController: UIViewController {
        @IBOutlet var imageScrollView: UIScrollView!
        @IBOutlet var imageView: UIImageView!
        @IBOutlet var ladderView: LadderView!
        @IBOutlet var cursorView: CursorView!

        var separatorView: SeparatorView?
        var undoButton: UIBarButtonItem = UIBarButtonItem()
        var redoButton: UIBarButtonItem = UIBarButtonItem()
        
        // This margin is used for all the views.  As ECGs are always read from left
        // to right, there is no reason to reverse this.
        let leftMargin: CGFloat = 30

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
                UIView.setAnimationsEnabled(false) // Mac transitions look better without animation.
            }

            // Distinguish the two views using slightly different background colors.
            if #available(iOS 13.0, *) {
                imageScrollView.backgroundColor = UIColor.secondarySystemBackground
                ladderView.backgroundColor = UIColor.tertiarySystemBackground
            } else {
                imageScrollView.backgroundColor = UIColor.lightGray
                ladderView.backgroundColor = UIColor.white
            }

            // Ensure there is a space for labels at the left margin.
            ladderView.leftMargin = leftMargin
            cursorView.leftMargin = leftMargin

            setMaxCursorPositionY()

            separatorView = HorizontalSeparatorView.addSeparatorBetweenViews(separatorType: .horizontal, primaryView: imageScrollView, secondaryView: ladderView, parentView: self.view)

            let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
            singleTapRecognizer.numberOfTapsRequired = 1
            imageScrollView.addGestureRecognizer(singleTapRecognizer)

            if #available(iOS 13.0, *) {
                let interaction = UIContextMenuInteraction(delegate: ladderView)
                ladderView.addInteraction(interaction)
            }
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
            let toolbar = navigationController?.toolbar
            let calibrateTitle = L("Calibrate", comment: "calibrate button label title")
            let selectTitle = L("Select", comment: "select button label title")
            let undoTitle = L("Undo")
            let redoTitle = L("Redo")
            let calibrateButton = UIBarButtonItem(title: calibrateTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(calibrate))
            let selectButton = UIBarButtonItem(title: selectTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(selectMarks))
            undoButton = UIBarButtonItem(title: undoTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(undo))
            redoButton = UIBarButtonItem(title: redoTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(redo))
            toolbar?.items = [calibrateButton, selectButton, undoButton, redoButton]
            navigationController?.setToolbarHidden(false, animated: false)
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
                ladderView.unhighlightMarks()
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

        private func setViewsNeedDisplay() {
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

    // MARK: - Scrolling and zooming
    extension ViewController: UIScrollViewDelegate {


        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            if scrollView == imageScrollView {
                return imageView
            }
            else {
                return nil
            }
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if scrollView == imageScrollView {
                P("scrollViewDidScroll")
                scrollViewAdjustViews(scrollView)
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            if scrollView == imageScrollView {
                scrollFinished()
            }
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if scrollView == imageScrollView && !decelerate {
                scrollFinished()
            }
        }

        fileprivate func scrollFinished() {
            P("scroll finished")
        }

        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            P("scrollViewDidEndZooming")
            scrollViewAdjustViews(scrollView)
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            P("scrollViewDidZoom")
        }

        private func scrollViewAdjustViews(_ scrollView: UIScrollView) {
            ladderView.offsetX = scrollView.contentOffset.x
            cursorView.offsetX = scrollView.contentOffset.x
            cursorView.scale = scrollView.zoomScale
            ladderView.scale = scrollView.zoomScale
            setViewsNeedDisplay()
        }
    }

    extension Notification.Name {
        static let didUndoableAction = Notification.Name("didUndoableAction")
    }

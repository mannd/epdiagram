    //
    //  ViewController.swift
    //  EP Diagram
    //
    //  Created by David Mann on 4/29/19.
    //  Copyright © 2019 EP Studios. All rights reserved.
    //

    import UIKit

    class ViewController: UIViewController, UIScrollViewDelegate {
        @IBOutlet var imageScrollView: UIScrollView!
        @IBOutlet var imageView: UIImageView!
        @IBOutlet var ladderView: LadderView!
        @IBOutlet var cursorView: CursorView!

        var separatorView: SeparatorView? = nil

        var zoom: CGFloat = 1.0
        var isZooming = false
        // This margin is used for all the views.  As ECGs are always read from left
        // to right, there is no reason to reverse this.
        let leftMargin: CGFloat = 30

        override func viewDidLoad() {
            super.viewDidLoad()
            title = NSLocalizedString("EP Diagram", comment: "app name")
            if Common.isRunningOnMac() {
                navigationController?.setNavigationBarHidden(true, animated: false)
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
            imageScrollView.contentInset = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
            ladderView.leftMargin = leftMargin
            cursorView.leftMargin = leftMargin
            cursorView.ladderViewDelegate = ladderView
            ladderView.cursorViewDelegate = cursorView
            imageScrollView.delegate = self
            ladderView.viewController = self

            // FIXME: This forces ladderView below the toolbar.  Not clear
            // why?  Also note that I changed priority of constraint of
            // imageView = 0.4 to .defaultLow (was .required) superview and changed the superview to include
            // the safe areas.
            separatorView = HorizontalSeparatorView.addSeparatorBetweenViews(separatorType: .horizontal, primaryView: imageScrollView, secondaryView: ladderView, parentView: self.view)

            let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
            singleTapRecognizer.numberOfTapsRequired = 1
            imageScrollView.addGestureRecognizer(singleTapRecognizer)
        }

        override func viewDidAppear(_ animated: Bool) {
            // This centers image, as opposed to starting with it at the upper left
            // hand corner of the screen.
            let newContentOffsetX = (imageScrollView.contentSize.width/2) - (imageScrollView.bounds.size.width/2);
            imageScrollView.contentOffset = CGPoint(x: newContentOffsetX, y: 0)
            cursorView.setNeedsDisplay()
            ladderView.setNeedsDisplay()
            // Set up toolbar and buttons.
            let toolbar = navigationController?.toolbar
            let calibrateTitle = NSLocalizedString("Calibrate", comment: "calibrate button label title")
            let selectTitle = NSLocalizedString("Select", comment: "select button label title")
            let calibrateButton = UIBarButtonItem(title: calibrateTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(calibrate))
            let selectButton = UIBarButtonItem(title: selectTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(selectMarks))
            // More buttons here.
            toolbar?.items = [calibrateButton, selectButton]
            navigationController?.setToolbarHidden(false, animated: false)

            // Size ladderView after views laid out.
            ladderView.reset()
        }

        // MARK: -  Buttons

        @objc func calibrate() {
           PRINT("calibrate")
        }

        @objc func selectMarks() {
            PRINT("select")
        }

        // MARK: - Touches

        @objc func singleTap(tap: UITapGestureRecognizer) {
            PRINT("Scroll view single tap")
            if !ladderView.hasActiveRegion() {
                ladderView.setActiveRegion(regionNum: 0)
                ladderView.setNeedsDisplay()
            }
            cursorView.unattachMark()
            if cursorView.cursorIsVisible() {
                cursorView.hideCursor(hide: true)
            }
            else {
                let positionX = tap.location(in: imageScrollView).x
                cursorView.putCursor(positionX: positionX)
                let mark = ladderView.addMark(positionX: positionX)
                mark?.anchor = .middle
                cursorView.attachMark(mark: mark)
            }
            cursorView.setNeedsDisplay()
            ladderView.setNeedsDisplay()
        }

        // MARK: - Scrolling and zooming

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            if scrollView == imageScrollView {
                return imageView
            }
            else {
                return nil
            }
        }

        // Functions below fire during scrolling of imageView and at end
        // of scrolling.  Relabeling might best occur at end of scrolling,
        // while redrawing of ladder can be done during scrolling.
        // Note that scrollViewDidScroll is also called while zooming.
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if scrollView == imageScrollView {
                PRINT("didScroll")
                // Only scrolling in the horizontal direction affects ladderView.
                ladderView.offset = scrollView.contentOffset.x
                cursorView.offset = scrollView.contentOffset.x
                cursorView.scale = scrollView.zoomScale
                ladderView.scale = scrollView.zoomScale
                ladderView.setNeedsDisplay()
                cursorView.setNeedsDisplay()
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            if scrollView == imageScrollView {
                PRINT("End decelerating")
                scrollFinished()
            }
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if scrollView == imageScrollView && !decelerate {
                PRINT("End dragging")
                scrollFinished()
            }
        }

        fileprivate func scrollFinished() {
            PRINT("Scroll finished")
        }


        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            isZooming = true
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            PRINT("scrollViewDidEndZooming")
            PRINT("Zoom = \(scale)")
            PRINT("imageView width = \(imageView.frame.width)")
            PRINT("imageScrollView bounds = \(imageScrollView.bounds)")
            PRINT("imageScrollView contentOffset = \(imageScrollView.contentOffset)")
            isZooming = false
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            PRINT("didZoom")
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
                PRINT("Transitioning")
                self.resetViews()
                PRINT("new ladderView height = \(self.ladderView.frame.height)")
            })
        }

        private func resetViews() {
            // Add back in separatorView after rotation.
            separatorView = HorizontalSeparatorView.addSeparatorBetweenViews(separatorType: .horizontal, primaryView: imageScrollView, secondaryView: ladderView, parentView: self.view)
            // TODO: redundant or not?
            self.ladderView.reset()
            self.ladderView.refresh()
            self.ladderView.setNeedsDisplay()
            self.imageView.setNeedsDisplay()
            self.cursorView.setNeedsDisplay()
        }

        // MARK: - Save and restore views

        // TODO: Need to implement this functionality.

        override func encodeRestorableState(with coder: NSCoder) {
            PRINT("Encode restorable state")
        }

        override func decodeRestorableState(with coder: NSCoder) {
            PRINT("Decode restorable state")
        }
    }


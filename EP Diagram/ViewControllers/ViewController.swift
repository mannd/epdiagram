    //
    //  ViewController.swift
    //  EP Diagram
    //
    //  Created by David Mann on 4/29/19.
    //  Copyright © 2019 EP Studios. All rights reserved.
    //

    import UIKit

    class ViewController: UIViewController {
        @IBOutlet var imageScrollView: UIScrollView!
        @IBOutlet var imageView: UIImageView!
        @IBOutlet var ladderView: LadderView!
        @IBOutlet var cursorView: CursorView!

        var separatorView: SeparatorView? = nil
        
        // This margin is used for all the views.  As ECGs are always read from left
        // to right, there is no reason to reverse this.
        let leftMargin: CGFloat = 30

        override func viewDidLoad() {
            super.viewDidLoad()

            // Transitions on mac look better without animation.
            UIView.setAnimationsEnabled(!Common.isRunningOnMac())
            
            title = L("EP Diagram", comment: "app name")
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

            separatorView = HorizontalSeparatorView.addSeparatorBetweenViews(separatorType: .horizontal, primaryView: imageScrollView, secondaryView: ladderView, parentView: self.view)

            let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
            singleTapRecognizer.numberOfTapsRequired = 1
            imageScrollView.addGestureRecognizer(singleTapRecognizer)

            if #available(iOS 13.0, *) {
                let interaction = UIContextMenuInteraction(delegate: ladderView)
                ladderView.addInteraction(interaction)
            }
        }

        override func viewDidAppear(_ animated: Bool) {
            centerImage()
            cursorView.setNeedsDisplay()
            ladderView.setNeedsDisplay()
            // Set up toolbar and buttons.
            let toolbar = navigationController?.toolbar
            let calibrateTitle = L("Calibrate", comment: "calibrate button label title")
            let selectTitle = L("Select", comment: "select button label title")
            let calibrateButton = UIBarButtonItem(title: calibrateTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(calibrate))
            let selectButton = UIBarButtonItem(title: selectTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(selectMarks))
            // More buttons here.
            toolbar?.items = [calibrateButton, selectButton]
            navigationController?.setToolbarHidden(false, animated: false)

            resetViews()
        }

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

        // MARK: - Touches

        @objc func singleTap(tap: UITapGestureRecognizer) {
            if !ladderView.hasActiveRegion() {
                ladderView.setActiveRegion(regionNum: 0)
            }
            cursorView.unattachAttachedMark()
            if cursorView.cursorIsVisible() {
                cursorView.hideCursor(true)
            }
            else {
                // By getting x in imageScrollView, offset doesn't apply, though zoom does.  See CursorView.putCursor().
                let positionX = tap.location(in: imageScrollView).x
                cursorView.putCursor(screenPositionX: positionX)
                cursorView.hideCursor(false)
                cursorView.attachMark(screenPositionX: positionX)
            }
            cursorView.setNeedsDisplay()
            ladderView.setNeedsDisplay()
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

        private func resetViews() {
            // Add back in separatorView after rotation.
            separatorView = HorizontalSeparatorView.addSeparatorBetweenViews(separatorType: .horizontal, primaryView: imageScrollView, secondaryView: ladderView, parentView: self.view)
            self.ladderView.resetSize()
            // FIXME: save and restore scrollview offset so it is maintained with rotation.
            self.ladderView.setNeedsDisplay()
            self.imageView.setNeedsDisplay()
            self.cursorView.setNeedsDisplay()
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

        // Functions below fire during scrolling of imageView and at end
        // of scrolling.  Relabeling might best occur at end of scrolling,
        // while redrawing of ladder can be done during scrolling.
        // Note that scrollViewDidScroll is also called while zooming.
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if scrollView == imageScrollView {
                P("didScroll")
                // Only scrolling in the horizontal direction affects ladderView.
                ladderView.offsetX = scrollView.contentOffset.x
                cursorView.offsetX = scrollView.contentOffset.x
                cursorView.scale = scrollView.zoomScale
                ladderView.scale = scrollView.zoomScale
                ladderView.setNeedsDisplay()
                cursorView.setNeedsDisplay()
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            if scrollView == imageScrollView {
                P("End decelerating")
                scrollFinished()
            }
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if scrollView == imageScrollView && !decelerate {
                P("End dragging")
                scrollFinished()
            }
        }

        fileprivate func scrollFinished() {
            P("Scroll finished")
        }

        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            P("scrollViewWillBeginZooming")
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            P("scrollViewDidEndZooming")
            //            P("Zoom = \(scale)")
            //            P("imageView width = \(imageView.frame.width)")
            //            P("imageScrollView bounds = \(imageScrollView.bounds)")
            //            P("imageScrollView contentOffset = \(imageScrollView.contentOffset)")
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            P("didZoom")
        }
    }

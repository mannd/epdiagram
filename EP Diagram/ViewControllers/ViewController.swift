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

        var zoom: CGFloat = 1.0
        var isZooming = false
        let leftMargin: CGFloat = 30

        override func viewDidLoad() {
            super.viewDidLoad()
            title = NSLocalizedString("EP Diagram", comment: "app name")
            // Ensure there is a space for labels at the left margin.
            imageScrollView.contentInset = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
            // Distinguish the two views using slightly different background colors.
            if #available(iOS 13.0, *) {
                imageScrollView.backgroundColor = UIColor.secondarySystemBackground
                ladderView.backgroundColor = UIColor.tertiarySystemBackground
            } else {
                imageScrollView.backgroundColor = UIColor.lightGray
                ladderView.backgroundColor = UIColor.white
            }
            ladderView.leftMargin = leftMargin
            cursorView.leftMargin = leftMargin
            cursorView.ladderViewDelegate = ladderView
            ladderView.cursorViewDelegate = cursorView
            imageScrollView.delegate = self

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
            let positionX = tap.location(in: imageScrollView).x
            cursorView.putCursor(positionX: positionX)
            let mark = ladderView.addMark(positionX: positionX)
            mark?.anchor = .middle
            cursorView.attachMark(mark: mark)
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
            coordinator.animate(alongsideTransition: nil, completion: {
                _ in
                PRINT("Transitioning")
                self.resetViews()
            })
        }

        private func resetViews() {
            self.ladderView.reset()
            self.ladderView.setNeedsDisplay()
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


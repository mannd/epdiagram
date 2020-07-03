//
//  ViewController.swift
//  EP Diagram
//
//  Created by David Mann on 4/29/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import SwiftUI
import os.log

final class ViewController: UIViewController {

    @IBOutlet var _constraintHamburgerWidth: NSLayoutConstraint!
    @IBOutlet var _constraintHamburgerLeft: NSLayoutConstraint!
    @IBOutlet var imageScrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var ladderView: LadderView!
    @IBOutlet var cursorView: CursorView!
    @IBOutlet var blackView: BlackView!

    // We get this view via its embed segue!  See prepareForSegue().
    var hamburgerTableViewController: HamburgerTableViewController?

    // This margin is used for all the views.  As ECGs are always read from left
    // to right, there is no reason to reverse this.
    // TODO: Possibly change this to property of ladder, since it might depend on label width (# of chars)?
    let leftMargin: CGFloat = 30
    var scale: CGFloat = 1.0

    internal var separatorView: SeparatorView?
    private var undoButton: UIBarButtonItem = UIBarButtonItem()
    private var redoButton: UIBarButtonItem = UIBarButtonItem()
    private var mainMenuButtons: [UIBarButtonItem]?
    private var selectMenuButtons: [UIBarButtonItem]?
    private var linkMenuButtons: [UIBarButtonItem]?
    internal var hamburgerMenuIsOpen = false

    // PDF and launch from URL stuff
    var pdfRef: CGPDFDocument?
    var launchFromURL: Bool = false
    var launchURL: URL?
    var pageNumber: Int = 1

    internal var _imageIsLocked: Bool = false
    internal var _ladderIsLocked: Bool = false
    internal let _maxBlackAlpha: CGFloat = 0.4

    var diagramFilenames: [String] = []
    var diagram: Diagram?
    var fileOpSuccessfullFlag: Bool = false {
        didSet {
            P("fileOpSuccessfulFlag = \(fileOpSuccessfullFlag)")
        }
    }

    var preferences: Preferences = Preferences()
    
    override func viewDidLoad() {
        os_log("viewDidLoad() - ViewController", log: OSLog.viewCycle, type: .info)
        super.viewDidLoad()

        // These 2 views are guaranteed to exist, so the delegates are IUOs.
        cursorView.ladderViewDelegate = ladderView
        ladderView.cursorViewDelegate = cursorView
        imageScrollView.delegate = self

        // FIXME: Not clear if code below is needed here or in EP Calipers.  App opens external PDF files without it.
        //            if launchFromURL {
        //                launchFromURL = false
        //                if let launchURL = launchURL {
        //                    openURL(url: launchURL)
        //                }
        //            }

        title = L("EP Diagram", comment: "app name")

        if Common.isRunningOnMac() {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
        UIView.setAnimationsEnabled(true)

        // Distinguish the two views using slightly different background colors.
        imageScrollView.backgroundColor = UIColor.secondarySystemBackground
        ladderView.backgroundColor = UIColor.tertiarySystemBackground

        imageScrollView.maximumZoomScale = 7.0
        // FIXME: zoom < 1.0 makes truncates ladder.
        //imageScrollView.minimumZoomScale = 0.25
        imageScrollView.minimumZoomScale = 1.0

        blackView.delegate = self
        blackView.alpha = 0.0
        constraintHamburgerLeft.constant = -self._constraintHamburgerWidth.constant;

        // Ensure there is a space for labels at the left margin.
        ladderView.leftMargin = leftMargin
        cursorView.leftMargin = leftMargin

        setMaxCursorPositionY()
        cursorView.caliperMaxY = imageScrollView.frame.height

        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        imageScrollView.addGestureRecognizer(singleTapRecognizer)

        let interaction = UIContextMenuInteraction(delegate: ladderView)
        ladderView.addInteraction(interaction)

        navigationItem.setLeftBarButton(UIBarButtonItem(image: UIImage(named: "hamburger"), style: .plain, target: self, action: #selector(toggleHamburgerMenu)), animated: true)
        let ladderButton = UIBarButtonItem(image: UIImage(named: "ladder"), style: .plain, target: self, action: #selector(selectLadder))
        navigationItem.rightBarButtonItem = ladderButton

        if diagram == nil {
            P("restoring default diagram")
            diagram = getDefaultDiagram()
        }
        guard let diagram = diagram else {
            fatalError("Could not find default diagram!")
        }
        imageView.image = diagram.image
        ladderView.ladder = diagram.ladder
    }

    func getDefaultDiagram() -> Diagram {
        return Diagram(name: nil, image: UIImage(named: "SampleECG")!, ladder: Ladder.defaultLadder())
    }

    @objc func onDidUndoableAction(_ notification: Notification) {
        if notification.name == .didUndoableAction {
            updateUndoRedoButtons()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        os_log("viewDidAppear() - ViewController", log: OSLog.viewCycle, type: .info)
        assertDelegatesNonNil()
        // Need to set this here, after view draw, or Mac malpositions cursor at start of app.
        imageScrollView.contentInset = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
        showMainMenu()
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUndoableAction(_:)), name: .didUndoableAction, object: nil)
        updateUndoRedoButtons()
        loadUserDefaults()
        resetViews()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .didUndoableAction, object: nil)
    }

    // Crash program at compile time if IUO delegates are nil.
    private func assertDelegatesNonNil() {
        assert(cursorView.ladderViewDelegate != nil && ladderView.cursorViewDelegate != nil, "LadderViewDelegate and/or CursorViewDelegate are nil")
    }

    func loadUserDefaults() {
        os_log("loadUserDefaults() - ViewController", log: .action, type: .info)
        preferences.retrieve()
        P(">>>>> preferences.lineWidth = \(preferences.lineWidth)")
        ladderView.lineWidth = CGFloat(preferences.lineWidth)
        ladderView.showBlock = preferences.showBlock
        ladderView.showImpulseOrigin = preferences.showImpulseOrigin
        P(">>>>> ladderView.lineWidth = \(ladderView.lineWidth)")
    }

    private func showMainMenu() {
        if mainMenuButtons == nil {
            let calibrateTitle = L("Calibrate", comment: "calibrate button label title")
            let selectTitle = L("Select", comment: "select button label title")
            let linkTitle = L("Link", comment: "link button label title")
            let calibrateButton = UIBarButtonItem(title: calibrateTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(calibrate))
            let selectButton = UIBarButtonItem(title: selectTitle, style: .plain, target: self, action: #selector(selectMarks))
            let linkButton = UIBarButtonItem(title: linkTitle, style: .plain, target: self, action: #selector(linkMarks))
            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            undoButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(undo))
            redoButton = UIBarButtonItem(barButtonSystemItem: .redo, target: self, action: #selector(redo))
            mainMenuButtons = [calibrateButton, spacer, selectButton, spacer, linkButton, spacer, undoButton, spacer, redoButton]
        }
        // Note: set toolbar items this way, not directly (i.e. toolbar.items = something).
        setToolbarItems(mainMenuButtons, animated: false)
        navigationController?.setToolbarHidden(false, animated: false)
    }

    private func showSelectMenu() {
        if selectMenuButtons == nil {
            let textLabelText = L("Tap marks to select")
            let textLabel = UILabel()
            textLabel.text = textLabelText
            let textLabelButton = UIBarButtonItem(customView: textLabel)
            let copyTitle = L("Copy", comment: "copy mark button label title")
            let copyButton = UIBarButtonItem(title: copyTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(copyMarks))
            let cancelTitle = L("Done")
            let cancelButton = UIBarButtonItem(title: cancelTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancelSelect))
            selectMenuButtons = [textLabelButton, copyButton, cancelButton]
        }
        setToolbarItems(selectMenuButtons, animated: false)
        navigationController?.setToolbarHidden(false, animated: false)
    }

    private func showLinkMenu() {
        if linkMenuButtons == nil {
            let textLabelText = L("Tap pairs of marks to link them")
            let textLabel = UILabel()
            textLabel.text = textLabelText
            let textLabelButton = UIBarButtonItem(customView: textLabel)
            let cancelTitle = L("Done")
            let cancelButton = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(cancelLink))
            linkMenuButtons = [textLabelButton, cancelButton]
        }
        setToolbarItems(linkMenuButtons, animated: false)
        navigationController?.setToolbarHidden(false, animated: false)
    }

    @objc func selectLadder() {
        os_log("selectLadder()", log: .action, type: .info)
        performSegue(withIdentifier: "selectLadderSegue", sender: self)
        
    }

    @objc func editDiagram() {
        os_log("editDiagram()", log: OSLog.action, type: .info)
        let alert = UIAlertController(title: L("Edit Diagram"), message: L("Create new diagram or edit this one"), preferredStyle: .actionSheet)
        let newAction = UIAlertAction(title: L("Create new diagram"), style: .default, handler: nil)
        let duplicateAction = UIAlertAction(title: L("Duplicate this diagram"), style: .default, handler: nil)
        let editAction = UIAlertAction(title: L("Edit this diagram"), style: .default, handler: editLadder)
        let cancelAction = UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil)
        alert.addAction(newAction)
        alert.addAction(duplicateAction)
        alert.addAction(editAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

    @objc func editLadder(action: UIAlertAction) {
        os_log("editLadder(action:)", log: OSLog.action, type: .info)
        performSegue(withIdentifier: "EditLadderSegue", sender: self)
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
        os_log("calibrate()", log: OSLog.action, type: .info)
        // Hide regular cursor.
        cursorView.doCalibration()
        // assuming now all calibration is 1000 msec
//        let calibrationValue: CGFloat = 1000
//        var calibration = Calibration()
//        calibration.originalZoom = imageScrollView.zoomScale
//        calibration.currentZoom = calibration.originalZoom
//        // replace this with number obtained from cursor distance apart
//        let dummy: CGFloat = 50
//        let measuredDistance = dummy
//        calibration.originalCalFactor = calibrationValue / measuredDistance
//        calibration.isCalibrated = true
//        ladderView.calibration = calibration
    }

    @objc func selectMarks() {
        os_log("selectMarks()", log: OSLog.action, type: .info)
        showSelectMenu()
        ladderView.selectMarkMode = true
    }

    @objc func linkMarks() {
        os_log("linkMarks()", log: OSLog.action, type: .info)
        cursorView.hideCursor(true)
        ladderView.unhighlightAllMarks()
        setViewsNeedDisplay()
        showLinkMenu()
        ladderView.linkMarkMode = true
        cursorView.allowTaps = false
        // Tap two marks and automatically generate a link between them.  Tap on and then the region in between and generate a blocked link.  Do this by setting link mode in the ladder view and have the ladder view handle the single taps.
    }

    @objc func copyMarks() {
        os_log("copyMarks()", log: OSLog.action, type: .info)
    }

    @objc func cancelSelect() {
        os_log("cancelSelect()", log: OSLog.action, type: .info)
        showMainMenu()
        ladderView.selectMarkMode = false
        ladderView.unhighlightAllMarks()
        ladderView.unselectAllMarks()
        ladderView.setNeedsDisplay()
    }

    @objc func cancelLink() {
        os_log("cancelLink action", log: OSLog.action, type: .info)
        showMainMenu()
        ladderView.linkMarkMode = false
        cursorView.allowTaps = true
        ladderView.unhighlightAllMarks()
        ladderView.setNeedsDisplay()
    }

    @objc func undo() {
        os_log("undo action", log: OSLog.action, type: .info)
        if self.undoManager?.canUndo ?? false {
            self.undoManager?.undo()
            ladderView.setNeedsDisplay()
        }
    }

    @objc func redo() {
        os_log("redo action", log: OSLog.action, type: .info)
        if self.undoManager?.canRedo ?? false {
            self.undoManager?.redo()
            ladderView.setNeedsDisplay()
        }
    }

    func updateUndoRedoButtons() {
        // DispatchQueue here forces UI to finish up its tasks before performing below on the main thread.
        // If not used, undoManager.canUndo/Redo is not updated before this is called.
        DispatchQueue.main.async {
            self.undoButton.isEnabled = self.undoManager?.canUndo ?? false
            self.redoButton.isEnabled = self.undoManager?.canRedo ?? false
        }
    }

    // MARK: - Touches

    @objc func singleTap(tap: UITapGestureRecognizer) {
        os_log("singleTap - ViewController", log: OSLog.touches, type: .info)
        guard cursorView.allowTaps else { return }
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
            cursorView.addMarkWithAttachedCursor(position: position)
        }
        setViewsNeedDisplay()
    }

    // MARK: - Handle PDFs, URLs at app startup

    func openURL(url: URL) {
        os_log("openURL action", log: OSLog.action, type: .info)
        // self.resetImage
        let ext = url.pathExtension.uppercased()
        if ext != "PDF" {
            // self.enablePageButtons = false
            imageView.image = UIImage(contentsOfFile: url.path)
        }
        else {
            // self.numberOfPages = 0
            let urlPath = url.path as NSString
            let tmpPDFRef: CGPDFDocument? = getPDFDocumentRef(urlPath.utf8String)
            if tmpPDFRef == nil {
                return
            }
            // self.clearPDF
            pdfRef = tmpPDFRef
            // self.numberOfPages = (int)CGPDFDocumentGetNumberOfPages(pdfRef)
            // always start with page number 1
            self.pageNumber = 1
            // enablePageButtons = (numberOfPages > 1)
            openPDFPage(pdfRef, atPage: pageNumber)
        }
        //            [self.imageView setHidden:NO];
        //            [self.scrollView setZoomScale:1.0f];
        //            [self clearCalibration];
        //            [self selectMainToolbar];
    }

    private func getPDFDocumentRef(_ fileName: UnsafePointer<Int8>?) -> CGPDFDocument? {
        let path: CFString?
        let url: CFURL?
        var document: CGPDFDocument? = nil

        path = CFStringCreateWithCString(nil, fileName, CFStringBuiltInEncodings.UTF8.rawValue)
        url = CFURLCreateWithFileSystemPath(nil, path, CFURLPathStyle.cfurlposixPathStyle, false)
        //CFRelease not needed in Swift.
        if let url = url {
            document = CGPDFDocument(url)
        }
        return document
    }

    private func openPDFPage(_ documentRef: CGPDFDocument?, atPage pageNum: Int) {
        guard let documentRef = documentRef else { return }
        let page: CGPDFPage? = getPDFPage(documentRef, pageNumber: pageNum)
        if let page = page {
            let sourceRect: CGRect = page.getBoxRect(.mediaBox)
            let scaleFactor: CGFloat = 5.0
            //                let sourceRectSize = CGSize(width: sourceRect.size.width, height: sourceRect.size.height)
            let sourceRectSize = sourceRect.size
            UIGraphicsBeginImageContextWithOptions(sourceRectSize, false, scaleFactor)
            let currentContext = UIGraphicsGetCurrentContext()
            // ensure transparent PDFs have white background in dark mode.
            currentContext?.setFillColor(UIColor.white.cgColor)
            currentContext?.fill(sourceRect)
            currentContext?.translateBy(x: 0, y: sourceRectSize.height)
            currentContext?.scaleBy(x: 1.0, y: -1.0)
            currentContext?.drawPDFPage(page)
            let image: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
            if image != nil {
                imageView.image = image
            }
            UIGraphicsEndImageContext()
        }
    }

    private func getPDFPage(_ document: CGPDFDocument, pageNumber: Int) -> CGPDFPage? {
        return document.page(at: pageNumber)
    }

    // MARK: - Rotate view

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        os_log("viewWillTransition", log: OSLog.viewCycle, type: .info)
        super.viewWillTransition(to: size, with: coordinator)
        // Remove separatorView when rotating to let original constraints resume.
        // Otherwise, views are not laid out correctly.
        if let separatorView = separatorView {
            // Note separatorView is released when removed from superview.
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
        os_log("resetView() - ViewController", log: .action, type: .info)
        // Add back in separatorView after rotation.
        if (separatorView == nil) {
        separatorView = HorizontalSeparatorView.addSeparatorBetweenViews(separatorType: .horizontal, primaryView: imageScrollView, secondaryView: ladderView, parentView: self.view)
        }
        self.ladderView.resetSize()
        // FIXME: save and restore scrollview offset so it is maintained with rotation.
        self.imageView.setNeedsDisplay()
        setMaxCursorPositionY()
        cursorView.caliperMaxY = imageScrollView.frame.height
        setViewsNeedDisplay()
    }

    func setViewsNeedDisplay() {
        cursorView.setNeedsDisplay()
        ladderView.setNeedsDisplay()
    }

    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HamburgerSegue" {
            hamburgerTableViewController = segue.destination as? HamburgerTableViewController
            hamburgerTableViewController?.delegate = self
        }
    }


    @IBSegueAction func showTemplateEditor(_ coder: NSCoder) -> UIViewController? {
        navigationController?.setToolbarHidden(true, animated: true)
        let ladderTemplates = FileIO.retrieve(FileIO.userTemplateFile, from: .documents, as: [LadderTemplate].self) ?? [LadderTemplate.defaultTemplate(), LadderTemplate.defaultTemplate2()]
        var templateEditor = LadderTemplatesEditor(ladderTemplates: ladderTemplates)
        templateEditor.delegate = self
        let hostingController = UIHostingController(coder: coder, rootView: templateEditor)
        return hostingController
    }
    

    @IBSegueAction func showLadderSelector(_ coder: NSCoder) -> UIViewController? {
        os_log("showLadderSelector")
        navigationController?.setToolbarHidden(true, animated: true)
        // FIXME: This is setup like this just for testing.
        let ladderTemplates = FileIO.retrieve(FileIO.userTemplateFile, from: .documents, as: [LadderTemplate].self) ?? [LadderTemplate.defaultTemplate(), LadderTemplate.defaultTemplate2()]
        let index = ladderTemplates.firstIndex(of: ladderView.ladder.template)
        var ladderSelector = LadderSelector(ladderTemplates: ladderTemplates, selectedIndex: index ?? 0)
        ladderSelector.delegate = self
        let hostingController = UIHostingController(coder: coder, rootView: ladderSelector)
        return hostingController
    }


    @IBSegueAction func showDiagramSelector(_ coder: NSCoder) -> UIViewController? {
        os_log("showDiagramSelector() - ViewController", log: OSLog.action, type: .info)
        let diagramSelector = DiagramSelector(names: diagramFilenames, delegate: self)
        let hostingController = UIHostingController(coder: coder, rootView: diagramSelector)
        return hostingController
    }


    @IBSegueAction func showPreferences(_ coder: NSCoder) -> UIViewController? {
        preferences.retrieve()
        var preferencesView = PreferencesView(preferences: preferences)
        preferencesView.delegate = self
        let hostingController = UIHostingController(coder: coder, rootView: preferencesView)
        return hostingController
    }
    
    // MARK: - Save and restore views

    // TODO: Need to implement this functionality.

    override func encodeRestorableState(with coder: NSCoder) {
        os_log("encodeRestorableState(with:) - ViewController", log: .viewCycle, type: .info)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        os_log("decodeRestorableState(with:) - ViewController", log: .viewCycle, type: .info)
    }
}





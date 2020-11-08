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
    let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    internal var separatorView: SeparatorView?
    private var undoButton: UIBarButtonItem = UIBarButtonItem()
    private var redoButton: UIBarButtonItem = UIBarButtonItem()
    private var selectButton: UIBarButtonItem = UIBarButtonItem()
    private var mainMenuButtons: [UIBarButtonItem]?
    private var selectMenuButtons: [UIBarButtonItem]?
    private var linkMenuButtons: [UIBarButtonItem]?
    private var calibrateMenuButtons: [UIBarButtonItem]?

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
    var diagram: Diagram = Diagram.defaultDiagram()

    // reference to calibration is passed to ladderView and cursorView
    var calibration = Calibration()

    var preferences: Preferences = Preferences()

    static let restorationContentOffsetXKey = "restorationContentOffsetXKey"
    static let restorationContentOffsetYKey = "restorationContentOffsetYKey"
    static let restorationZoomKey = "restorationZoomKey"
    static let restorationIsCalibratedKey = "restorationIsCalibrated"
    static let restorationCalFactorKey = "restorationCalFactorKey"
    static let restorationFileNameKey = "restorationFileNameKey"
    var restorationInfo: [AnyHashable: Any]?
    var restorationFileName: String = ""

    // Speed up appearance of image picker by initializing it here.
    let imagePicker: UIImagePickerController = UIImagePickerController()

    override func viewDidLoad() {
        os_log("viewDidLoad() - ViewController", log: OSLog.viewCycle, type: .info)
        super.viewDidLoad()

        let info = self.restorationInfo
        if let info = info {
            for item in info {
                print(item)
            }

        }
        // restore diagram file here
        if let fileName = info?[ViewController.restorationFileNameKey] as? String {
            if let diagram = restoreDiagramFromCache(fileName: fileName) {
                self.diagram = diagram
                // delete cache file here, after user update complete.
                DispatchQueue.main.async {
                    self.deleteCacheFile(fileName: fileName)
                }
            }
        }

        // These 2 views are guaranteed to exist, so the delegates are IUOs.
        cursorView.ladderViewDelegate = ladderView
        ladderView.cursorViewDelegate = cursorView
        imageScrollView.delegate = self

        // These two views hold a reference to calibration.
        cursorView.calibration = calibration
        ladderView.calibration = calibration

        if Common.isRunningOnMac() {
            navigationController?.setNavigationBarHidden(true, animated: false)
            // TODO: Need to convert hamburger menu to regular menu on Mac.
        }
        UIView.setAnimationsEnabled(true)

        // Distinguish the two views using slightly different background colors.
        imageScrollView.backgroundColor = UIColor.secondarySystemBackground
        ladderView.backgroundColor = UIColor.tertiarySystemBackground

        imageScrollView.maximumZoomScale = 7.0
        imageScrollView.minimumZoomScale = 0.25

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

        loadUserDefaults()

        setImageViewImage(with: diagram.image)
        ladderView.ladder = diagram.ladder

//        setTitle()
    }

    func getTitle() -> String {
        guard let name = diagram.name else { return L("EP Diagram", comment: "app name") }
        if Common.isRunningOnMac() || Common.isIPad() {
            return L("EP Diagram - \(name)")
        }
        return name
    }

    func setTitle() {
        title = getTitle()
    }

    func setMode(_ mode: Mode) {
        cursorView.mode = mode
        ladderView.mode = mode
    }

    @objc func onDidUndoableAction(_ notification: Notification) {
        if notification.name == .didUndoableAction {
            updateUndoRedoButtons()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        os_log("viewWillAppear() - ViewController", log: .viewCycle, type: .info)
        super.viewWillAppear(animated)

    }

    override func viewDidAppear(_ animated: Bool) {
        os_log("viewDidAppear() - ViewController", log: OSLog.viewCycle, type: .info)
        super.viewDidAppear(animated)
        // See https://github.com/mattneub/Programming-iOS-Book-Examples/blob/master/bk2ch06p357StateSaveAndRestoreWithNSUserActivity/ch19p626pageController/SceneDelegate.swift
        var restorationContentOffset = CGPoint()
        if let contentOffsetX = restorationInfo?[ViewController.restorationContentOffsetXKey] {
            restorationContentOffset.x = contentOffsetX as? CGFloat ?? 0
        }
        if let contentOffsetY = restorationInfo?[ViewController.restorationContentOffsetYKey] {
            restorationContentOffset.y = contentOffsetY as? CGFloat ?? 0
        }
        print("restorationContentOffset = \(restorationContentOffset)")
        imageScrollView.setContentOffset(restorationContentOffset, animated: true)
        if let zoomScale = restorationInfo?[ViewController.restorationZoomKey] {
            imageScrollView.zoomScale = zoomScale as? CGFloat ?? 1
        }
        if let isCalibrated = restorationInfo?[ViewController.restorationIsCalibratedKey] {
            cursorView.setIsCalibrated(isCalibrated as? Bool ?? false)
        }
        if let calFactor = restorationInfo?[ViewController.restorationCalFactorKey] {
            cursorView.calFactor = calFactor as? CGFloat ?? 1.0
        }
        self.restorationInfo = nil
        self.userActivity = self.view.window?.windowScene?.userActivity

        assertDelegatesNonNil()
        // Need to set this here, after view draw, or Mac malpositions cursor at start of app.
        imageScrollView.contentInset = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
        showMainMenu()
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUndoableAction(_:)), name: .didUndoableAction, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePreferences), name: .preferencesChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIScene.didEnterBackgroundNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(enterForeground), name: UIScene.willEnterForegroundNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(willConnect), name: UIScene.willConnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnect), name: UIScene.didDisconnectNotification, object: nil)
        updateUndoRedoButtons()
        resetViews()
    }

    // We only want to use the restorationInfo once when view controller first appears.
    var didFirstLayout = false
    override func viewDidLayoutSubviews() {
        os_log("viewDidLayoutSubviews() - ViewController", log: .viewCycle, type: .info)
        if didFirstLayout { return }
        didFirstLayout = true
        let info = restorationInfo
        if let inHelp = info?[HelpViewController.inHelpKey] as? Bool, inHelp {
            performShowHelpSegue()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .didUndoableAction, object: nil)
        NotificationCenter.default.removeObserver(self, name: .preferencesChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIScene.didEnterBackgroundNotification, object: nil)
//        NotificationCenter.default.removeObserver(self, name: UIScene.willEnterForegroundNotification, object: nil)
//        NotificationCenter.default.removeObserver(self, name: UIScene.willConnectNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIScene.didDisconnectNotification, object: nil)
    }

    override
    func updateUserActivityState(_ activity: NSUserActivity) {
        os_log("updateUserActivityState called")
        super.updateUserActivityState(activity)
        // FIXME: make sure old cache is deleted
        print("+++ restorationFileName: \(restorationFileName)")
        listCacheFiles()
        restorationFileName = UUID().uuidString
        print("updateUserActivityState contentOffset = \(imageScrollView.contentOffset)")
        let info: [AnyHashable: Any] = [
            ViewController.restorationFileNameKey: restorationFileName,
            ViewController.restorationContentOffsetXKey: imageScrollView.contentOffset.x,
            ViewController.restorationContentOffsetYKey: imageScrollView.contentOffset.y,
            ViewController.restorationZoomKey: imageScrollView.zoomScale,
            ViewController.restorationIsCalibratedKey: cursorView.isCalibrated(),
            ViewController.restorationCalFactorKey: cursorView.calFactor
        ]
        activity.addUserInfoEntries(from: info)
    }

    private func listCacheFiles() {
        guard let restorationURL = FileIO.getURL(for: .cache) else { return }
        if let fileURLs = try? FileManager.default.contentsOfDirectory(at: restorationURL, includingPropertiesForKeys: nil), fileURLs.count > 0 {
            for file in fileURLs {
                let fileName = file.path
                print("***** cache file paths = \(fileName)")
            }
        } else {
            print("***** no cache files found")
        }
    }

    @objc func didEnterBackground() {
        os_log("didEnterBackground()", log: .action, type: .info)
        saveDiagramToCache(fileName: restorationFileName)
    }

    @objc func didDisconnect() {
        os_log("didDisconnect()", log: .action, type: .info)
    }

    // FIXME: have separate cache dir and delete all in it, otherwise if program terminated we may leave cache files.
    func deleteCacheFile(fileName name: String) {
        os_log("deleteCacheFile(fileName:)", log: .action, type: .info)
        guard let restorationURL = FileIO.getURL(for: .cache) else { return }
        print("restorationURL = \(restorationURL.path)")
        do {
            let nameURL = restorationURL.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: nameURL.path) {
                try FileManager.default.removeItem(at: nameURL)
            }
        } catch {
            os_log("deleteCacheFile(fileName:) error %s", log: .errors, type: .error, error.localizedDescription)
        }
    }

    // FIXME: Consider using Bookmarks instead of storing files. https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html#//apple_ref/doc/uid/TP40010672-CH3
    func saveDiagramToCache(fileName name: String) {
        os_log("saveDiagramToCache(fileName:)", log: .action, type: .info)
        DispatchQueue.global().async { [self] in
            guard let restorationURL = FileIO.getURL(for: .cache) else { return }
            print(">>>> restorationURL = \(restorationURL)")
            do {
                let nameURL = restorationURL.appendingPathComponent(name)
                if !FileManager.default.fileExists(atPath: nameURL.path) {
                    try FileManager.default.createDirectory(at: nameURL,
                                                            withIntermediateDirectories: true,
                                                            attributes: nil)
                }
                print(">>>>>>>>>> \(nameURL.path)")
                if let image = diagram.image {
                    let imageData = image.pngData()
                    let imageURL = nameURL.appendingPathComponent(FileIO.imageFilename, isDirectory: false)
                    try imageData?.write(to: imageURL)
                }
                let encoder = JSONEncoder()
                let diagramData = try encoder.encode(diagram.diagramData)
                let ladderURL = nameURL.appendingPathComponent(FileIO.ladderFilename, isDirectory: false)
                FileManager.default.createFile(atPath: ladderURL.path, contents: diagramData, attributes: nil)
            } catch {
                os_log("saveDiagramToCache(fileName:) error %s", log: .errors, type: .error, error.localizedDescription)
            }
        }
    }

    func restoreDiagramFromCache(fileName name: String) -> Diagram? {
        guard let restorationURL = FileIO.getURL(for: .cache) else { return nil }
        do {
            let nameURL = restorationURL.appendingPathComponent(name)
            if !FileManager.default.fileExists(atPath: nameURL.path) {
                return nil
            }
            return try Diagram.retrieve(name: name, url: nameURL)
        } catch {
            os_log("restoreDiagramToCache(fileName:) error %s", log: .errors, type: .error, error.localizedDescription)
            return nil
        }
    }

    // Crash program at compile time if IUO delegates are nil.
    private func assertDelegatesNonNil() {
        assert(cursorView.ladderViewDelegate != nil && ladderView.cursorViewDelegate != nil, "LadderViewDelegate and/or CursorViewDelegate are nil")
    }

    func loadUserDefaults() {
        os_log("loadUserDefaults() - ViewController", log: .action, type: .info)
        preferences.retrieve()
        ladderView.lineWidth = CGFloat(preferences.lineWidth)
        ladderView.showBlock = preferences.showBlock
        ladderView.showImpulseOrigin = preferences.showImpulseOrigin
        ladderView.showIntervals = preferences.showIntervals
    }

    private func showMainMenu() {
        if mainMenuButtons == nil {
            let calibrateTitle = L("Calibrate", comment: "calibrate button label title")
            let selectTitle = L("Select", comment: "select button label title")
            let linkTitle = L("Link", comment: "link button label title")
            let calibrateButton = UIBarButtonItem(title: calibrateTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(calibrate))
            selectButton = UIBarButtonItem(title: selectTitle, style: .plain, target: self, action: #selector(showSelectMarksMenu))
            let linkButton = UIBarButtonItem(title: linkTitle, style: .plain, target: self, action: #selector(linkMarks))
            undoButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(undo))
            redoButton = UIBarButtonItem(barButtonSystemItem: .redo, target: self, action: #selector(redo))
            mainMenuButtons = [calibrateButton, spacer, selectButton, spacer, linkButton, spacer, undoButton, spacer, redoButton]
        }
        // Note: set toolbar items this way, not directly (i.e. toolbar.items = something).
        setToolbarItems(mainMenuButtons, animated: false)
        navigationController?.setToolbarHidden(false, animated: false)
    }

    @objc func showSelectMarksMenu(_: UIAlertAction) {
        if selectMenuButtons == nil {
            let prompt = makePrompt(text: L("Tap marks to select"))
            let cancelTitle = L("Done")
            let cancelButton = UIBarButtonItem(title: cancelTitle, style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancelSelect))
            selectMenuButtons = [prompt, spacer, cancelButton]
        }
        setToolbarItems(selectMenuButtons, animated: false)
        navigationController?.setToolbarHidden(false, animated: false)
        cursorView.cursorIsVisible = false
        ladderView.unhighlightAllMarks()
        setMode(.select)
        setViewsNeedDisplay()
    }

    private func showLinkMenu() {
        if linkMenuButtons == nil {
            let prompt = makePrompt(text: L("Tap pairs of marks to link them"))
            let cancelTitle = L("Done")
            let cancelButton = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(cancelLink))
            linkMenuButtons = [prompt, spacer, cancelButton]
        }
        cursorView.cursorIsVisible = false
        setToolbarItems(linkMenuButtons, animated: false)
        navigationController?.setToolbarHidden(false, animated: false)
    }

    private func showCalibrateMenu() {
        if calibrateMenuButtons == nil {
            let promptButton = makePrompt(text: L("Set caliper to 1000 ms"))
            let setTitle = L("Set")
            let setButton = UIBarButtonItem(title: setTitle, style: .plain, target: self, action: #selector(setCalibration))
            let clearTitle = L("Clear")
            let clearButton = UIBarButtonItem(title:clearTitle, style: .plain, target: self, action: #selector(clearCalibration))
            let cancelTitle = L("Cancel")
            let cancelButton = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(cancelCalibration))
            calibrateMenuButtons = [promptButton, spacer, setButton, clearButton, cancelButton]
        }
        setToolbarItems(calibrateMenuButtons, animated: false)
        navigationController?.setToolbarHidden(false, animated: false)
    }

    private func makePrompt(text: String) -> UIBarButtonItem {
        let prompt = UILabel()
        prompt.text = text
        return UIBarButtonItem(customView: prompt)
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
        showCalibrateMenu()
        cursorView.showCalipers()
    }

    @objc func showSelectAlert() {
        os_log("selectMarks()", log: .action, type: .info)
        cursorView.cursorIsVisible = false
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let selectMarksAction = UIAlertAction(title: L("Select Marks"), style: .default, handler: showSelectMarksMenu)
        let selectZoneAction = UIAlertAction(title: L("Select a Zone"), style: .default, handler: nil)
        let cancelAction = UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil)
        alert.addAction(selectMarksAction)
        alert.addAction(selectZoneAction)
        alert.addAction(cancelAction)
        alert.popoverPresentationController?.barButtonItem = selectButton
        present(alert, animated: true, completion: nil)
    }

    @objc func linkMarks() {
        os_log("linkMarks()", log: OSLog.action, type: .info)
        cursorView.cursorIsVisible = false
        ladderView.unhighlightAllMarks()
        showLinkMenu()
        setMode(.link)
      setViewsNeedDisplay()
//        cursorView.allowTaps = false
        // Tap two marks and automatically generate a link between them.  Tap on and then the region in between and generate a blocked link.  Do this by setting link mode in the ladder view and have the ladder view handle the single taps.
    }

    // FIXME: copy and paste should be long press menu items.
//    @objc func copyMarks() {
//        os_log("copyMarks()", log: OSLog.action, type: .info)
//        showPasteMarksMenu()
//    }
//
//    @objc func showPasteMarksMenu() {
//        os_log("showPasteMarksMenu()", log: .action, type: .info)
//        // "Paste marks: Tap on ladder to paste copied mark(s) Done"
//    }

    @objc func cancelSelect() {
        os_log("cancelSelect()", log: OSLog.action, type: .info)
        showMainMenu()
        setMode(.normal)
        ladderView.unhighlightAllMarks()
        ladderView.unselectAllMarks()
        ladderView.setNeedsDisplay()
    }

    @objc func cancelLink() {
        os_log("cancelLink()", log: OSLog.action, type: .info)
        showMainMenu()
        setMode(.normal)
//        cursorView.allowTaps = true
        ladderView.unhighlightAllMarks()
        ladderView.setNeedsDisplay()
    }

    @objc func setCalibration() {
        os_log("setCalibration()", log: .action, type: .info)
        cursorView.setCalibration(zoom: imageScrollView.zoomScale)
        closeCalibrationMenu()
    }

    @objc func clearCalibration() {
        os_log("clearCalibration()", log: .action, type: .info)
        calibration.reset()
        ladderView.refresh()
//        cursorView.clearCalibration()
        closeCalibrationMenu()
    }

    @objc func cancelCalibration() {
        os_log("cancelCalibration()", log: .action, type: .info)
        closeCalibrationMenu()
    }

    private func closeCalibrationMenu() {
        showMainMenu()
        setMode(.normal)
        setViewsNeedDisplay()
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
        if cursorView.mode == .calibration {
            P("is Calibrating")
            return
        }
        guard cursorView.allowTaps else { return }
        if !ladderView.hasActiveRegion() {
            ladderView.setActiveRegion(regionNum: 0)
        }
        if cursorView.cursorIsVisible {
            ladderView.unattachAttachedMark()
            cursorView.cursorIsVisible = false
            ladderView.unhighlightAllMarks()
        }
        else {
            let position = tap.location(in: imageScrollView)
            cursorView.addMarkWithAttachedCursor(position: position)
        }
        setViewsNeedDisplay()
    }

    // MARK: - Handle PDFs, URLs at app startup

    // FIXME: cache image to unique location in background when loading new image and retain
    // filename, while deleting old image cache.  Use this to restore diagram, since once image is
    // loaded it does not change.
    func openURL(url: URL) {
        os_log("openURL action", log: OSLog.action, type: .info)
        // self.resetImage
        let ext = url.pathExtension.uppercased()
        if ext != "PDF" {
            // self.enablePageButtons = false
            setImageViewImage(with: UIImage(contentsOfFile: url.path))
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
                setImageViewImage(with: image)
            }
            UIGraphicsEndImageContext()
        }
    }

    private func getPDFPage(_ document: CGPDFDocument, pageNumber: Int) -> CGPDFPage? {
        return document.page(at: pageNumber)
    }

    func setImageViewImage(with image: UIImage?) {
        imageView.image = image
        // FIXME: cache new image here if it is not nil.  Erase old cached image first.
//        DispatchQueue.global().async { [self] in
//            guard let restorationURL = FileIO.getURL(for: .cache), restorationFileName.count > 0 else { return }
//            print(">>>> restorationURL = \(restorationURL)")
//            do {
//                let nameURL = restorationURL.appendingPathComponent(restorationFileName)
//                if !FileManager.default.fileExists(atPath: nameURL.path) {
//                    try FileManager.default.createDirectory(at: nameURL,
//                                                            withIntermediateDirectories: true,
//                                                            attributes: nil)
//                }
//                print(">>>>>>>>>> \(nameURL.path)")
//
//                if let image = diagram.image {
//                    let imageData = image.pngData()
//                    let imageURL = nameURL.appendingPathComponent(FileIO.imageFilename, isDirectory: false)
//                    try imageData?.write(to: imageURL)
//                }
////                let encoder = JSONEncoder()
////                let diagramData = try encoder.encode(diagram.diagramData)
////                let ladderURL = nameURL.appendingPathComponent(FileIO.ladderFilename, isDirectory: false)
////                FileManager.default.createFile(atPath: ladderURL.path, contents: diagramData, attributes: nil)
//            } catch {
//                os_log("saveImageViewImage(with:) error %s", log: .errors, type: .error, error.localizedDescription)
//            }
//        }


    }

    // MARK: - Rotate view

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        os_log("viewWillTransition", log: OSLog.viewCycle, type: .info)
        super.viewWillTransition(to: size, with: coordinator)
        // Hide cursor with rotation, to avoid redrawing it.
        cursorView.cursorIsVisible = false
        // Remove separatorView when rotating to let original constraints resume.
        // Otherwise, views are not laid out correctly.
        if let separatorView = separatorView {
            // Note separatorView is released when removed from superview.
            separatorView.removeFromSuperview()
            self.separatorView = nil
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

    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HamburgerSegue" {
            hamburgerTableViewController = segue.destination as? HamburgerTableViewController
            hamburgerTableViewController?.delegate = self
        }
    }

    @IBSegueAction func showTemplateEditor(_ coder: NSCoder) -> UIViewController? {
        navigationController?.setToolbarHidden(true, animated: true)
        // FIXME: Decide how to hande default ladder templates.  Below hard codes 2 defaults if there are no saved defaults.
        // Restore default ladder templates if none saved.
        var ladderTemplates = FileIO.retrieve(FileIO.userTemplateFile, from: .documents, as: [LadderTemplate].self) ?? LadderTemplate.defaultTemplates()
        if ladderTemplates.isEmpty {
            ladderTemplates = LadderTemplate.defaultTemplates()
        }
        var templateEditor = LadderTemplatesEditor(ladderTemplates: ladderTemplates, parentViewTitle: getTitle())
        templateEditor.delegate = self
        let hostingController = UIHostingController(coder: coder, rootView: templateEditor)
        return hostingController
    }

    @IBSegueAction func showLadderSelector(_ coder: NSCoder) -> UIViewController? {
        os_log("showLadderSelector")
        navigationController?.setToolbarHidden(true, animated: true)
        // Use default ladder templates if none saved.
        var ladderTemplates = FileIO.retrieve(FileIO.userTemplateFile, from: .documents, as: [LadderTemplate].self) ?? LadderTemplate.defaultTemplates()
        if ladderTemplates.isEmpty {
            ladderTemplates = LadderTemplate.defaultTemplates()
        }
        let index = ladderTemplates.firstIndex(where: { ladderTemplate in
            ladderTemplate.name == ladderView.ladder.name
        })
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
        let preferencesView = PreferencesView()
        let hostingController = UIHostingController(coder: coder, rootView: preferencesView)
        return hostingController
    }
    
    @IBSegueAction func showSampleSelector(_ coder: NSCoder) -> UIViewController? {
        let sampleDiagrams: [Diagram] = [
            Diagram(name: L("Normal ECG"), image: UIImage(named: "SampleECG")!, description: L("Just a normal ECG")),
            Diagram(name: L("AV Block"), image: UIImage(named: "AVBlock")!, description: L("High grade AV block")),
            Diagram.blankDiagram(name: L("Blank Diagram")),
            // Make this taller than height even with rotation.
            Diagram(name: L("Scrollable Blank Diagram"), image: UIImage.emptyImage(size: CGSize(width: view.frame.size.width * 3, height: max(view.frame.size.height, view.frame.size.width)), color: UIColor.systemTeal), description: L("Wide scrollable blank image"))
            // TODO: add others here.
        ]
        let sampleSelector = SampleSelector(sampleDiagrams: sampleDiagrams, delegate: self)
        let hostingController = UIHostingController(coder: coder, rootView: sampleSelector)
        return hostingController
    }

    func performSelectLadderSegue() {
        performSegue(withIdentifier: "selectLadderSegue", sender: self)
    }

    func performEditLadderSegue() {
        performSegue(withIdentifier: "EditLadderSegue", sender: self)
    }
    
    func performShowDiagramSelectorSegue() {
        performSegue(withIdentifier: "showDiagramSelectorSegue", sender: self)
    }

    func performShowSampleSelectorSegue() {
        performSegue(withIdentifier: "showSampleSelectorSegue", sender: self)
    }

    func performShowHelpSegue() {
        performSegue(withIdentifier: "showHelpSegue", sender: self)
    }

    @IBSegueAction func performShowHelpSegueAction(_ coder: NSCoder) -> HelpViewController? {
        let helpViewController = HelpViewController(coder: coder)
        helpViewController?.restorationInfo = self.restorationInfo
        return helpViewController
    }
    
    func performShowPreferencesSegue() {
        performSegue(withIdentifier: "showPreferencesSegue", sender: self)
    }

    func performShowTemplateEditorSegue() {
        performSegue(withIdentifier: "showTemplateEditorSegue", sender: self)
    }
}





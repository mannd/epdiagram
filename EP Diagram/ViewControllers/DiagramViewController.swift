//
//  DiagramViewController.swift
//  EP Diagram
//
//  Created by David Mann on 4/29/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers
import Photos
import os.log

final class DiagramViewController: UIViewController {
    // View, outlets, constraints
    @IBOutlet var _constraintHamburgerWidth: NSLayoutConstraint!
    @IBOutlet var _constraintHamburgerLeft: NSLayoutConstraint!
    @IBOutlet var imageScrollView: ImageScrollView!
    @IBOutlet var imageView: ImageView!
    @IBOutlet var ladderView: LadderView!
    @IBOutlet var cursorView: CursorView!
    @IBOutlet var blackView: BlackView!
    var hamburgerTableViewController: HamburgerTableViewController? // We get this view via its embed segue!
    var separatorView: SeparatorView?

    // TODO: Possibly change this to property of ladder, since it might depend on label width (# of chars)?
    // This margin is passed to other views.
    let leftMargin: CGFloat = 50

    // Buttons, menus
    private let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    private var undoButton: UIBarButtonItem = UIBarButtonItem()
    private var redoButton: UIBarButtonItem = UIBarButtonItem()
    private var selectButton: UIBarButtonItem = UIBarButtonItem()
    private var mainMenuButtons: [UIBarButtonItem]?
    private var selectMenuButtons: [UIBarButtonItem]?
    private var linkMenuButtons: [UIBarButtonItem]?
    private var calibrateMenuButtons: [UIBarButtonItem]?

    weak var diagramEditorDelegate: DiagramEditorDelegate?
    var currentDocument: DiagramDocument?

    var menuPressLocation: CGPoint?
    var longPressLocationInLadder: LocationInLadder?
    var menuAppeared = false // track when context menu appears

    // PDF and launch from URL stuff
    var pdfRef: CGPDFDocument?
    var launchFromURL: Bool = false
    var launchURL: URL?
    var pageNumber: Int = 1

    // For hambuger menu
    var hamburgerMenuIsOpen = false
    var _imageIsLocked: Bool = false
    var _ladderIsLocked: Bool = false
    let _maxBlackAlpha: CGFloat = 0.4

    var diagram: Diagram = Diagram.blankDiagram() {
        didSet {
            diagramEditorDelegate?.diagramEditorDidUpdateContent(self, diagram: diagram)
        }
    }
    var preferences: Preferences = Preferences()
    // Set by screen delegate
    var restorationInfo: [AnyHashable: Any]?

    // Keys for state restoration
    static let restorationContentOffsetXKey = "restorationContentOffsetXKey"
    static let restorationContentOffsetYKey = "restorationContentOffsetYKey"
    static let restorationZoomKey = "restorationZoomKey"
    static let restorationIsCalibratedKey = "restorationIsCalibrated"
    static let restorationCalFactorKey = "restorationCalFactorKey"
    static let restorationFileNameKey = "restorationFileNameKey"
    static let restorationNeededKey = "restorationNeededKey"
    static let restorationTransformKey = "restorationTranslateKey"
//    static let restorationActiveRegionIndexKey = "restorationActiveRegionIndexKey"
    static let restorationDoRestorationKey = "restorationDoRestorationKey"

    // Speed up appearance of image picker by initializing it here.
    let imagePicker: UIImagePickerController = UIImagePickerController()
    private let maxZoom: CGFloat = 7.0
    private let minZoom: CGFloat = 0.2
    let pdfScaleFactor: CGFloat = 5.0

    // Context menu actions
    lazy var deleteAction = UIAction(title: L("Delete selected mark(s)"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
        self.ladderView.deleteSelectedMarks()
    }
    lazy var deleteAllInRegion = UIAction(title: L("Clear region"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
        self.ladderView.deleteAllInSelectedRegion()
    }
    lazy var deleteAllInLadder = UIAction(title: L("Clear ladder"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
        self.ladderView.deleteAllInLadder()
    }
    lazy var solidAction = UIAction(title: L("Solid")) { action in
        self.ladderView.setSelectedMarksStyle(style: .solid)
    }
    lazy var dashedAction = UIAction(title: L("Dashed")) { action in
        self.ladderView.setSelectedMarksStyle(style: .dashed)
    }
    lazy var dottedAction = UIAction(title: L("Dotted")) { action in
        self.ladderView.setSelectedMarksStyle(style: .dotted)
    }
    lazy var styleMenu = UIMenu(title: L("Style..."), children: [self.solidAction, self.dashedAction, self.dottedAction, self.regionStyleMenu])

    lazy var regionSolidStyleAction = UIAction(title: L("Solid")) { action in
        self.ladderView.setSelectedRegionsStyle(style: .solid)
    }
    lazy var regionDashedStyleAction = UIAction(title: L("Dashed")) { action in
        self.ladderView.setSelectedRegionsStyle(style: .dashed)
    }
    lazy var regionDottedStyleAction = UIAction(title: L("Dotted")) { action in
        self.ladderView.setSelectedRegionsStyle(style: .dotted)
    }
    lazy var regionInheritedStyleAction = UIAction(title: L("Inherited")) { action in
        self.ladderView.setSelectedRegionsStyle(style: .inherited)
    }
    lazy var regionStyleMenu = UIMenu(title: L("Default region style..."), children: [self.regionSolidStyleAction, self.regionDashedStyleAction, self.regionDottedStyleAction, self.regionInheritedStyleAction])

    lazy var slantProximalPivotAction = UIAction(title: L("Slant proximal pivot point")) { action in
        self.showSlantMenu()
    }
    lazy var slantDistalPivotAction = UIAction(title: L("Slant distal pivot point")) { action in

    }
    lazy var slantMenu = UIMenu(title: L("Slant mark(s)..."), children: [self.slantProximalPivotAction, self.slantDistalPivotAction])
    lazy var unlinkAction = UIAction(title: L("Unlink")) { action in
        self.ladderView.ungroupSelectedMarks()
    }
    lazy var straightenToProximalAction = UIAction(title: L("Straighten mark to proximal endpoint")) { action in
        self.ladderView.straightenToProximal()
    }
    lazy var straightenToDistalAction = UIAction(title: L("Straighten mark to distal endpoint")) { action in
        self.ladderView.straightenToDistal()
    }
    lazy var straightenMenu = UIMenu(title: L("Straighten mark(s)..."), children: [self.straightenToDistalAction, self.straightenToProximalAction])

    lazy var rhythmAction = UIAction(title: L("Rhythm")) { action in
        // TODO: implement
    }
    lazy var editLabelAction = UIAction(title: L("Edit label"), image: UIImage(systemName: "pencil")) { action in
        self.editLabel()
    }
    lazy var addRegionAboveAction = UIAction(title: L("Add region above")) { action in

    }
    lazy var addRegionBelowAction = UIAction(title: L("Add region below")) { action in
        
    }
    lazy var addRegionMenu = UIMenu(title: L("Add Region..."), image: UIImage(systemName: "plus"), children: [self.addRegionAboveAction, self.addRegionBelowAction])

    


override func viewDidLoad() {
        os_log("viewDidLoad() - ViewController", log: OSLog.viewCycle, type: .info)
        super.viewDidLoad()

        //showRestorationInfo() // for debugging

        // TODO: customization for mac version
        if isRunningOnMac() {
            //navigationController?.setNavigationBarHidden(true, animated: false)
            // TODO: Need to convert hamburger menu to regular menu on Mac.
        }

        // Setup cursor, ladder and image scroll views.
        // These 2 views are guaranteed to exist, so the delegates are implicitly unwrapped optionals.
        cursorView.ladderViewDelegate = ladderView
        ladderView.cursorViewDelegate = cursorView

        // FIXME: Do these views really need currentDocument _and_ diagram?
        cursorView.currentDocument = currentDocument
        ladderView.currentDocument = currentDocument

        ladderView.leftMargin = leftMargin
        cursorView.leftMargin = leftMargin
        imageScrollView.leftMargin = leftMargin

        cursorView.calibration = diagram.calibration
        ladderView.calibration = diagram.calibration
        ladderView.ladder = diagram.ladder
        imageView.image = scaleImageForImageView(diagram.image)

        imageScrollView.delegate = self

        // Distinguish the two views using slightly different background colors.
        imageScrollView.backgroundColor = UIColor.secondarySystemBackground
        imageView.backgroundColor = UIColor.secondarySystemBackground
        ladderView.backgroundColor = UIColor.tertiarySystemBackground

        // Limit max and min scale of image.
        imageScrollView.maximumZoomScale = maxZoom
        imageScrollView.minimumZoomScale = minZoom
        imageScrollView.diagramViewControllerDelegate = self

        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)
        imageView.isUserInteractionEnabled = true

        // Get defaults and apply them to views.
        updatePreferences()

        // Set up hamburger menu.
        blackView.delegate = self
        blackView.alpha = 0.0
        _constraintHamburgerLeft.constant = -self._constraintHamburgerWidth.constant

        // Navigation buttons
        // Hamburger menu is replaced by main menu on Mac.
        // TODO: Replace hamburger menu with real menu on Mac.
//        if !isRunningOnMac() {
//            navigationItem.setLeftBarButton(UIBarButtonItem(image: UIImage(named: "hamburger"), style: .plain, target: self, action: #selector(toggleHamburgerMenu)), animated: true)
//        }
        navigationItem.setLeftBarButton(UIBarButtonItem(image: UIImage(named: "hamburger"), style: .plain, target: self, action: #selector(toggleHamburgerMenu)), animated: true)

        let snapshotButton = UIBarButtonItem(image: UIImage(systemName: "photo.on.rectangle"), style: .plain, target: self, action: #selector(snapshotDiagram))
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .done, target: self, action: #selector(closeAction))
        navigationItem.setRightBarButtonItems([closeButton, snapshotButton], animated: true)
       
        // Set up touches
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        imageScrollView.addGestureRecognizer(singleTapRecognizer)

        // Set up context menu.
        let interaction = UIContextMenuInteraction(delegate: self)
        ladderView.addInteraction(interaction)
        // Context menu not great here, prefer long press gesture
//        let imageViewInteraction = UIContextMenuInteraction(delegate: imageScrollView)
//        imageScrollView.addInteraction(imageViewInteraction)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.doImageScrollViewLongPress))
        self.imageScrollView.addGestureRecognizer(longPress)

        setTitle()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNotifications()
    }

    func loadSampleDiagram(_ diagram: Diagram) {
        currentDocument?.undoManager.beginUndoGrouping()
        // FIXME: make set calibration undoable...
        self.diagram.calibration = diagram.calibration
        setLadder(diagram.ladder)
        setDiagramImage(diagram.image)
        imageScrollView.contentInset = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
        hideCursorAndNormalizeAllMarks()
        setViewsNeedDisplay()
        currentDocument?.undoManager.endUndoGrouping()
    }

    @IBAction func doImageScrollViewLongPress(sender: UILongPressGestureRecognizer) {
        print("long press")
        guard sender.state == .began else { return }
        sender.view?.becomeFirstResponder()
        let menu = UIMenuController.shared
        let rotateMenuItem = UIMenuItem(title: L("Rotate"), action: #selector(rotateAction))
        let doneMenuItem = UIMenuItem(title: L("Done"), action: #selector(doneAction))
        let resetMenuItem = UIMenuItem(title: L("Reset"), action: #selector(resetImage))
        let testMenu = UIMenuController.shared
        let test1MenuItem = UIMenuItem(title: "test1", action: #selector(rotateAction))
        let test2MenuItem = UIMenuItem(title: "test2", action: #selector(rotateAction))
        testMenu.menuItems = [test1MenuItem, test2MenuItem]
        menu.menuItems = [rotateMenuItem, doneMenuItem, resetMenuItem]
        let location = sender.location(in: sender.view)
        let rect = CGRect(x: location.x, y: location.y , width: 0, height: 0)
        menu.showMenu(from: sender.view!, rect: rect)

    }

    @objc func doneAction() {
        imageScrollView.resignFirstResponder()
    }

    @objc func rotateAction() {
        print("rotating")
        rotateImage(degrees: 90)
        imageScrollView.resignFirstResponder()
    }

    private func showDebugRestorationInfo() {
        // For debugging
        if let restorationURL = DiagramIO.getRestorationURL() {
            os_log("restorationURL path = %s", log: .debugging, type: .debug, restorationURL.path)
            let paths = FileIO.enumerateDirectory(restorationURL)
            for path in paths {
                os_log("    %s", log: .debugging, type: .debug, path)
            }
        }
    }

    func setTitle() {
        if let name = currentDocument?.name(), !name.isEmpty {
            title = isIPad() ? L("EP Diagram - \(name)") : name
        } else {
            title = L("EP Diagram")
        }
    }

    func setMode(_ mode: Mode) {
        cursorView.mode = mode
        ladderView.mode = mode
    }


    // FIXME: Create new diagram, add image.  Put into background, the restart.  We just go to the the files screen.  However 2nd time it happens, we get the desired result, with diagram loading with zoom, etc.
    override func viewDidAppear(_ animated: Bool) {
        os_log("viewDidAppear() - ViewController", log: OSLog.viewCycle, type: .info)
        super.viewDidAppear(animated)



        // Need to set this here, after view draw, or Mac malpositions cursor at start of app.
        imageScrollView.contentInset = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
        ladderView.normalizeAllMarks()
        self.userActivity = self.view.window?.windowScene?.userActivity
        // See https://github.com/mattneub/Programming-iOS-Book-Examples/blob/master/bk2ch06p357StateSaveAndRestoreWithNSUserActivity/ch19p626pageController/SceneDelegate.swift
        if restorationInfo != nil {
            if let zoomScale = restorationInfo?[DiagramViewController.restorationZoomKey] as? CGFloat {
                imageScrollView.zoomScale = zoomScale
            }
            var restorationContentOffset = CGPoint()
            // FIXME: Do we have to correct content offset Y too?
            if let contentOffsetX = restorationInfo?[DiagramViewController.restorationContentOffsetXKey] {
                restorationContentOffset.x = (contentOffsetX as? CGFloat ?? 0) * imageScrollView.zoomScale
            }
            if let contentOffsetY = restorationInfo?[DiagramViewController.restorationContentOffsetYKey] {
                restorationContentOffset.y = contentOffsetY as? CGFloat ?? 0
            }
            // FIXME: Temporary
//            imageScrollView.setContentOffset(restorationContentOffset, animated: true)

            if let isCalibrated = restorationInfo?[DiagramViewController.restorationIsCalibratedKey] as? Bool {
                cursorView.setIsCalibrated(isCalibrated)
            }
            if let calFactor = restorationInfo?[DiagramViewController.restorationCalFactorKey] as? CGFloat {
                cursorView.calFactor = calFactor
            }
            if let transformString = restorationInfo?[DiagramViewController.restorationTransformKey] as? String {
                let transform = NSCoder.cgAffineTransform(for: transformString)
                imageView.transform = transform
            }
        }
        // Only use the restorationInfo once
        restorationInfo = nil
        showMainMenu()
        updateUndoRedoButtons()
        resetViews()
    }

    // We only want to use the restorationInfo once when view controller first appears.
    var didFirstLayout = false
    override func viewDidLayoutSubviews() {
        // Called multiple times when showing context menu, so comment out for now.
//        os_log("viewDidLayoutSubviews() - ViewController", log: .viewCycle, type: .info)
        if didFirstLayout { return }
        didFirstLayout = true
        // mark pointers in registry need to reestablished when diagram is reloaded
        ladderView.reregisterAllMarks()
        let info = restorationInfo
        if let inHelp = info?[HelpViewController.inHelpKey] as? Bool, inHelp {
            performShowHelpSegue()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeNotifications()
    }

    override func updateUserActivityState(_ activity: NSUserActivity) {
        os_log("updateUserActivityState called")
        let currentDocumentURL: String = currentDocument?.fileURL.lastPathComponent ?? ""
        super.updateUserActivityState(activity)
        let info: [AnyHashable: Any] = [
            // FIXME: We are correcting just x for zoom scale.  Test if correcting y is needed too.
            DiagramViewController.restorationContentOffsetXKey: imageScrollView.contentOffset.x / imageScrollView.zoomScale,
            DiagramViewController.restorationContentOffsetYKey: imageScrollView.contentOffset.y,
            DiagramViewController.restorationZoomKey: imageScrollView.zoomScale,
            DiagramViewController.restorationIsCalibratedKey: cursorView.isCalibrated(),
            DiagramViewController.restorationCalFactorKey: cursorView.calFactor,
            DiagramViewController.restorationFileNameKey: currentDocumentURL,
            DiagramViewController.restorationDoRestorationKey: true,
            HelpViewController.inHelpKey: false,
            DiagramViewController.restorationTransformKey: NSCoder.string(for: imageView.transform),
        ]
        activity.addUserInfoEntries(from: info)
    }

    @objc func showMainMenu() {
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

    // FIXME: can't single tap on mark in ladder after finished with context menu.
    func showSlantMenu() {
        guard let toolbar = navigationController?.toolbar else { return }
        let slider = UISlider()
        slider.minimumValue = -45
        slider.maximumValue = 45
        slider.setValue(0, animated: false)
        slider.addTarget(self, action: #selector(sliderValueDidChange(_:)), for: .valueChanged)
        let doneButton = UIButton(type: .system)
        doneButton.setTitle(L("Done"), for: .normal)
        doneButton.addTarget(self, action: #selector(closeAngleMenu(_:)), for: .touchUpInside)
        let stackView = UIStackView(frame: toolbar.frame)
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(doneButton)
        setToolbarItems([UIBarButtonItem(customView: stackView)], animated: true)
    }

    func editLabel() {
        print("edit label")
        guard let selectedRegion = ladderView.selectedRegion() else { return }
        UserAlert.showTextAlert(viewController: self, title: L("Edit Label"), message: L("Enter new label text for \"\(selectedRegion.name).\""), defaultText: selectedRegion.name, preferredStyle: .alert, handler: { newLabel in
            self.ladderView.undoablySetLabel(newLabel, forRegion: selectedRegion)
        })
    }
  
    @objc func closeAngleMenu(_ sender: UIAlertAction) {
        hideCursorAndNormalizeAllMarks()
        showMainMenu()
    }

    @objc func sliderValueDidChange(_ sender: UISlider!) {
        let value: CGFloat = CGFloat(sender.value)
        ladderView.slantSelectedMarks(angle: value)
        ladderView.refresh()
    }

    @objc func showSelectMarksMenu(_: UIAlertAction) {
        if selectMenuButtons == nil {
            let prompt = makePrompt(text: L("Tap or drag over marks to select"))
            let cancelTitle = L("Done")
            let cancelButton = UIBarButtonItem(title: cancelTitle, style: .done, target: self, action: #selector(cancelSelect))
            selectMenuButtons = [prompt, spacer, cancelButton]
        }
        setToolbarItems(selectMenuButtons, animated: false)
        navigationController?.setToolbarHidden(false, animated: false)
        hideCursorAndNormalizeAllMarks()
        ladderView.normalizeRegions()
        setMode(.select)
        ladderView.startZoning()
        setViewsNeedDisplay()
    }

    // Ideally this should be "private" however need access to it in hamburger delegate in another file.
    func hideCursorAndNormalizeAllMarks() {
        guard cursorView.cursorIsVisible else { return } // don't bother if cursor not visible
        cursorView.cursorIsVisible = false
        ladderView.normalizeAllMarks()
    }

    private func showLinkMenu() {
        if linkMenuButtons == nil {
            let prompt = makePrompt(text: L("Tap pairs of marks to link them"))
            let cancelTitle = L("Done")
            let cancelButton = UIBarButtonItem(title: cancelTitle, style: .done, target: self, action: #selector(cancelLink))
            linkMenuButtons = [prompt, spacer, cancelButton]
        }
        hideCursorAndNormalizeAllMarks()
        ladderView.normalizeRegions()
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
            let cancelTitle = L("Done")
            let cancelButton = UIBarButtonItem(title: cancelTitle, style: .done, target: self, action: #selector(cancelCalibration))
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
        if !isRunningOnMac() {
            let newContentOffsetX = (imageScrollView.contentSize.width/2) - (imageScrollView.bounds.size.width/2);
            imageScrollView.contentOffset = CGPoint(x: newContentOffsetX, y: 0)
        }
    }

    // MARK: -  Buttons

    @objc func closeAction() {
        os_log("CLOSE ACTION")
        let info: [AnyHashable: Any] = [
            DiagramViewController.restorationDoRestorationKey: false]
        self.userActivity?.addUserInfoEntries(from: info)
        view.endEditing(true)
        currentDocument?.undoManager.removeAllActions()
        diagramEditorDelegate?.diagramEditorDidFinishEditing(self, diagram: diagram)
    }

    @objc func snapshotDiagram() {
        checkPhotoLibraryStatus()
    }

    func handleSnapshotDiagram() {
        let topRenderer = UIGraphicsImageRenderer(size: imageScrollView.bounds.size)
        let originX = imageScrollView.bounds.minX - imageScrollView.contentOffset.x
        let originY = imageScrollView.bounds.minY - imageScrollView.contentOffset.y
        let bounds = CGRect(x: originX, y: originY, width: imageScrollView.bounds.width, height: imageScrollView.bounds.height)
        let topImage = topRenderer.image { ctx in
            imageScrollView.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        let bottomRenderer = UIGraphicsImageRenderer(size: ladderView.bounds.size)
        let bottomImage = bottomRenderer.image { ctx in
            ladderView.drawHierarchy(in: ladderView.bounds, afterScreenUpdates: true)
        }
        let size = CGSize(width: ladderView.bounds.size.width, height: imageScrollView.bounds.size.height + ladderView.bounds.size.height)
        UIGraphicsBeginImageContext(size)
        let topRect = CGRect(x: 0, y: 0, width: ladderView.bounds.size.width, height: imageScrollView.bounds.size.height)
        topImage.draw(in: topRect)
        let bottomRect = CGRect(x: 0, y: imageScrollView.bounds.size.height, width: ladderView.bounds.size.width, height: ladderView.bounds.size.height)
        bottomImage.draw(in: bottomRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let newImage = newImage {
            let imageSaver = ImageSaver()
            imageSaver.writeToPhotoAlbum(image: newImage, viewController: self)
        }
    }

    func checkPhotoLibraryStatus() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            os_log("Photo library status authorized.", log: .default, type: .default)
            handleSnapshotDiagram()
        case .denied:
            os_log("Photo library status denied.", log: .default, type: .default)
            UserAlert.showMessage(viewController: self, title: L("Photo Library Access Not Authorized"), message: L("Please authorize photo library access in the Settings app."))
        case .restricted:
            os_log("Photo library status restricted.", log: .default, type: .default)
        case .limited:
            os_log("Photo library status limited.", log: .default, type: .default)
        case .notDetermined:
            os_log("Photo library status not determined.", log: .default, type: .default)
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == .authorized {
                    DispatchQueue.main.async {
                        self.handleSnapshotDiagram()
                    }
                }
            }
        @unknown default:
            fatalError("Unknown checkPhotoLibaryStatus case")
        }
    }


    // FIXME: Calibrate holds study with no image and zooming, but doesn't work with image!
    @objc func calibrate() {
        os_log("calibrate()", log: OSLog.action, type: .info)
        showCalibrateMenu()
        cursorView.showCalipers()
        setMode(.calibration)
    }

    @objc func linkMarks() {
        os_log("linkMarks()", log: OSLog.action, type: .info)
        hideCursorAndNormalizeAllMarks()
        ladderView.removeLinks()
        showLinkMenu()
        setMode(.link)
        setViewsNeedDisplay()
    }

    @objc func cancelSelect() {
        os_log("cancelSelect()", log: OSLog.action, type: .info)
        showMainMenu()
        setMode(.normal)
        ladderView.endZoning()
        ladderView.normalizeAllMarks()
        ladderView.setNeedsDisplay()
    }

    @objc func cancelLink() {
        os_log("cancelLink()", log: OSLog.action, type: .info)
        showMainMenu()
        setMode(.normal)
        ladderView.removeLinks()
        ladderView.normalizeAllMarks()
        ladderView.setNeedsDisplay()
    }

    @objc func setCalibration() {
        os_log("setCalibration()", log: .action, type: .info)
        cursorView.setCalibration(zoom: imageScrollView.zoomScale)
        closeCalibrationMenu()
    }

    // FIXME: clear calibration but calibration returns after saving and reopening diagram
    @objc func clearCalibration() {
        os_log("clearCalibration()", log: .action, type: .info)
        diagram.calibration.reset()
        hideCursorAndNormalizeAllMarks()
        ladderView.refresh()
        cursorView.refresh()
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
        if self.currentDocument?.undoManager?.canUndo ?? false {
            // Cursor doesn't track undo and redo well, so hide it!
            hideCursorAndNormalizeAllMarks()
            self.currentDocument?.undoManager?.undo()
            setViewsNeedDisplay()
        }
    }

    @objc func redo() {
        os_log("redo action", log: OSLog.action, type: .info)
        if self.currentDocument?.undoManager?.canRedo ?? false {
            hideCursorAndNormalizeAllMarks()
            self.currentDocument?.undoManager?.redo()
            setViewsNeedDisplay()
        }
    }



    // MARK: - Touches

    // Taps to cursor and ladder view are absorbed by cursor view and ladder view.
    // Single tap to image (not near mark) adds mark with cursor if no mark attached.
    // Single tap to image with mark attached unattaches mark.
    // Double tap to image, with attached mark:
    //    First tap unattaches mark, second tap adds mark with cursor.
    //    - without attached mark:
    //    First tap adds attached mark, second shifts anchor.
    // FIXME: not sure if second behavior is good.
    @objc func singleTap(tap: UITapGestureRecognizer) {
        os_log("singleTap - ViewController", log: OSLog.touches, type: .info)
        if cursorView.mode == .calibration {
            return
        }
        if ladderView.mode == .select {
            ladderView.zone = Zone()
            ladderView.normalizeAllMarks()
            ladderView.setNeedsDisplay()
        }
        if ladderView.mode == .normal {
            guard cursorView.allowTaps else { return }
            if !ladderView.hasActiveRegion() {
                ladderView.setActiveRegion(regionNum: 0)
            }
            if cursorView.cursorIsVisible {
                ladderView.unattachAttachedMark()
                hideCursorAndNormalizeAllMarks()
            }
            else {
                let position = tap.location(in: imageScrollView)
                cursorView.addMarkWithAttachedCursor(position: position)
            }
            setViewsNeedDisplay()
        }
    }

    // MARK: - Handle PDFs, URLs at app startup

    func openURL(url: URL) {
        os_log("openURL action", log: OSLog.action, type: .info)
        // FIXME: self.resetImage sets transform to CGAffineTransformIdentity
        // self.resetImage
        let ext = url.pathExtension.uppercased()
        if ext != "PDF" {
            // TODO: implement multipage PDF
            // self.enablePageButtons = false
            diagram.imageIsUpscaled = false
            setDiagramImage(UIImage(contentsOfFile: url.path))
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
            let scaleFactor: CGFloat = pdfScaleFactor
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
            let scaledImage = scaleImageForImageView(image)
            // correct for scale factor
            if let scaledImage = scaledImage, let cgImage = scaledImage.cgImage {
                let rescaledImage = UIImage(cgImage: cgImage, scale: scaleFactor, orientation: .up)
                setDiagramImage(rescaledImage)
                diagram.imageIsUpscaled = true
            }
            UIGraphicsEndImageContext()
        }
    }

    private func getPDFPage(_ document: CGPDFDocument, pageNumber: Int) -> CGPDFPage? {
        return document.page(at: pageNumber)
    }

    // MARK: - Rotate screen

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        os_log("viewWillTransition", log: OSLog.viewCycle, type: .info)
        super.viewWillTransition(to: size, with: coordinator)
        // Hide cursor with rotation, to avoid redrawing it.
        hideCursorAndNormalizeAllMarks()
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

    private func resetViews() {
        os_log("resetViews() - ViewController", log: .action, type: .info)
        // Add back in separatorView after rotation.
        if (separatorView == nil) {
            separatorView = HorizontalSeparatorView.addSeparatorBetweenViews(separatorType: .horizontal, primaryView: imageScrollView, secondaryView: ladderView, parentView: self.view)
            separatorView?.cursorViewDelegate = cursorView
        }
        self.ladderView.resetSize()
        self.imageView.setNeedsDisplay()
        cursorView.caliperMaxY = imageScrollView.frame.height
        setViewsNeedDisplay()
    }

    // MARK: - Segues

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
        var templateEditor = LadderTemplatesEditor(ladderTemplates: ladderTemplates)
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


    @IBSegueAction func showPreferences(_ coder: NSCoder) -> UIViewController? {
//        preferences.retrieve()
        let preferencesView = PreferencesView()
        let hostingController = UIHostingController(coder: coder, rootView: preferencesView)
        return hostingController
    }

    @IBSegueAction func showSampleSelector(_ coder: NSCoder) -> UIViewController? {
        let sampleDiagrams: [Diagram] = [
            Diagram(name: L("Normal ECG"), description: L("Just a normal ECG"), image: UIImage(named: "SampleECG")!, ladder: Ladder.defaultLadder()),
        Diagram(name: L("AV Block"), description: L("High grade AV block"), image: UIImage(named: "AVBlock")!, ladder: Ladder.defaultLadder())
//        Diagram.blankDiagram(name: L("Blank Diagram")),
//        // Make this taller than height even with rotation.
//        Diagram(name: L("Scrollable Blank Diagram"), image: UIImage.emptyImage(size: CGSize(width: view.frame.size.width * 3, height: max(view.frame.size.height, view.frame.size.width)), color: UIColor.systemTeal), description: L("Wide scrollable blank image"))
        // TODO: add others here.
        ]
        let sampleSelector = SampleSelector(sampleDiagrams: sampleDiagrams, delegate: self)
        let hostingController = UIHostingController(coder: coder, rootView: sampleSelector)
        return hostingController
    }

    @IBSegueAction func performShowHelpSegueAction(_ coder: NSCoder) -> HelpViewController? {
        let helpViewController = HelpViewController(coder: coder)
        helpViewController?.restorationInfo = self.restorationInfo
        return helpViewController
    }

    func performSelectLadderSegue() {
        performSegue(withIdentifier: "selectLadderSegue", sender: self)
    }

    func performEditLadderSegue() {
        performSegue(withIdentifier: "EditLadderSegue", sender: self)
    }

    func performShowSampleSelectorSegue() {
        performSegue(withIdentifier: "showSampleSelectorSegue", sender: self)
    }

    func performShowHelpSegue() {
        P("performShowHelpSegue")
        self.userActivity?.needsSave = true
        performSegue(withIdentifier: "showHelpSegue", sender: self)
    }

    func performShowPreferencesSegue() {
        performSegue(withIdentifier: "showPreferencesSegue", sender: self)
    }

    func performShowTemplateEditorSegue() {
        performSegue(withIdentifier: "showTemplateEditorSegue", sender: self)
    }

    // MARK: - Mac menu actions

    @IBAction func showPreferencesCommand(_ sender: Any) {
        showPreferences()
    }

    // This is called automatically by the Help menu.
    @IBAction func showHelp(_ sender: Any) {
        showHelp()
    }

 
    @IBAction func getDiagramInfo(_ sender: Any) {
        getDiagramInfo()
    }

    @IBAction func sampleDiagrams(_ sender: Any) {
        sampleDiagrams()
    }

    @IBAction func openImage(_ sender: AnyObject) {
        /* Present open panel. */
//        guard let window = self.window else { return }
//        let openPanel = NSOpenPanel()
//        openPanel.allowedFileTypes = validFileExtensions()
//        openPanel.canSelectHiddenExtension = true
//        openPanel.beginSheetModal(for: window,
//            completionHandler: {
//                (result: NSApplication.ModalResponse) -> Void in
//                if result == .OK {
//                    self.openURL(openPanel.url, addToRecentDocuments: true)
//               }
//            }
//        )
    }
}

extension DiagramViewController {
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUndoableAction(_:)), name: .didUndoableAction, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePreferences), name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIScene.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnect), name: UIScene.didDisconnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resolveFileConflicts), name: UIDocument.stateChangedNotification, object: nil)
  
    }

    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .didUndoableAction, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIScene.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIScene.didDisconnectNotification, object: nil)
    }

    @objc func onDidUndoableAction(_ notification: Notification) {
        if notification.name == .didUndoableAction {
            updateUndoRedoButtons()
        }
    }

    func updateUndoRedoButtons() {
//        undoButton.isEnabled = true
//        redoButton.isEnabled = true
        // DispatchQueue here forces UI to finish up its tasks before performing below on the main thread.
        DispatchQueue.main.async {
            self.undoButton.isEnabled = self.currentDocument?.undoManager?.canUndo ?? false
            self.redoButton.isEnabled = self.currentDocument?.undoManager?.canRedo ?? false
        }
    }

    @objc func didEnterBackground() {
        os_log("didEnterBackground()", log: .action, type: .info)
    }

    @objc func didDisconnect() {
        os_log("didDisconnect()", log: .lifeCycle, type: .info)

    }

    @objc func updatePreferences() {
        os_log("updatePreferences()", log: .action, type: .info)
        ladderView.markLineWidth = CGFloat(UserDefaults.standard.double(forKey: Preferences.defaultLineWidthKey))
        cursorView.lineWidth = CGFloat(UserDefaults.standard.double(forKey: Preferences.defaultCursorLineWidthKey))
        ladderView.showBlock = UserDefaults.standard.bool(forKey: Preferences.defaultShowBlockKey)
        ladderView.showImpulseOrigin = UserDefaults.standard.bool(forKey: Preferences.defaultShowImpulseOriginKey)
        ladderView.showIntervals = UserDefaults.standard.bool(forKey: Preferences.defaultShowIntervalsKey)
        ladderView.showConductionTimes = UserDefaults.standard.bool(forKey: Preferences.defaultShowConductionTimesKey)
        ladderView.snapMarks = UserDefaults.standard.bool(forKey: Preferences.defaultSnapMarksKey)
        ladderView.defaultMarkStyle = Mark.Style(rawValue: UserDefaults.standard.integer(forKey: Preferences.defaultMarkStyleKey)) ?? .solid
    }

    @objc func resolveFileConflicts() {
        os_log("resolveFileConflicts()", log: .action, type: .info)
        guard let currentDocument = currentDocument else { return }
        if currentDocument.documentState == UIDocument.State.inConflict {
            // Use newest file wins strategy.
            do {
                try NSFileVersion.removeOtherVersionsOfItem(at: currentDocument.fileURL)

            } catch {
                os_log("Error resolving file conflict - %s", log: .errors, type: .error, error.localizedDescription)
            }
            currentDocument.diagram = diagram
        }
    }

}

extension DiagramViewController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        let typeIdentifiers = [UTType.image.identifier]
        return session.hasItemsConforming(toTypeIdentifiers: typeIdentifiers ) && session.items.count == 1
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        let dropLocation = session.location(in: view)

        let operation: UIDropOperation

        if imageScrollView.frame.contains(dropLocation) {
            operation =  .copy
        } else {
            // Do not allow dropping outside of the image view.
            operation = .cancel
        }

        return UIDropProposal(operation: operation)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        // Consume drag items (in this example, of type UIImage).
        session.loadObjects(ofClass: UIImage.self) { imageItems in
            print("load image")
            if let images = imageItems as? [UIImage] {
                self.diagram.imageIsUpscaled = false
                self.setDiagramImage(images.first)
                return
            }
        }
    }
}

extension DiagramViewController {
    static func navigationControllerFactory() -> UINavigationController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let controller = storyboard.instantiateInitialViewController() as? UINavigationController else {
            fatalError("Project fault - cant instantiate NavigationController from storyboard")
        }
        return controller
    }

    func renameDocument(oldURL: URL, newURL: URL) {
        os_log("renameDocument", log: .action, type: .info)
        guard oldURL != newURL else { return }
        DispatchQueue.global(qos: .background).async {
            self.currentDocument?.close { success in
                if success {
                    let error: NSError? = nil
                    let fileCoordinator = NSFileCoordinator()
                    var moveError = error
                    fileCoordinator.coordinate(writingItemAt: oldURL, options: .forMoving, writingItemAt: newURL, options: .forReplacing, error: &moveError, byAccessor: { newURL1, newURL2 in
                        let fileManager = FileManager.default
                        fileCoordinator.item(at: oldURL, willMoveTo: newURL)
                        if (try? fileManager.moveItem(at: newURL1, to: newURL2)) != nil {
                            fileCoordinator.item(at: oldURL, didMoveTo: newURL)
                            self.currentDocument = DiagramDocument(fileURL: newURL)
                            self.currentDocument?.open { openSuccess in
                                guard openSuccess else {
                                    print ("could not open \(newURL)")
                                    return
                                }
                                // Try to delete old document, ignore errors.
                                // FIXME: Should rename delete old file?
                                if fileManager.isDeletableFile(atPath: oldURL.path) {
                                    try? fileManager.removeItem(atPath: oldURL.path)
                                }
                                DispatchQueue.main.async {
                                    self.currentDocument?.diagram = self.diagram
                                    self.setTitle()
                                }
                            }
                        }
                        if let error = error {
                            print("error = \(error.localizedDescription)")
                        }
                    })
                }
            }
        }
    }
}


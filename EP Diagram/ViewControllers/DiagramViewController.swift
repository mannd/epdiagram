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

    // Constants
    static let defaultLeftMargin: CGFloat = 50
    static let minLeftMargin: Float = 30
    static let maxLeftMargin: Float = 100
    static let minSlantAngle: Float = -45
    static let maxSlantAngle: Float = 45

    // This margin is passed to other views.
    var leftMargin: CGFloat = defaultLeftMargin {
        didSet {
            diagram.leftMargin = leftMargin
            ladderView.leftMargin = leftMargin
            cursorView.leftMargin = leftMargin
            imageScrollView.leftMargin = leftMargin
            imageScrollView.contentInset = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
        }
    }

    // Mode is passed to the other views, and setting mode cleans up after each change.
    var mode: Mode = .normal {
        didSet {
            cursorView.cursorIsVisible = false
            ladderView.normalizeLadder()
            cursorView.mode = mode
            ladderView.mode = mode
            hamburgerButton.isEnabled = (mode == .normal)
            switch mode {
            case .normal:
                ladderView.setActiveRegion(regionNum: 0)
                ladderView.endZoning()
                ladderView.removeConnectedMarks()
                showMainToolbar()
            case .select:
                ladderView.startZoning()
                showSelectToolbar()
            case .connect:
                showConnectToolbar()
            case .calibrate:
                cursorView.showCalipers()
                showCalibrateToolbar()
            default:
                break
            }
            setViewsNeedDisplay()
        }
    }

    var calibration: Calibration {
        get { diagram.calibration }
        set(newValue) {
            diagram.calibration = newValue
            ladderView.calibration = newValue
            cursorView.calibration = newValue
        }

    }

    var marksAreHidden: Bool {
        get { ladderView.marksAreHidden }
        set(newValue) {
            ladderView.marksAreHidden = newValue
            cursorView.marksAreHidden = newValue
        }
    }

    // Buttons, toolbars
    private let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    private var undoButton: UIBarButtonItem = UIBarButtonItem()
    private var redoButton: UIBarButtonItem = UIBarButtonItem()
    private var calibrateButton: UIBarButtonItem = UIBarButtonItem()
    private var connectButton: UIBarButtonItem = UIBarButtonItem()
    private var selectButton: UIBarButtonItem = UIBarButtonItem()
    private var mainToolbarButtons: [UIBarButtonItem]?
    private var selectToolbarButtons: [UIBarButtonItem]?
    private var connectToolbarButtons: [UIBarButtonItem]?
    private var calibrateToolbarButtons: [UIBarButtonItem]?
    private var hamburgerButton: UIBarButtonItem = UIBarButtonItem()

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

    // Diagram preferences
    var playSounds: Bool = true

    // Set by screen delegate
    var restorationInfo: [AnyHashable: Any]?

    // Keys for state restoration
    static let restorationContentOffsetXKey = "restorationContentOffsetXKey"
    static let restorationContentOffsetYKey = "restorationContentOffsetYKey"
    static let restorationZoomKey = "restorationZoomKey"
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

    var prolongSelectState = false // used to allow menus like slant to complete actions on selected marks
    var activeEndpoint: Mark.Endpoint = .proximal
    var adjustment: Adjustment = .adjust

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

    lazy var adjustLeftMarginAction = UIAction(title: L("Adjust left margin"), image: UIImage(systemName: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right")) { action in
        self.showAdjustLeftMarginToolbar()
    }

    // TODO: Do we need something like this.  We do if we allow manual setting of block.
    lazy var reanalyzeLadderAction = UIAction(title: L("Reanalyze ladder")) { action in }

    lazy var unlinkAll = UIAction(title: L("Unlink all marks")) { action in
        self.ladderView.unlinkAllMarks()
    }
    lazy var linkAll = UIAction(title: L("Link all marks")) { action in
        self.ladderView.linkAllMarks()
    }

    lazy var blockProximalAction = UIAction(title: L("Proximal block")) { action in

    }
    lazy var blockDistalAction = UIAction(title: L("Distal block")) { action in

    }
    lazy var blockNoneAction = UIAction(title: L("No block")) { action in

    }
    lazy var blockAutoAction = UIAction(title: L("Auto block")) { action in
//        self.ladderView.setBlockAuto()
    }
    lazy var blockMenu = UIMenu(title: L("Block..."), children: [self.blockProximalAction, self.blockDistalAction, self.blockNoneAction, self.blockAutoAction])

    lazy var solidAction = UIAction(title: L("Solid")) { action in
        self.ladderView.setSelectedMarksStyle(style: .solid)
    }
    lazy var dashedAction = UIAction(title: L("Dashed")) { action in
        self.ladderView.setSelectedMarksStyle(style: .dashed)
    }
    lazy var dottedAction = UIAction(title: L("Dotted")) { action in
        self.ladderView.setSelectedMarksStyle(style: .dotted)
    }
    lazy var styleMenu = UIMenu(title: L("Style..."), image: UIImage(systemName: "scribble"), children: [self.solidAction, self.dashedAction, self.dottedAction, self.regionStyleMenu])

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
        self.activeEndpoint = .proximal
        self.showSlantToolbar()
    }
    lazy var slantDistalPivotAction = UIAction(title: L("Slant distal pivot point")) { action in
        self.activeEndpoint = .distal
        self.showSlantToolbar()
    }
    lazy var slantMenu = UIMenu(title: L("Slant mark(s)..."), image: UIImage(systemName: "line.diagonal"), children: [self.slantProximalPivotAction, self.slantDistalPivotAction])

    lazy var adjustProximalYAction = UIAction(title: L("Adjust proximal mark end(s)")) { action in
        self.activeEndpoint = .proximal
        self.adjustment = .adjust
        self.showAdjustYToolbar()
    }
    lazy var adjustDistalYAction = UIAction(title: L("Adjust distal mark end(s)")) { action in
        self.activeEndpoint = .distal
        self.adjustment = .adjust
        self.showAdjustYToolbar()
    }
    lazy var trimProximalYAction = UIAction(title: L("Trim proximal mark end(s)")) { action in
        self.activeEndpoint = .proximal
        self.adjustment = .trim
        self.showAdjustYToolbar()
    }
    lazy var trimDistalYAction = UIAction(title: L("Trim distal mark end(s)")) { action in
        self.activeEndpoint = .distal
        self.adjustment = .trim
        self.showAdjustYToolbar()
    }
    lazy var adjustYMenu = UIMenu(title: L("Adjust mark ends..."), children: [adjustProximalYAction, adjustDistalYAction, trimProximalYAction, trimDistalYAction])

    lazy var oneRegionHeightAction = UIAction(title: L("1 unit")) { action in
        guard let selectedRegion = self.ladderView.selectedLabelRegion() else { return }
        self.ladderView.setRegionHeight(1, forRegion: selectedRegion)
    }
    lazy var twoRegionHeightAction = UIAction(title: L("2 units")) { action in
        guard let selectedRegion = self.ladderView.selectedLabelRegion() else { return }
        self.ladderView.setRegionHeight(2, forRegion: selectedRegion)
    }
    lazy var threeRegionHeightAction = UIAction(title: L("3 units")) { action in
        guard let selectedRegion = self.ladderView.selectedLabelRegion() else { return }
        self.ladderView.setRegionHeight(3, forRegion: selectedRegion)
    }
    lazy var fourRegionHeightAction = UIAction(title: L("4 units")) { action in
        guard let selectedRegion = self.ladderView.selectedLabelRegion() else { return }
        self.ladderView.setRegionHeight(4, forRegion: selectedRegion)
    }
    lazy var regionHeightMenu = UIMenu(title: L("Region height..."), image: UIImage(systemName: "arrow.up.arrow.down.square"), children: [self.oneRegionHeightAction, self.twoRegionHeightAction, self.threeRegionHeightAction, self.fourRegionHeightAction])


    lazy var unlinkAction = UIAction(title: L("Unlink"), image: UIImage(systemName: "link")) { action in
        self.ladderView.unlinkSelectedMarks()
    }

    lazy var straightenToProximalAction = UIAction(title: L("Straighten mark to proximal endpoint")) { action in
        self.ladderView.straightenToEndpoint(.proximal)
    }
    lazy var straightenToDistalAction = UIAction(title: L("Straighten mark to distal endpoint")) { action in
        self.ladderView.straightenToEndpoint(.distal)
    }
    lazy var straightenMenu = UIMenu(title: L("Straighten mark(s)..."), image: UIImage(systemName: "arrow.up.arrow.down"), children: [self.straightenToProximalAction, self.straightenToDistalAction])

    lazy var rhythmAction = UIAction(title: L("Rhythm"), image: UIImage(systemName: "waveform.path.ecg")) { action in
        // TODO: implement
    }
    lazy var editLabelAction = UIAction(title: L("Edit label"), image: UIImage(systemName: "pencil.circle")) { action in
        self.editLabel()
    }

    lazy var addRegionAboveAction = UIAction(title: L("Add region above")) { action in
        self.ladderView.addRegion(relation: .before)
    }
    lazy var addRegionBelowAction = UIAction(title: L("Add region below")) { action in
        self.ladderView.addRegion(relation: .after)
    }
    lazy var addRegionMenu = UIMenu(title: L("Add Region..."), image: UIImage(systemName: "plus"), children: [self.addRegionAboveAction, self.addRegionBelowAction])

    lazy var removeRegionAction = UIAction(title: L("Remove region"), image: UIImage(systemName: "minus")) { action in
        self.ladderView.removeRegion()
    }

    // MARK: - Lifecycle
    
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

        leftMargin = diagram.ladder.leftMargin

        // init views
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
        hamburgerButton = UIBarButtonItem(image: UIImage(named: "hamburger"), style: .plain, target: self, action: #selector(toggleHamburgerMenu))
        navigationItem.setLeftBarButton(hamburgerButton, animated: true)

        let snapshotButton = UIBarButtonItem(image: UIImage(systemName: "photo.on.rectangle"), style: .plain, target: self, action: #selector(snapshotDiagram))
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .done, target: self, action: #selector(closeDocument))
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

    override func viewDidAppear(_ animated: Bool) {
        os_log("viewDidAppear() - ViewController", log: OSLog.viewCycle, type: .info)
        super.viewDidAppear(animated)

        // Need to set this here, after view draw, or Mac malpositions cursor at start of app.
        imageScrollView.contentInset = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
        ladderView.normalizeAllMarks()
        self.userActivity = self.view.window?.windowScene?.userActivity
        // See https://github.com/mattneub/Programming-iOS-Book-Examples/blob/master/bk2ch06p357StateSaveAndRestoreWithNSUserActivity/ch19p626pageController/SceneDelegate.swift
        if restorationInfo != nil {
            if let zoomScale = restorationInfo?[Self.restorationZoomKey] as? CGFloat {
                imageScrollView.zoomScale = zoomScale
            }
            var restorationContentOffset = CGPoint()
            // FIXME: Do we have to correct content offset Y too?
            if let contentOffsetX = restorationInfo?[Self.restorationContentOffsetXKey] {
                restorationContentOffset.x = (contentOffsetX as? CGFloat ?? 0) * imageScrollView.zoomScale
            }
            if let contentOffsetY = restorationInfo?[Self.restorationContentOffsetYKey] {
                restorationContentOffset.y = contentOffsetY as? CGFloat ?? 0
            }
            // FIXME: Temporary
            //            imageScrollView.setContentOffset(restorationContentOffset, animated: true)
            if let transformString = restorationInfo?[Self.restorationTransformKey] as? String {
                let transform = NSCoder.cgAffineTransform(for: transformString)
                imageView.transform = transform
            }
        }
        // Only use the restorationInfo once
        restorationInfo = nil
        showMainToolbar()
        updateToolbarButtons()
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
            Self.restorationContentOffsetXKey: imageScrollView.contentOffset.x / imageScrollView.zoomScale,
            Self.restorationContentOffsetYKey: imageScrollView.contentOffset.y,
            Self.restorationZoomKey: imageScrollView.zoomScale,
            Self.restorationFileNameKey: currentDocumentURL,
            Self.restorationDoRestorationKey: true,
            HelpViewController.inHelpKey: false,
            Self.restorationTransformKey: NSCoder.string(for: imageView.transform),
        ]
        activity.addUserInfoEntries(from: info)
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

    func loadSampleDiagram(_ diagram: Diagram) {
        currentDocument?.undoManager.beginUndoGrouping()
        undoablySetCalibration(Calibration())
        undoablySetLadder(diagram.ladder)
        undoablySetDiagramImage(diagram.image)
        currentDocument?.undoManager.endUndoGrouping()
        mode = .normal
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



    func setTitle() {
        if let name = currentDocument?.name(), !name.isEmpty {
            title = isIPad() ? L("EP Diagram - \(name)") : name
        } else {
            title = L("EP Diagram")
        }
    }

    // MARK: Toolbars, Modes

    @objc func showMainToolbar() {
        if mainToolbarButtons == nil {
            calibrateButton = UIBarButtonItem(title: L("Calibrate"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(launchCalibrateMode))
            selectButton = UIBarButtonItem(title: L("Select"), style: .plain, target: self, action: #selector(launchSelectMode))
            connectButton = UIBarButtonItem(title: L("Connect"), style: .plain, target: self, action: #selector(launchConnectMode))
            undoButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(undo))
            redoButton = UIBarButtonItem(barButtonSystemItem: .redo, target: self, action: #selector(redo))
            mainToolbarButtons = [calibrateButton, spacer, selectButton, spacer, connectButton, spacer, undoButton, spacer, redoButton]
        }
        setToolbarItems(mainToolbarButtons, animated: false)
        navigationController?.setToolbarHidden(false, animated: false)
    }

    @objc func launchSelectMode(_: UIAlertAction) {
        mode = .select
    }

    private func showSelectToolbar() {
        if selectToolbarButtons == nil {
            let prompt = makePrompt(text: L("Tap or drag to select"))
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancelSelectMode))
            selectToolbarButtons = [prompt, spacer, doneButton]
        }
        setToolbarItems(selectToolbarButtons, animated: false)
    }

    @objc func cancelSelectMode() {
        os_log("cancelSelect()", log: OSLog.action, type: .info)
        mode = .normal
        ladderView.setNeedsDisplay()
    }

    @objc func launchConnectMode() {
        os_log("connectMarks()", log: .action, type: .info)
        mode = .connect
    }

    private func showConnectToolbar() {
        if connectToolbarButtons == nil {
            let prompt = makePrompt(text: L("Tap pairs of marks to connect them"))
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancelConnectMode))
            connectToolbarButtons = [prompt, spacer, doneButton]
        }
        setToolbarItems(connectToolbarButtons, animated: false)
    }

    @objc func cancelConnectMode() {
        os_log("cancelLink()", log: OSLog.action, type: .info)
        mode = .normal
        ladderView.setNeedsDisplay()
    }

    func showSlantToolbar() {
        guard let toolbar = navigationController?.toolbar else { return }
        currentDocument?.undoManager.beginUndoGrouping()
        prolongSelectState = true

        let labelText = UITextField()
        labelText.text = L("Adjust mark slant")
        let slider = UISlider()
        slider.minimumValue = Self.minSlantAngle
        slider.maximumValue = Self.maxSlantAngle
        if let soleSelectedMark = ladderView.soleSelectedMark() {
            var slantAngle = ladderView.slantAngle(mark: soleSelectedMark, endpoint: activeEndpoint)
            // slant angle is flipped depending on endpoint, but it makes the slider and marks move in concert.
            slantAngle = activeEndpoint == .proximal ? -slantAngle : slantAngle
            slider.setValue(Float(slantAngle), animated: false)

        } else {
            slider.setValue(0, animated: false)
            ladderView.slantSelectedMarks(angle: 0, endpoint: activeEndpoint)
        }
        // init marks to 0 slant
        slider.addTarget(self, action: #selector(slantSliderValueDidChange(_:)), for: .valueChanged)
        let doneButton = UIButton(type: .system)
        doneButton.setTitle(L("Done"), for: .normal)
        doneButton.addTarget(self, action: #selector(closeSlantToolbar(_:)), for: .touchUpInside)
        let stackView = UIStackView(frame: toolbar.frame)
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.addArrangedSubview(labelText)
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(doneButton)
        setToolbarItems([UIBarButtonItem(customView: stackView)], animated: true)
    }

    func showAdjustLeftMarginToolbar() {
        guard let toolbar = navigationController?.toolbar else { return }
        currentDocument?.undoManager.beginUndoGrouping() // will end when menu closed
        prolongSelectState = true
        let labelText = UITextField()
        labelText.text = L("Adjust left margin")
        let slider = UISlider()
        slider.minimumValue = Self.minLeftMargin
        slider.maximumValue = Self.maxLeftMargin
        slider.setValue(Float(leftMargin), animated: false)
        slider.addTarget(self, action: #selector(leftMarginSliderValueDidChange(_:)), for: .valueChanged)
        let doneButton = UIButton(type: .system)
        doneButton.setTitle(L("Done"), for: .normal)
        doneButton.addTarget(self, action: #selector(closeAdjustLeftMarginToolbar(_:)), for: .touchUpInside)
        let stackView = UIStackView(frame: toolbar.frame)
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.addArrangedSubview(labelText)
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(doneButton)
        setToolbarItems([UIBarButtonItem(customView: stackView)], animated: true)
    }

    func showAdjustYToolbar() {
        guard let toolbar = navigationController?.toolbar else { return }
        currentDocument?.undoManager.beginUndoGrouping() // will end when menu closed
        prolongSelectState = true
        let labelText = UITextField()
        labelText.text = adjustment == .adjust ? L("Adjust distal Y value") : L("Trim distal Y value")
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1.0
        if let soleSelectedMark = ladderView.soleSelectedMark() {
            let y = activeEndpoint == .proximal ? soleSelectedMark.segment.proximal.y : soleSelectedMark.segment.distal.y
            slider.setValue(Float(y), animated: false)
        } else {
            let startValue: Float = activeEndpoint == .proximal ? 0 : 1
            slider.setValue(startValue, animated: false)
            ladderView.adjustY(CGFloat(startValue), endpoint: activeEndpoint, adjustment: adjustment)
        }
        slider.addTarget(self, action: #selector(adjustYSliderValueDidChange(_:)), for: .valueChanged)
        let doneButton = UIButton(type: .system)
        doneButton.setTitle(L("Done"), for: .normal)
        doneButton.addTarget(self, action: #selector(closeAdjustYToolbar(_:)), for: .touchUpInside)
        let stackView = UIStackView(frame: toolbar.frame)
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.addArrangedSubview(labelText)
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(doneButton)
        setToolbarItems([UIBarButtonItem(customView: stackView)], animated: true)
    }

    @objc func adjustYSliderValueDidChange(_ sender: UISlider) {
        let value: CGFloat = CGFloat(sender.value)
        ladderView.adjustY(value, endpoint: activeEndpoint, adjustment: adjustment)
        ladderView.refresh()
    }


    @objc func closeSlantToolbar(_ sender: UIAlertAction) {
        currentDocument?.undoManager.endUndoGrouping()
        hideCursorAndNormalizeAllMarks()
        prolongSelectState = false
        mode = ladderView.restoreState()
    }

    @objc func closeAdjustYToolbar(_ sender: UIAlertAction) {
        currentDocument?.undoManager.endUndoGrouping()
        hideCursorAndNormalizeAllMarks()
        prolongSelectState = false
        ladderView.swapEndsIfNeeded()
        mode = ladderView.restoreState()
//        ladderView.swapEndsIfNeeded()
    }

    @objc func slantSliderValueDidChange(_ sender: UISlider) {
        let value: CGFloat = CGFloat(sender.value)
        ladderView.slantSelectedMarks(angle: value, endpoint: activeEndpoint)
        ladderView.refresh()
    }

    // Ideally this should be "private" however need access to it in hamburger delegate in another file.
    func hideCursorAndNormalizeAllMarks() {
        cursorView.cursorIsVisible = false
        ladderView.normalizeAllMarks()
        setViewsNeedDisplay()
    }

 
    private func makePrompt(text: String) -> UIBarButtonItem {
        let prompt = UILabel()
        prompt.text = text
        return UIBarButtonItem(customView: prompt)
    }

    // MARK: -  Actions

    @objc func closeDocument() {
        os_log("closeDocument()", log: .action, type: .info)
        let info: [AnyHashable: Any] = [
            Self.restorationDoRestorationKey: false]
        self.userActivity?.addUserInfoEntries(from: info)
        view.endEditing(true)
        currentDocument?.undoManager.removeAllActions()
        diagramEditorDelegate?.diagramEditorDidFinishEditing(self, diagram: diagram)
    }

    @objc func snapshotDiagram() {
        os_log("snapshotDiagram()", log: .action, type: .info)

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
            if playSounds {
                Sounds.playShutterSound()
            }
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

    @objc func launchCalibrateMode() {
        os_log("calibrate()", log: OSLog.action, type: .info)
        mode = .calibrate
    }

    private func showCalibrateToolbar() {
        if calibrateToolbarButtons == nil {
            let promptButton = makePrompt(text: L("Set caliper to 1000 ms"))
            let setButton = UIBarButtonItem(title: L("Set"), style: .plain, target: self, action: #selector(setCalibration))
            let clearButton = UIBarButtonItem(title: L("Clear"), style: .plain, target: self, action: #selector(clearCalibration))
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancelCalibrateMode))
            calibrateToolbarButtons = [promptButton, spacer, setButton, clearButton, doneButton]
        }
        setToolbarItems(calibrateToolbarButtons, animated: false)
    }


    @objc func setCalibration() {
        os_log("setCalibration()", log: .action, type: .info)
        let newCalibration = cursorView.newCalibration(zoom: imageScrollView.zoomScale)
        undoablySetCalibration(newCalibration)
        cancelCalibrateMode()
    }

    @objc func clearCalibration() {
        os_log("clearCalibration()", log: .action, type: .info)
        undoablySetCalibration(Calibration())
        cancelCalibrateMode()
    }

    @objc func cancelCalibrateMode() {
        mode = .normal
    }

    @objc func leftMarginSliderValueDidChange(_ sender: UISlider!) {
        let value = CGFloat(sender.value)
        undoablySetLeftMargin(value)
        ladderView.refresh()
    }

    private func undoablySetLeftMargin(_ margin: CGFloat) {
        let oldLeftMargin = leftMargin
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetLeftMargin(oldLeftMargin)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        leftMargin = margin
    }

    @objc func closeAdjustLeftMarginToolbar(_ sender: UISlider!) {
        currentDocument?.undoManager.endUndoGrouping()
        hideCursorAndNormalizeAllMarks()
        prolongSelectState = false
        mode = ladderView.restoreState()
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

    func editLabel() {
        guard let selectedRegion = ladderView.selectedLabelRegion() else { return }
        UserAlert.showEditLabelAlert(viewController: self, region: selectedRegion, handler: { newLabel, newDescription in
            self.ladderView.undoablySetLabel(newLabel, description: newDescription, forRegion: selectedRegion)
        })
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
        guard !marksAreHidden else { return }
        if cursorView.mode == .calibrate {
            return
        }
        if ladderView.mode == .select {
            ladderView.endZoning()
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
            undoablySetDiagramImageAndResetLadder(UIImage(contentsOfFile: url.path))
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
        mode = .normal
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
                diagram.imageIsUpscaled = true
                undoablySetDiagramImageAndResetLadder(rescaledImage)
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
        let ladderTemplatesModelController = LadderTemplatesModelController(viewController: self)
        let templateEditor = LadderTemplatesEditor(ladderTemplatesController: ladderTemplatesModelController)
        let hostingController = UIHostingController(coder: coder, rootView: templateEditor)
        return hostingController
    }

    @IBSegueAction func showLadderSelector(_ coder: NSCoder) -> UIViewController? {
        os_log("showLadderSelector")
        navigationController?.setToolbarHidden(true, animated: true)
        let ladderTemplates = LadderTemplate.templates()
        let index = ladderTemplates.firstIndex(where: { ladderTemplate in
            ladderTemplate.name == ladderView.ladder.name
        })
        var ladderSelector = LadderSelector(ladderTemplates: ladderTemplates, selectedIndex: index ?? 0)
        ladderSelector.delegate = self
        let hostingController = UIHostingController(coder: coder, rootView: ladderSelector)
        return hostingController
    }

    @IBSegueAction func showPreferences(_ coder: NSCoder) -> UIViewController? {
        let diagramModelController = DiagramModelController(diagram: diagram, diagramViewController: self)
        let preferencesView = PreferencesView(diagramController: diagramModelController)
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

    func updateToolbarButtons() {
        calibrateButton.isEnabled = !marksAreHidden && !ladderView.ladderIsLocked
        selectButton.isEnabled = !marksAreHidden && !ladderView.ladderIsLocked
        connectButton.isEnabled = !marksAreHidden && !ladderView.ladderIsLocked
    }

    @objc func updatePreferences() {
        os_log("updatePreferences()", log: .action, type: .info)
        ladderView.markLineWidth = CGFloat(UserDefaults.standard.integer(forKey: Preferences.defaultLineWidthKey))
        cursorView.lineWidth = CGFloat(UserDefaults.standard.integer(forKey: Preferences.defaultCursorLineWidthKey))
        cursorView.caliperLineWidth = CGFloat(UserDefaults.standard.integer(forKey: Preferences.defaultCaliperLineWidthKey))
        ladderView.showBlock = UserDefaults.standard.bool(forKey: Preferences.defaultShowBlockKey)
        ladderView.showImpulseOrigin = UserDefaults.standard.bool(forKey: Preferences.defaultShowImpulseOriginKey)
        ladderView.showIntervals = UserDefaults.standard.bool(forKey: Preferences.defaultShowIntervalsKey)
        ladderView.showConductionTimes = UserDefaults.standard.bool(forKey: Preferences.defaultShowConductionTimesKey)
        ladderView.snapMarks = UserDefaults.standard.bool(forKey: Preferences.defaultSnapMarksKey)
        ladderView.defaultMarkStyle = Mark.Style(rawValue: UserDefaults.standard.integer(forKey: Preferences.defaultMarkStyleKey)) ?? .solid
        ladderView.showLabelDescription = TextVisibility(rawValue: UserDefaults.standard.integer(forKey: Preferences.defaultLabelDescriptionVisibilityKey)) ?? .invisible
        playSounds = UserDefaults.standard.bool(forKey: Preferences.defaultPlaySoundsKey)
        marksAreHidden = UserDefaults.standard.bool(forKey: Preferences.defaultHideMarksKey)
        let caliperColorName = ColorName(rawValue: UserDefaults.standard.integer(forKey: Preferences.defaultCaliperColorNameKey)) ?? ColorName.blue
        cursorView.caliperColor = caliperColorName.color()
        let cursorColorName = ColorName(rawValue: UserDefaults.standard.integer(forKey: Preferences.defaultCursorColorNameKey)) ?? ColorName.blue
        cursorView.cursorColor = cursorColorName.color()
        let attachedColorName = ColorName(rawValue: UserDefaults.standard.integer(forKey: Preferences.defaultAttachedColorNameKey)) ?? ColorName.orange
        ladderView.attachedColor = attachedColorName.color()
        let connectedColorName = ColorName(rawValue: UserDefaults.standard.integer(forKey: Preferences.defaultConnectedColorNameKey)) ?? ColorName.green
        ladderView.connectedColor = connectedColorName.color()
        let selectedColorName = ColorName(rawValue: UserDefaults.standard.integer(forKey: Preferences.defaultSelectedColorNameKey)) ?? ColorName.blue
        ladderView.selectedColor = selectedColorName.color()
        let linkedColorName = ColorName(rawValue: UserDefaults.standard.integer(forKey: Preferences.defaultLinkedColorNameKey)) ?? ColorName.purple
        ladderView.linkedColor = linkedColorName.color()
        let normalColorName = ColorName(rawValue: UserDefaults.standard.integer(forKey: Preferences.defaultNormalColorNameKey)) ?? ColorName.normal
        ladderView.normalColor = normalColorName.color()
        let activeColorName = ColorName(rawValue: UserDefaults.standard.integer(forKey: Preferences.defaultActiveColorNameKey)) ?? ColorName.red
        ladderView.activeColor = activeColorName.color()
        updateToolbarButtons()
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
                self.undoablySetDiagramImageAndResetLadder(images.first)
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

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
    // For debugging only
    #if DEBUG
    var debugForceOnboarding = false
    #else // Don't change below!
    var debugForceOnboarding = false
    #endif

    // View, outlets, constraints
    @IBOutlet var _constraintHamburgerWidth: NSLayoutConstraint!
    @IBOutlet var _constraintHamburgerLeft: NSLayoutConstraint!
    @IBOutlet var imageScrollView: ImageScrollView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var imageContainerView: UIView!
    @IBOutlet var ladderView: LadderView!
    @IBOutlet var cursorView: CursorView!
    @IBOutlet var blackView: BlackView!
    var hamburgerTableViewController: HamburgerTableViewController? // We get this view via its embed segue!

    var separatorView: SeparatorView?
    @IBOutlet var imageViewHeightConstraint: NSLayoutConstraint!

    // Constants
    static let defaultLeftMargin: CGFloat = 50
    static let minLeftMargin: Float = 30
    static let maxLeftMargin: Float = 100
    static let minSlantAngle: Float = -45
    static let maxSlantAngle: Float = 45

    let stackViewSpacing: CGFloat = 12

    let gotoTextFieldTag = 1

    // These are taken from the Apple IKImageView demo
    let zoomInFactor: CGFloat = 1.414214
    let zoomOutFactor: CGFloat = 0.7071068

    // This margin is passed to other views.
    var leftMargin: CGFloat = defaultLeftMargin {
        didSet {
            diagram.leftMargin = leftMargin
            ladderView.leftMargin = leftMargin
            cursorView.leftMargin = leftMargin
            // Rotation can extend the edge of the view left of the left margin, so
            // we compensate for this here, and whenever left margin is set.
            let offset = self.imageView.frame
            imageScrollView.contentInset.left = self.leftMargin - offset.minX
            imageScrollView.leftMargin = leftMargin
        }
    }

    // Mode is passed to the other views, and setting mode cleans up after each change.
    var mode: Mode = .normal {
        didSet {
            cursorView.cursorIsVisible = false
            cursorView.mode = mode
            ladderView.mode = mode
            imageScrollView.mode = mode
            hamburgerButton.isEnabled = (mode == .normal)
            if mode != .normal {
                ladderView.normalizeLadder()
            }
            switch mode {
            case .normal:
                ladderView.normalizeLadder()
                ladderView.restoreState()
                if ladderView.activeRegion == nil {
                    ladderView.setActiveRegion(regionNum: 0)
                }
                ladderView.endZoning()
                ladderView.removeConnectedMarks()
                showMainToolbar()
            case .select:
                ladderView.saveState()
                ladderView.startZoning()
                showSelectToolbar()
            case .connect:
                showConnectToolbar()
            case .calibrate:
                cursorView.showCalipers()
                showCalibrateToolbar()
            }
            setViewsNeedDisplay()
        }
    }

    var calibration: Calibration {
        get { diagram.calibration }
        set {
            diagram.calibration = newValue
            ladderView.calibration = newValue
            cursorView.calibration = newValue
        }
    }

    var marksAreHidden: Bool {
        get { ladderView.marksAreHidden }
        set {
            ladderView.marksAreHidden = newValue
            cursorView.marksAreHidden = newValue
        }
    }

    // Buttons, toolbars
    let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
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
    var rotateToolbarButtons: [UIBarButtonItem]?
    var pdfToolbarButtons: [UIBarButtonItem]?

    weak var diagramEditorDelegate: DiagramEditorDelegate?
    var currentDocument: DiagramDocument?

    // PDF and launch from URL stuff
    var pdfRef: CGPDFDocument?
    //    var launchFromURL: Bool = false
    //    var launchURL: URL?
    var pageNumber: Int = 1
    var enablePageButtons = false
    var numberOfPages: Int = 0

    // flags to inhibit certain actions when showing these toolbars
    var showingPDFToolbar = false
    var showingRotateToolbar = false

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

    // Sandbox
    var requestSandboxExpansion: Bool = false

    // Diagram preferences
    var playSounds: Bool = true

    // Set by screen delegate
    var restorationInfo: [AnyHashable: Any]?
    var documentIsClosing = false

    // Keys for state restoration
    static let restorationContentOffsetXKey = "restorationContentOffsetXKey"
    static let restorationContentOffsetYKey = "restorationContentOffsetYKey"
    static let restorationZoomKey = "restorationZoomKey"
    static let restorationFileNameKey = "restorationFileNameKey"
    static let restorationDocumentURLKey = "restorationDocumentURLKey"
    static let restorationNeededKey = "restorationNeededKey"
    static let restorationTransformKey = "restorationTranslateKey"
    //    static let restorationActiveRegionIndexKey = "restorationActiveRegionIndexKey"
    static let restorationDoRestorationKey = "restorationDoRestorationKey"
    static let restorationModeKey = "restorationModeKey"
    static let restorationCaliperCrossbarKey = "restorationCaliperCrossbarKey"
    static let restorationCaliperBar1Key = "restorationCaliperBar1Key"
    static let restorationCaliperBar2Key = "restorationCaliperBar2Key"

    static let restorationBookmarkKey = "restorationBookmarkKey"

    // Speed up appearance of image picker by initializing it here.
    let imagePicker: UIImagePickerController = UIImagePickerController()
    private let maxZoom: CGFloat = 7.0
    private let minZoom: CGFloat = 0.2
    let pdfScaleFactor: CGFloat = 5.0

    var activeEndpoint: Mark.Endpoint = .proximal
    var adjustment: Adjustment = .adjust

    // Context menu actions

    // Deletion of marks
    lazy var deleteAction = UIAction(title: L("Delete mark(s)"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
        self.ladderView.deleteSelectedMarks()
    }

    // Linkage
    lazy var unlinkAction = UIAction(title: L("Unlink"), image: UIImage(systemName: "link")) { action in
        self.ladderView.unlinkSelectedMarks()
    }
    lazy var snapAction = UIAction(title: L("Snap to nearby marks"), image: UIImage(systemName: "hare")) { _ in
        self.ladderView.snapSelectedMarks()
    }

    // Block and impulse origin
    lazy var blockProximalAction = UIAction(title: L("Proximal block")) { action in
        self.ladderView.setSelectedMarksBlockSetting(value: .proximal)
    }
    lazy var blockDistalAction = UIAction(title: L("Distal block")) { action in
        self.ladderView.setSelectedMarksBlockSetting(value: .distal)
    }
    lazy var blockNoneAction = UIAction(title: L("No block")) { action in
        self.ladderView.setSelectedMarksBlockSetting(value: .none)
    }
    lazy var blockAutoAction = UIAction(title: L("Auto block")) { action in
        self.ladderView.setSelectedMarksBlockSetting(value: .auto)
    }
    lazy var blockMenu = UIMenu(title: addEllipsisIfNeeded(L("Block")), image: UIImage(systemName: "hand.raised"), children: [self.blockProximalAction, self.blockDistalAction, self.blockNoneAction, self.blockAutoAction])

    lazy var impulseOriginProximalAction = UIAction(title: L("Proximal impulse origin")) { _ in
        self.ladderView.setSelectedMarksImpulseOriginSetting(value: .proximal)
    }

    lazy var impulseOriginDistalAction = UIAction(title: L("Distal impulse origin")) { _ in
        self.ladderView.setSelectedMarksImpulseOriginSetting(value: .distal)

    }
    lazy var impulseOriginNoneAction = UIAction(title: L("No impulse origin")) { _ in
        self.ladderView.setSelectedMarksImpulseOriginSetting(value: .none)
    }

    lazy var impulseOriginAutoAction = UIAction(title: L("Auto impulse origin")) { _ in
        self.ladderView.setSelectedMarksImpulseOriginSetting(value: .auto)
    }
    lazy var impulseOriginMenu = UIMenu(title: addEllipsisIfNeeded(L("Impulse origin")), image: UIImage(systemName: "asterisk.circle"), children: [self.impulseOriginProximalAction, self.impulseOriginDistalAction, self.impulseOriginNoneAction, self.impulseOriginAutoAction])

    // Mark style
    lazy var solidAction = UIAction(title: L("Solid")) { action in
        self.ladderView.setSelectedMarksStyle(style: .solid)
    }
    lazy var dashedAction = UIAction(title: L("Dashed")) { action in
        self.ladderView.setSelectedMarksStyle(style: .dashed)
    }
    lazy var dottedAction = UIAction(title: L("Dotted")) { action in
        self.ladderView.setSelectedMarksStyle(style: .dotted)
    }
    lazy var styleMenu = UIMenu(title: addEllipsisIfNeeded(L("Style")), image: UIImage(systemName: "scribble"), children: [self.solidAction, self.dashedAction, self.dottedAction])

    // Mark labels
    lazy var leftLabelMarkAction = UIAction(title: L("Left")) { action in
        self.ladderView.setSelectedMarksLabel(labelPosition: .left)
    }
    lazy var proximalLabelMarkAction = UIAction(title: L("Proximal")) { action in
        self.ladderView.setSelectedMarksLabel(labelPosition: .proximal)
    }
    lazy var distalLabelMarkAction = UIAction(title: L("Distal")) { action in
        self.ladderView.setSelectedMarksLabel(labelPosition: .distal)
    }
    lazy var labelMarkMenu = UIMenu(title: L("Label"), image: UIImage(systemName: "pencil"), children: [self.leftLabelMarkAction, self.proximalLabelMarkAction, self.distalLabelMarkAction])

    lazy var boldEmphasisAction = UIAction(title: L("Bold")) { action in
        self.ladderView.setSelectedMarksEmphasis(emphasis: .bold)
    }
    lazy var normalEmphasisAction = UIAction(title: L("Normal")) { action in
        self.ladderView.setSelectedMarksEmphasis(emphasis: .normal)
    }
    lazy var emphasisMenu = UIMenu(title: addEllipsisIfNeeded(L("Emphasis")), image: UIImage(systemName: "bold"), children: [self.normalEmphasisAction, self.boldEmphasisAction])

    // Region style
    lazy var regionSolidStyleAction = UIAction(title: L("Solid")) { action in
        self.ladderView.setSelectedRegionsStyle(style: .solid)
    }
    lazy var regionDashedStyleAction = UIAction(title: L("Dashed")) { action in
        self.ladderView.setSelectedRegionsStyle(style: .dashed)
    }
    lazy var regionDottedStyleAction = UIAction(title: L("Dotted")) { action in
        self.ladderView.setSelectedRegionsStyle(style: .dotted)
    }
    lazy var regionInheritedStyleAction = UIAction(title: L("Default")) { action in
        self.ladderView.setSelectedRegionsStyle(style: .inherited)
    }
    lazy var regionStyleMenu = UIMenu(title: L("New mark style"), image: UIImage(systemName: "scribble"), children: [self.regionSolidStyleAction, self.regionDashedStyleAction, self.regionDottedStyleAction, self.regionInheritedStyleAction])

    // Manipulate marks
    lazy var slantProximalPivotAction = UIAction(title: L("Slant proximal pivot point")) { action in
        self.activeEndpoint = .proximal
        self.showSlantToolbar()
    }
    lazy var slantDistalPivotAction = UIAction(title: L("Slant distal pivot point")) { action in
        self.activeEndpoint = .distal
        self.showSlantToolbar()
    }
    lazy var slantMenu = UIMenu(title: addEllipsisIfNeeded(L("Slant mark(s)")), image: UIImage(systemName: "line.diagonal"), children: [self.slantProximalPivotAction, self.slantDistalPivotAction])

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
    lazy var adjustYMenu = UIMenu(title: L("Adjust mark ends"), image: UIImage(systemName: "scissors"), children: [adjustProximalYAction, adjustDistalYAction, trimProximalYAction, trimDistalYAction])


    lazy var straightenToProximalAction = UIAction(title: L("Straighten mark to proximal endpoint")) { action in
        self.ladderView.straightenToEndpoint(.proximal)
    }
    lazy var straightenToDistalAction = UIAction(title: L("Straighten mark to distal endpoint")) { action in
        self.ladderView.straightenToEndpoint(.distal)
    }
    lazy var straightenMenu = UIMenu(title: addEllipsisIfNeeded(L("Straighten mark(s)")), image: UIImage(systemName: "arrow.up.arrow.down"), children: [self.straightenToProximalAction, self.straightenToDistalAction])

    // Rhythm
    lazy var rhythmAction = UIAction(title: L("Rhythm"), image: UIImage(systemName: "waveform.path.ecg")) { action in
        do {
            try self.ladderView.checkForRhythm()
            self.performShowRhythmSegue()
        } catch {
            self.showError(title: L("Error Applying Rhythm"), error: error)
        }
    }

    lazy var repeatCLMenu = UIMenu(title: L("Repeat CL"), image: UIImage(systemName: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right"), children: [self.repeatCLBeforeAction, self.repeatCLAfterAction, self.repeatCLBothAction])

    lazy var repeatCLAfterAction = UIAction(title: L("Repeat CL after")) { _ in
        self.repeatCL(time: .after)
    }
    lazy var repeatCLBeforeAction = UIAction(title: L("Repeat CL before")) { _ in
        self.repeatCL(time: .before)
    }
    lazy var repeatCLBothAction = UIAction(title: L("Repeat CL bidirectionally")) { _ in
        self.repeatCL(time: .both)
    }

    private func repeatCL(time: TemporalRelation) {
        do {
            try self.ladderView.checkForRepeatCL()
            self.ladderView.performRepeatCL(time: time)
        } catch {
            showError(title: L("Error Repeating Cycle Length"), error: error)
        }
    }

    lazy var copyMarksAction = UIAction(title: L("Copy and paste"), image: UIImage(systemName: "doc.on.doc")) { _ in
        self.showCopyMarksToolbar()
        self.ladderView.copyMarks()
    }

    lazy var repeatPatternAction = UIAction(title: L("Repeat pattern"), image: UIImage(systemName: "repeat")) { _ in
        self.repeatPattern()
    }

    /// Add an ellipsis to a menu title for iOS version < 15
    ///
    /// iOS 15 and mac catalyst add a ">" character to submenu titles, so an ellipsis is redundant.
    /// - Parameter string: String to modify
    /// - Returns: String with added ellipsis if needed
    private func addEllipsisIfNeeded(_ string: String) -> String {
        if #unavailable(iOS 15) {
            return string + "..."
        }
        return string
    }

    private func repeatPattern() {
        do {
            self.ladderView.setPatternMarks()
            try self.ladderView.checkForRepeatPattern()
            self.showRepeatPatternToolbar()
        } catch {
            self.showError(title: L("Error Repeating Pattern"), error: error)
            self.ladderView.patternMarks.removeAll()
        }
    }

    lazy var adjustCLAction = UIAction(title: L("Adjust CL"), image: UIImage(systemName: "slider.horizontal.below.rectangle")) { _  in
        do {
            let meanCL = try self.ladderView.meanCL() 
            self.showAdjustCLToolbar(rawValue: meanCL)
        } catch {
            self.showError(title: L("Error Adjusting Cycle Length"), error: error)
        }
    }

    lazy var moveAction = UIAction(title: L("Move marks"), image: UIImage(systemName: "arrow.right.arrow.left")) { _ in
        do {
            try self.ladderView.checkForMovement()
            self.showMoveMarksToolbar()
        } catch {
            self.showError(title: L("Error Moving Marks"), error: error)
        }
    }

    // Period actions
    lazy var editPeriodsAction = UIAction(title: L("Add/edit periods"), image: UIImage(systemName: "plus.rectangle.on.rectangle")) { _ in
        do {
            try self.ladderView.checkForEditablePeriods()
            self.performEditPeriodsSegue()
        } catch {
            self.showError(title: L("Error Editing Periods"), error: error)
        }
    }

    lazy var copyPeriodsAction = UIAction(title: "Copy periods", image: UIImage(systemName: "rectangle.stack")) { _ in
        do {
            try self.ladderView.checkForCopyablePeriods()
            self.performSelectPeriodsSegue()
        } catch {
            self.showError(title: L("Error Copying Periods"), error: error)
        }
    }

    lazy var deletePeriodsAction = UIAction(title: L("Delete period(s)"), image: UIImage(systemName: "rectangle.on.rectangle.slash"), attributes: .destructive) { _ in
        self.ladderView.deletePeriods()
    }

    lazy var periodsMenu = UIMenu(title: addEllipsisIfNeeded(L("Periods")), image: UIImage(systemName: "rectangle.on.rectangle"), children: [self.editPeriodsAction, self.copyPeriodsAction, self.deletePeriodsAction])

    // Label actions
    lazy var editLabelAction = UIAction(title: L("Edit label"), image: UIImage(systemName: "pencil")) { action in
        self.editLabel()
    }

    lazy var adjustLeftMarginAction = UIAction(title: L("Adjust left margin"), image: UIImage(systemName: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right")) { action in
        self.showAdjustLeftMarginToolbar()
    }


    // Region height
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
    lazy var regionHeightMenu = UIMenu(title: L("Region height"), image: UIImage(systemName: "arrow.up.arrow.down.square"), children: [self.oneRegionHeightAction, self.twoRegionHeightAction, self.threeRegionHeightAction, self.fourRegionHeightAction])

    // Delete or add region
    lazy var addRegionAboveAction = UIAction(title: L("Add region above")) { action in
        self.ladderView.addRegion(relation: .before)
    }
    lazy var addRegionBelowAction = UIAction(title: L("Add region below")) { action in
        self.ladderView.addRegion(relation: .after)
    }
    lazy var addRegionMenu = UIMenu(title: addEllipsisIfNeeded(L("Add Region")), image: UIImage(systemName: "plus"), children: [self.addRegionAboveAction, self.addRegionBelowAction])

    lazy var removeRegionAction = UIAction(title: L("Remove region"), image: UIImage(systemName: "minus")) { action in
        self.ladderView.removeRegion()
    }

    lazy var markMenu = UIMenu(title: L("Mark Menu"), children: [self.styleMenu, self.emphasisMenu, self.impulseOriginMenu, self.blockMenu, self.labelMarkMenu, self.straightenMenu, self.slantMenu, self.adjustYMenu, self.moveAction, self.adjustCLAction, self.rhythmAction, self.repeatCLMenu, self.copyMarksAction, self.repeatPatternAction, self.unlinkAction, self.snapAction, self.periodsMenu, self.deleteAction])

    lazy var labelMenu = [self.regionStyleMenu, self.editLabelAction, self.addRegionMenu, self.removeRegionAction, self.regionHeightMenu, self.adjustLeftMarginAction]

    lazy var noSelectionAction = UIAction(title: L("No regions, zones, or marks selected")) { _ in }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        os_log("viewDidLoad() - ViewController", log: OSLog.viewCycle, type: .info)
        super.viewDidLoad()

        //print("userInfo", restorationInfo as Any)

        // Setup cursor, ladder and image scroll views.
        // These 2 views are guaranteed to exist, so the delegates are implicitly unwrapped optionals.
        cursorView.ladderViewDelegate = ladderView
        ladderView.cursorViewDelegate = cursorView

        // Current document needed to access UndoManager.
        cursorView.currentDocument = currentDocument
        ladderView.currentDocument = currentDocument

        leftMargin = diagram.ladder.leftMargin

        // init views
        calibration = diagram.calibration
        cursorView.calibration = diagram.calibration
        ladderView.calibration = diagram.calibration
        ladderView.ladder = diagram.ladder

        imageView.image = scaleImageForImageView(diagram.image)
        ladderView.viewMaxWidth = imageView.frame.width

        imageScrollView.delegate = self

        // Distinguish the two views using slightly different background colors.
        imageScrollView.backgroundColor = UIColor.secondarySystemBackground
        imageView.backgroundColor = UIColor.secondarySystemBackground
        ladderView.backgroundColor = UIColor.systemBackground

        // Limit max and min scale of image.
        imageScrollView.maximumZoomScale = maxZoom
        imageScrollView.minimumZoomScale = minZoom
        imageScrollView.diagramViewControllerDelegate = self

        mode = .normal

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
        #if !targetEnvironment(macCatalyst)
        hamburgerButton = UIBarButtonItem(image: UIImage(named: "hamburger"), style: .plain, target: self, action: #selector(toggleHamburgerMenu))
        navigationItem.setLeftBarButton(hamburgerButton, animated: true)
        let snapshotButton = UIBarButtonItem(image: UIImage(systemName: "photo.on.rectangle"), style: .plain, target: self, action: #selector(snapshotDiagram))
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .done, target: self, action: #selector(closeDocument))
        navigationItem.setRightBarButtonItems([closeButton, snapshotButton], animated: true)
        #endif

        let backButton = UIBarButtonItem(title: L("Done"), style: .done, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton

        // Set up touches
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        imageScrollView.addGestureRecognizer(singleTapRecognizer)

        // Context menus
        let interaction = UIContextMenuInteraction(delegate: self)
        ladderView.addInteraction(interaction)

        #if targetEnvironment(macCatalyst) // context menu works better on Mac here
        let imageInteraction = UIContextMenuInteraction(delegate: imageScrollView)
        imageScrollView.addInteraction(imageInteraction)
        #else
        // We use a long press menu for the image, to avoid the view jumping around during normal scrolling, zooming.
        // Yes, we tried using UIContextMenuInteraction, but it was unusable for iOS.
        let longPressRecognizer = UILongPressGestureRecognizer(target: self.imageScrollView, action: #selector(imageScrollView.showImageMenu))
        imageScrollView.addGestureRecognizer(longPressRecognizer)
        #endif

        ladderView.reregisterAllMarks()

        setupNotifications()

        let firstRun: Bool = !UserDefaults.standard.bool(forKey: Preferences.notFirstRunKey)

        if debugForceOnboarding || firstRun { // || first run
            performShowOnboardingSegue()
            UserDefaults.standard.set(true, forKey: Preferences.notFirstRunKey)
            // take this oportunity to save the version, which we can use in the future to determine if we nee to reshow the onboarding (e.g. if onboarding changes).
            if let version = Version.version {
                UserDefaults.standard.set(version, forKey: Preferences.versionKey)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        os_log("viewWillAppear() - ViewController", log: OSLog.viewCycle, type: .info)
        super.viewWillAppear(animated)

        // Need to show toolbar before view appears, otherwise views don't layout correctly.
        #if targetEnvironment(macCatalyst)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        #else
        navigationController?.setNavigationBarHidden(false, animated: animated)
        #endif
        navigationController?.setToolbarHidden(false, animated: animated)

        // Fixes view opening flush with left margin on Mac.
        // However, this triggers UITableViewAlertForLayoutOutsideViewHierarchy breakpoint
        // for both macOS and iOS versions.
        // Probably safe to ignore this.  Moving this statement elsewhere doesn't work.
        self.view.layoutIfNeeded()
    }

    var didFirstWillLayout = false
    override func viewWillLayoutSubviews() {
        os_log("viewWillLayoutSubviews() - DiagramViewController", log: OSLog.viewCycle, type: .info)
        getImageViewHeight()
        if didFirstWillLayout {
            super.viewWillLayoutSubviews()
            return
        }
        didFirstWillLayout = true
        if restorationInfo != nil {
            if let zoomScale = restorationInfo?[Self.restorationZoomKey] as? CGFloat {
                imageScrollView.zoomScale = zoomScale
            }
            var restorationContentOffset = CGPoint()
            if let contentOffsetX = restorationInfo?[Self.restorationContentOffsetXKey] {
                restorationContentOffset.x = (contentOffsetX as? CGFloat ?? 0) * imageScrollView.zoomScale
            }
            if let contentOffsetY = restorationInfo?[Self.restorationContentOffsetYKey] {
                restorationContentOffset.y = contentOffsetY as? CGFloat ?? 0
            }
            imageScrollView.setContentOffset(restorationContentOffset, animated: true)
        }
        super.viewWillLayoutSubviews()
    }

    override func viewDidAppear(_ animated: Bool) {
        os_log("viewDidAppear() - ViewController", log: OSLog.viewCycle, type: .info)
        super.viewDidAppear(animated)

        #if targetEnvironment(macCatalyst)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let plugin = appDelegate.appKitPlugin {
                if let nsWindow = view.window?.nsWindow {
                    plugin.disableCloseButton(nsWindow: nsWindow)
                }
            }
        }

        if requestSandboxExpansion {
            addDirectoryToSandbox(self)
        }
        #else
        // FIXME: Temporary -- why?
        if requestSandboxExpansion {
            addIOSDirectoryToSandbox()
        }
        #endif

        #if !targetEnvironment(macCatalyst)
        if let currentDocument = currentDocument {
            let directoryURL = currentDocument.fileURL.deletingLastPathComponent()
            Sandbox.storeDirectoryBookmark(from: directoryURL)
        }
        #endif

        setTitle()

        self.userActivity = self.view.window?.windowScene?.userActivity
        self.userActivity?.delegate = self
        self.restorationInfo = nil
        // See https://github.com/mattneub/Programming-iOS-Book-Examples/blob/master/bk2ch06p357StateSaveAndRestoreWithNSUserActivity/ch19p626pageController/SceneDelegate.swift

        UIView.animate(withDuration: 0.4) {
            self.imageView.transform = self.diagram.transform
        }
        scrollViewAdjustViews(imageScrollView) // make sure views adjust to rotated image
        ladderView.updateLadderIntervals()
        // Need to set this here, after view draw, or Mac malpositions cursor at start of app.
        let offset = self.imageView.frame
        imageScrollView.contentInset = UIEdgeInsets(top: 0, left: leftMargin - offset.minX, bottom: 0, right: 0)
        updateToolbarButtons()
        updateUndoRedoButtons()
        resetViews(setActiveRegion: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // No need anymore (since iOS9) to remove notifications.
    }

    deinit {
        os_log("deinit - DiagramViewController", log: .debugging, type: .debug)
    }

    func addIOSDirectoryToSandbox() {
        print("addIOSDirectoryToSandbox")
    }

    override func updateUserActivityState(_ activity: NSUserActivity) {
        //os_log("debug: diagramViewController updateUserActivityState called", log: .debugging, type: .debug)

        super.updateUserActivityState(activity)

        let info: [AnyHashable: Any] = [
            Self.restorationContentOffsetXKey: imageScrollView.contentOffset.x / imageScrollView.zoomScale,
            Self.restorationContentOffsetYKey: imageScrollView.contentOffset.y,
            Self.restorationZoomKey: imageScrollView.zoomScale,
            Self.restorationDoRestorationKey: true,
            Self.restorationTransformKey: NSCoder.string(for: imageView.transform),
            Self.restorationDocumentURLKey: currentDocument?.fileURL ?? "",
        ]
        activity.addUserInfoEntries(from: info)
    }

    func loadSampleDiagram(_ diagram: Diagram) {
        currentDocument?.undoManager.beginUndoGrouping()
        undoablySetCalibration(Calibration())
        undoablySetLadder(diagram.ladder)
        undoablySetDiagramImage(diagram.image, imageIsUpscaled: false, transform: .identity, scale: 1.0, contentOffset: .zero)
        currentDocument?.undoManager.endUndoGrouping()
        ladderView.activeRegion = ladderView.ladder.regions[0]
        // We can't change mode here, because changing mode restores state, and may put as the active region a region that no longer exists.  But as we can only load sample diagrams from normal mode, there is no need to change mode.
    }

    func setTitle() {
        var titleLabel = L("EP Diagram")
        if let name = currentDocument?.name(), !name.isEmpty {
            #if targetEnvironment(macCatalyst)
            titleLabel = L("EP Diagram - \(name)")
            #else
            titleLabel = isIPad() ? L("EP Diagram - \(name)") : name
            #endif
        }
        title = titleLabel
        #if targetEnvironment(macCatalyst)
        view.window?.windowScene?.title = titleLabel
        #endif
    }

    // MARK: Toolbars, Modes

    @objc func showMainToolbar() {
        if mainToolbarButtons == nil {
            calibrateButton = UIBarButtonItem(title: L("Calibrate"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(launchCalibrateMode))
            selectButton = UIBarButtonItem(title: L("Edit"), style: .plain, target: self, action: #selector(launchSelectMode))
            connectButton = UIBarButtonItem(title: L("Connect"), style: .plain, target: self, action: #selector(launchConnectMode))
            undoButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(undo))
            redoButton = UIBarButtonItem(barButtonSystemItem: .redo, target: self, action: #selector(redo))
            #if targetEnvironment(macCatalyst)
            mainToolbarButtons = [calibrateButton, spacer,  connectButton, spacer, selectButton]
            #else
            mainToolbarButtons = [calibrateButton, spacer,  connectButton, spacer, selectButton, spacer, undoButton, spacer, redoButton]
            #endif


        }
        setToolbarItems(mainToolbarButtons, animated: false)
    }

    @objc func launchSelectMode(_: UIAlertAction) {
        mode = .select
    }

    func showSelectToolbar() {
        if selectToolbarButtons == nil {
            let selectAllButton = UIBarButtonItem(title: L("Select All"), style: .plain, target: self, action: #selector(selectAllMarks))
            let clearButtonTitle = isIPad() ? L("Clear Selection") : L("Clear")
            let clearButton = UIBarButtonItem(title: clearButtonTitle, style: .plain, target: self, action: #selector(clearSelection))
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancelSelectMode))
            #if targetEnvironment(macCatalyst)
            selectToolbarButtons = [selectAllButton, spacer, clearButton, spacer, doneButton]
            #else
            selectToolbarButtons = [selectAllButton, spacer, clearButton, spacer, undoButton, spacer, redoButton, spacer, doneButton]
            #endif
        }
        setToolbarItems(selectToolbarButtons, animated: false)
    }

    @objc func selectAllMarks() {
        ladderView.selectAllMarks()
    }

    @objc func clearSelection() {
        ladderView.clearSelection()
    }

    @objc func cancelSelectMode() {
        os_log("cancelSelect()", log: OSLog.action, type: .info)
        ladderView.restoreState()
        mode = .normal
    }

    @objc func launchConnectMode() {
        os_log("connectMarks()", log: .action, type: .info)
        mode = .connect
    }

    func showConnectToolbar() {
        if connectToolbarButtons == nil {
            #if targetEnvironment(macCatalyst)
            let labelText = L("Click pairs of marks to connect them")
            #else
            let labelText = isIPad() ? L("Tap pairs of marks to connect them") : L("Tap pairs of marks")
            #endif
            let prompt = makePrompt(text: labelText)
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancelConnectMode))
            #if targetEnvironment(macCatalyst)
            connectToolbarButtons = [prompt, spacer, doneButton]
            #else
            connectToolbarButtons = [prompt, spacer, undoButton, spacer, redoButton, spacer, doneButton]
            #endif

        }
        setToolbarItems(connectToolbarButtons, animated: false)
    }

    @objc func cancelConnectMode() {
        os_log("cancelConnectMode()", log: OSLog.action, type: .info)
        mode = .normal
    }

    func showAdjustCLToolbar(rawValue: CGFloat) {
        guard let toolbar = navigationController?.toolbar else { return }
        currentDocument?.undoManager.beginUndoGrouping()
        ladderView.unlinkAllMarks()
        let labelText = UITextField()
        labelText.text = L("Adjust cycle length")
        let slider = UISlider()
        slider.minimumValue = Float(ladderView.regionValueFromCalibratedValue(Rhythm.minimumCL, usingCalFactor: calibration.currentCalFactor))
        slider.maximumValue = Float(ladderView.regionValueFromCalibratedValue(Rhythm.maximumCL, usingCalFactor: calibration.currentCalFactor))
        slider.setValue(Float(rawValue), animated: false)
        ladderView.adjustCL(cl: rawValue)
        slider.addTarget(self, action: #selector(clSliderValueDidChange(_:)), for: .valueChanged)
        let doneButton = UIButton(type: .close)
        doneButton.addTarget(self, action: #selector(closeAdjustCLToolbar(_:)), for: .touchUpInside)
        let stackView = UIStackView(frame: toolbar.frame)
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = stackViewSpacing
        stackView.addArrangedSubview(labelText)
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(doneButton)
        setToolbarItems([UIBarButtonItem(customView: stackView)], animated: true)
        imageScrollView.isActivated = false
    }

    func showCopyMarksToolbar() {
        guard let toolbar = navigationController?.toolbar else { return }
        currentDocument?.undoManager?.beginUndoGrouping()
        ladderView.unlinkAllMarks()
        let labelText = UITextField()
        labelText.text = isRunningOnMac() ? L("Click to paste marks") : L("Tap to paste marks")
        let doneButton = UIButton(type: .close)
        doneButton.addTarget(self, action: #selector(closeCopyMarksToolbar(_:)), for: .touchUpInside)
        let stackView = UIStackView(frame: toolbar.frame)
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = stackViewSpacing
        stackView.addArrangedSubview(labelText)
        stackView.addArrangedSubview(doneButton)
        setToolbarItems([UIBarButtonItem(customView: stackView)], animated: true)
        imageScrollView.isActivated = false
    }

    func showRepeatPatternToolbar() {
        guard let toolbar = navigationController?.toolbar else { return }
        currentDocument?.undoManager.beginUndoGrouping()
        ladderView.unlinkAllMarks()
        let labelText = UITextField()
        #if targetEnvironment(macCatalyst)
        labelText.text = L("Click joining mark once for a single copy, double-click for multiple copies")
        #else
        labelText.text = isIPad() ? L("Tap joining mark once for single copy, double tap for multiple copies") : L("Single or double tap joining mark")
        #endif
        let doneButton = UIButton(type: .close)
        doneButton.addTarget(self, action: #selector(closeRepeatPatternToolbar(_:)), for: .touchUpInside)
        let stackView = UIStackView(frame: toolbar.frame)
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = stackViewSpacing
        stackView.addArrangedSubview(labelText)
        stackView.addArrangedSubview(doneButton)
        setToolbarItems([UIBarButtonItem(customView: stackView)], animated: true)
        imageScrollView.isActivated = false
    }

    func showMoveMarksToolbar() {
        guard let toolbar = navigationController?.toolbar else { return }
        currentDocument?.undoManager.beginUndoGrouping()
        ladderView.unlinkAllMarks()
        let labelText = UITextField()
        labelText.text = L("Drag selected marks")
        ladderView.isDraggingSelectedMarks = true
        let doneButton = UIButton(type: .close)
        doneButton.addTarget(self, action: #selector(closeMoveMarksToolbar(_:)), for: .touchUpInside)
        let stackView = UIStackView(frame: toolbar.frame)
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = stackViewSpacing
        stackView.addArrangedSubview(labelText)
        stackView.addArrangedSubview(doneButton)
        setToolbarItems([UIBarButtonItem(customView: stackView)], animated: true)
        imageScrollView.isActivated = false
    }

    func showSlantToolbar() {
        guard let toolbar = navigationController?.toolbar else { return }
        currentDocument?.undoManager.beginUndoGrouping()
        ladderView.unlinkAllMarks()
        let labelText = UITextField()
        labelText.text = L("Adjust mark slant")
        let slider = UISlider()
        slider.minimumValue = Self.minSlantAngle
        slider.maximumValue = Self.maxSlantAngle
        if let soleSelectedMark = ladderView.soleSelectedMark() {
            let slantAngle = ladderView.slantAngle(mark: soleSelectedMark, endpoint: activeEndpoint)
            slider.setValue(Float(slantAngle), animated: false)
        } else {
            slider.setValue(0, animated: false)
            ladderView.slantSelectedMarks(angle: 0, endpoint: activeEndpoint)
        }
        slider.addTarget(self, action: #selector(slantSliderValueDidChange(_:)), for: .valueChanged)
        let doneButton = UIButton(type: .close)
        doneButton.addTarget(self, action: #selector(closeSlantToolbar(_:)), for: .touchUpInside)
        let stackView = UIStackView(frame: toolbar.frame)
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = stackViewSpacing
        stackView.addArrangedSubview(labelText)
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(doneButton)
        setToolbarItems([UIBarButtonItem(customView: stackView)], animated: true)
        imageScrollView.isActivated = false
    }

    func showAdjustLeftMarginToolbar() {
        guard let toolbar = navigationController?.toolbar else { return }
        currentDocument?.undoManager.beginUndoGrouping() // will end when menu closed
        let labelText = UITextField()
        labelText.text = L("Adjust left margin")
        let slider = UISlider()
        slider.minimumValue = Self.minLeftMargin
        slider.maximumValue = Self.maxLeftMargin
        slider.setValue(Float(leftMargin), animated: false)
        slider.addTarget(self, action: #selector(leftMarginSliderValueDidChange(_:)), for: .valueChanged)
        let doneButton = UIButton(type: .close)
        doneButton.addTarget(self, action: #selector(closeAdjustLeftMarginToolbar(_:)), for: .touchUpInside)
        let stackView = UIStackView(frame: toolbar.frame)
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = stackViewSpacing
        stackView.addArrangedSubview(labelText)
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(doneButton)
        setToolbarItems([UIBarButtonItem(customView: stackView)], animated: true)
        imageScrollView.isActivated = false
    }

    func showAdjustYToolbar() {
        guard let toolbar = navigationController?.toolbar else { return }
        currentDocument?.undoManager.beginUndoGrouping() // will end when menu closed
        ladderView.unlinkAllMarks()
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
        let doneButton = UIButton(type: .close)
        doneButton.addTarget(self, action: #selector(closeAdjustYToolbar(_:)), for: .touchUpInside)
        let stackView = UIStackView(frame: toolbar.frame)
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = stackViewSpacing
        stackView.addArrangedSubview(labelText)
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(doneButton)
        setToolbarItems([UIBarButtonItem(customView: stackView)], animated: true)
        imageScrollView.isActivated = false
    }

    @objc func adjustYSliderValueDidChange(_ sender: UISlider) {
        let value: CGFloat = CGFloat(sender.value)
        ladderView.adjustY(value, endpoint: activeEndpoint, adjustment: adjustment)
        ladderView.refresh()
    }

    @objc func clSliderValueDidChange(_ sender: UISlider) {
        let value: CGFloat = CGFloat(sender.value)
        ladderView.adjustCL(cl: value)
        ladderView.refresh()
    }

    @objc func closeMoveMarksToolbar(_ sender: UISlider) {
        ladderView.relinkAllMarks()
        currentDocument?.undoManager.endUndoGrouping()
        ladderView.isDraggingSelectedMarks = false
        showSelectToolbar()
        imageScrollView.isActivated = true
    }

    @objc func closeAdjustCLToolbar(_ sender: UISlider) {
        ladderView.relinkAllMarks()
        currentDocument?.undoManager.endUndoGrouping()
        showSelectToolbar()
        imageScrollView.isActivated = true
    }

    @objc func closeCopyMarksToolbar(_ sender: UIAlertAction) {
        self.ladderView.copiedMarks.removeAll()
        ladderView.relinkAllMarks()
        currentDocument?.undoManager.endUndoGrouping()
        showSelectToolbar()
        imageScrollView.isActivated = true
    }

    @objc func closeRepeatPatternToolbar(_ sender: UIAlertAction) {
        ladderView.relinkAllMarks()
        currentDocument?.undoManager.endUndoGrouping()
        self.ladderView.patternMarks = []
        showSelectToolbar()
        imageScrollView.isActivated = true
    }

    @objc func closeSlantToolbar(_ sender: UIAlertAction) {
        ladderView.relinkAllMarks()
        currentDocument?.undoManager.endUndoGrouping()
        showSelectToolbar()
        imageScrollView.isActivated = true
    }

    @objc func closeAdjustYToolbar(_ sender: UIAlertAction) {
        ladderView.swapEndpointsIfNeededOfAllMarks()
        ladderView.relinkAllMarks()
        currentDocument?.undoManager.endUndoGrouping()
        showSelectToolbar()
        imageScrollView.isActivated = true
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


    func makePrompt(text: String) -> UIBarButtonItem {
        let prompt = UILabel()
        prompt.text = text
        return UIBarButtonItem(customView: prompt)
    }

    // MARK: -  Actions

    @objc func closeDocument() {
        os_log("closeDocument()", log: .action, type: .info)
        if let separatorView = separatorView {
            separatorView.removeFromSuperview()
            self.separatorView = nil
        }
        view.endEditing(true)
        documentIsClosing = true
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

    func showCalibrateToolbar() {
        if calibrateToolbarButtons == nil {
            let promptButton = makePrompt(text: L("Set caliper to 1000 ms"))
            let setButton = UIBarButtonItem(title: L("Set"), style: .plain, target: self, action: #selector(setCalibration))
            let clearButton = UIBarButtonItem(title: L("Clear"), style: .plain, target: self, action: #selector(clearCalibration))
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancelCalibrateMode))
            calibrateToolbarButtons = [promptButton, spacer, setButton, spacer, clearButton, spacer, doneButton]
        }
        setToolbarItems(calibrateToolbarButtons, animated: false)
    }

    @objc func setCalibration() {
        os_log("setCalibration()", log: .action, type: .info)
        let newCalibration = cursorView.newCalibration(zoom: imageScrollView.zoomScale)
        undoablySetCalibration(newCalibration)
        ladderView.updateLadderIntervals()
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
        showSelectToolbar()
        imageScrollView.isActivated = true
    }

    @objc func undo(_ sender: Any) {
        os_log("undo action", log: OSLog.action, type: .info)
        if self.currentDocument?.undoManager?.canUndo ?? false {
            // Cursor doesn't track undo and redo well, so hide it!
            if mode == .normal {
                hideCursorAndNormalizeAllMarks()
            }
            self.currentDocument?.undoManager?.undo()
            setViewsNeedDisplay()
        }
    }

    @objc func redo(_ sender: Any) {
        os_log("redo action", log: OSLog.action, type: .info)
        if self.currentDocument?.undoManager?.canRedo ?? false {
            if mode == .normal {
                hideCursorAndNormalizeAllMarks()
            }
            self.currentDocument?.undoManager?.redo()
            setViewsNeedDisplay()
        }
    }


    func editLabel() {
        guard let selectedRegion = ladderView.selectedLabelRegion() else { return }
        UserAlert.showEditRegionLabelAlert(viewController: self, region: selectedRegion, handler: { newLabel, newDescription in
            self.ladderView.undoablySetLabel(newLabel, description: newDescription, forRegion: selectedRegion)
        })
    }

    func showError(title: String, error: Error) {
        var message = error.localizedDescription
        if error is LadderError {
            if let ladderError = error as? LadderError {
                message = ladderError.localizedDescription
            }
        }
        UserAlert.showMessage(viewController: self, title: title, message: message)
        os_log("ERROR: %s, %s", log: .errors, type: .error, title, message)
    }


    // MARK: - Touches

    // Taps to cursor and ladder view are absorbed by cursor view and ladder view.
    // Single tap to image (not near mark) adds mark with cursor if no mark attached.
    // Single tap to image with mark attached unattaches mark.
    // Double tap to image, with attached mark:
    //    First tap unattaches mark, second tap adds mark with cursor.
    //    - without attached mark:
    //    First tap adds attached mark, second shifts anchor.
    @objc func singleTap(tap: UITapGestureRecognizer) {
        os_log("singleTap - ViewController", log: OSLog.touches, type: .info)
        guard !marksAreHidden else { return }
        guard ladderView.isActivated else { return }
        if cursorView.mode == .calibrate {
            return
        }
        if ladderView.mode == .select {
            ladderView.endZoning()
            ladderView.normalizeRegions()
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
                if position.x >= 0 { // negative position in left margin
                    cursorView.addMarkWithAttachedCursor(positionX: position.x)
                }
            }
            setViewsNeedDisplay()
        }
    }

    // MARK: - Handle PDFs, URLs at app startup

    func openURL(url: URL) {
        os_log("openURL action", log: OSLog.action, type: .info)

        let ext = url.pathExtension.uppercased()
        if ext != "PDF" {
            self.enablePageButtons = false
            undoablySetDiagramImageAndResetLadder(UIImage(contentsOfFile: url.path), imageIsUpscaled: false, transform: .identity, scale: 1.0, contentOffset: .zero)
        }
        else {
            self.numberOfPages = 0
            let urlPath = url.path as NSString
            let tmpPDFRef: CGPDFDocument? = getPDFDocumentRef(urlPath.utf8String)
            if tmpPDFRef == nil {
                return
            }
            self.clearPDF()
            pdfRef = tmpPDFRef
            if let pdfRef = pdfRef {
                self.numberOfPages = pdfRef.numberOfPages
            }
            // always start with page number 1
            self.pageNumber = 1
            enablePageButtons = (numberOfPages > 1)
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

    func openPDFPage(_ documentRef: CGPDFDocument?, atPage pageNum: Int) {
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
                undoablySetDiagramImageAndResetLadder(rescaledImage, imageIsUpscaled: true, transform: .identity, scale: 1.0, contentOffset: .zero)
            }
            UIGraphicsEndImageContext()
        }
    }

    private func getPDFPage(_ document: CGPDFDocument, pageNumber: Int) -> CGPDFPage? {
        return document.page(at: pageNumber)
    }

    func getPageNumber() {
        let gotoPageAlertController = UIAlertController(title: L("Goto page"), message: nil, preferredStyle: .alert)
        gotoPageAlertController.addTextField(configurationHandler: { textField in
            let currentPage: String = String.localizedStringWithFormat("%i", self.pageNumber)
            textField.text = currentPage
            textField.tag = self.gotoTextFieldTag
            textField.delegate = self
            textField.clearButtonMode = .always
            textField.keyboardType = .numberPad
        })
        let cancelAction = UIAlertAction(title: L("Cancel"), style: .cancel, handler: { _ in self.showPDFToolbar() })
        let gotoAction = UIAlertAction(title: L("OK"), style: .default) { _ in
            let textFields = gotoPageAlertController.textFields
            if let rawTextField = textFields?[0] {
                if var page = Int(rawTextField.text ?? "1") {
                    if page > self.numberOfPages {
                        page = self.numberOfPages
                    }
                    if page < 1 {
                        page = 1
                    }
                    self.pageNumber = page;
                    //            [self enablePageButtons:YES];
                    self.openPDFPage(self.pdfRef, atPage: self.pageNumber)
                }
            }
        }
        gotoPageAlertController.addAction(cancelAction)
        gotoPageAlertController.addAction(gotoAction)
        present(gotoPageAlertController, animated: true)
    }

    func clearPDF() {
        pageNumber = 0
        numberOfPages = 0
    }

    #if targetEnvironment(macCatalyst)

    // Not used
    @IBAction func selectDiagram(_ sender: Any) {
        let supportedTypes: [UTType] = [UTType.image, UTType.pdf]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        documentPicker.delegate = self

        // Set the initial directory.
        documentPicker.directoryURL = FileIO.getDocumentsURL()

        // Present the document picker.
        present(documentPicker, animated: true, completion: nil)    }
    #endif


    // MARK: - Rotate screen

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        os_log("viewWillTransition", log: OSLog.viewCycle, type: .info)
        super.viewWillTransition(to: size, with: coordinator)
        // Hide cursor with rotation, to avoid redrawing it, but only if in normal mode.
        if mode == .normal {
            hideCursorAndNormalizeAllMarks()
        }
        // Remove separatorView when rotating to let original constraints resume.
        // Otherwise, views are not laid out correctly.
        if let separatorView = separatorView {
            separatorView.removeFromSuperview()
            self.separatorView = nil
        }
        coordinator.animate(alongsideTransition: nil, completion: {
            _ in
            self.resetViews()
        })
    }

    private func resetViews(setActiveRegion: Bool = true) {
        os_log("resetViews() - ViewController", log: .action, type: .info)
        // Add back in separatorView after rotation.
        if (separatorView == nil) {
            separatorView = HorizontalSeparatorView.addSeparatorBetweenViews(primaryView: imageScrollView, secondaryView: ladderView, parentView: self.view)
            separatorView?.cursorViewDelegate = cursorView
        }
        self.ladderView.resetSize(setActiveRegion: setActiveRegion, width: imageView.frame.width)
        cursorView.caliperMaxY = imageScrollView.frame.height
        cursorView.caliperMinY = 0
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
        navigationController?.setToolbarHidden(true, animated: false)
        let ladderTemplatesModelController = LadderTemplatesModelController(viewController: self)
        let templateEditor = LadderTemplatesEditor(ladderTemplatesController: ladderTemplatesModelController)
        let hostingController = UIHostingController(coder: coder, rootView: templateEditor)
        return hostingController
    }

    @IBSegueAction func showLadderSelector(_ coder: NSCoder) -> UIViewController? {
        os_log("showLadderSelector")
        navigationController?.setToolbarHidden(true, animated: false)
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
        navigationController?.setToolbarHidden(true, animated: false)
        let diagramModelController = DiagramModelController(diagram: diagram, diagramViewController: self)
        let preferencesView = PreferencesView(diagramController: diagramModelController)
        let hostingController = UIHostingController(coder: coder, rootView: preferencesView)
        return hostingController
    }

    @IBSegueAction func showSampleSelector(_ coder: NSCoder) -> UIViewController? {
        navigationController?.setToolbarHidden(true, animated: false)
        let sampleSelector = SampleSelector(sampleDiagrams: Diagram.sampleDiagrams(), delegate: self)
        let hostingController = UIHostingController(coder: coder, rootView: sampleSelector)
        return hostingController
    }

    @IBSegueAction func performShowHelpSegueAction(_ coder: NSCoder) -> HelpViewController? {
        navigationController?.setToolbarHidden(true, animated: false)
        let helpViewController = HelpViewController(coder: coder)
        return helpViewController
    }

    @IBSegueAction func performSelectPeriodsAction(_ coder: NSCoder) -> UIViewController? {
        let periodSelector = PeriodSelector(dismissAction: ladderView.setPeriods, periods: .constant(ladderView.ladder.getUniqueLadderPeriods()))
        let hostingController = UIHostingController(coder: coder, rootView: periodSelector)
        return hostingController
    }
    
    @IBSegueAction func performEditPeriodsAction(_ coder: NSCoder) -> UIViewController? {
        let periodsEditor = PeriodListEditor(dismissAction: applyPeriods, periodsModelController: ladderView.periodsModelController)
        let hostingController = UIHostingController(coder: coder, rootView: periodsEditor)
        return hostingController
    }

    @IBSegueAction func performRhythmSegueAction(_ coder: NSCoder) -> UIViewController? {
        // Have to provide dismiss action to SwiftUI modal view.  It won't dismiss itself.
        let rhythmView = RhythmView(dismissAction: applyRhythm(rhythm:cancel:))
        let hostingController = UIHostingController(coder: coder, rootView: rhythmView)
        return hostingController
    }

    @IBSegueAction func performOnboardingSegueAction(_ coder: NSCoder) -> UIViewController? {
        guard let url = Bundle.main.url(
                forResource: isRunningOnMac() ? "maconboard" : "onboard",
                withExtension: "html")
        else { return nil }
        do {
            let contents = try String(contentsOf: url)
            let onboardingView = Onboarding(onboardText: .constant(contents), url: url)
            return UIHostingController(coder: coder, rootView: onboardingView)
        } catch {
            return nil
        }
    }

    func applyRhythm(rhythm: Rhythm, cancel: Bool) {
        print(rhythm)
        if !cancel {
            ladderView.fillWithRhythm(rhythm)
        }
        self.dismiss(animated: true, completion: nil)
    }

    func applyPeriods(periods: [Period], cancel: Bool) {
        if !cancel {
             ladderView.applyPeriods(periods)
        }
    }

    func performShowRhythmSegue() {
        performSegue(withIdentifier: "showRhythmSegue", sender: self)
    }

    func performSelectLadderSegue() {
        performSegue(withIdentifier: "selectLadderSegue", sender: self)
    }

    func performEditPeriodsSegue() {
        performSegue(withIdentifier: "editPeriodsSegue", sender: self)
    }

    func performSelectPeriodsSegue() {
        performSegue(withIdentifier: "selectPeriodsSegue", sender: self)
    }

    func performShowSampleSelectorSegue() {
        performSegue(withIdentifier: "showSampleSelectorSegue", sender: self)
    }

    func performShowHelpSegue() {
        P("performShowHelpSegue")
        performSegue(withIdentifier: "showHelpSegue", sender: self)
    }

    func performShowOnboardingSegue() {
        performSegue(withIdentifier: "showOnboardingSegue", sender: self)
    }

    func performShowPreferencesSegue() {
        performSegue(withIdentifier: "showPreferencesSegue", sender: self)
    }

    func performShowTemplateEditorSegue() {
        performSegue(withIdentifier: "showTemplateEditorSegue", sender: self)
    }

}

#if targetEnvironment(macCatalyst)
extension DiagramViewController {
    // MARK: - Mac menu actions

    // View menu

    @IBAction func doZoom(_ sender: Any) {
        // No zooming if no image
        guard imageView.image != nil else { return }
        var zoomFactor: CGFloat
        var newZoomFactor: CGFloat = 1.0
        if let command = sender as? UICommand, let property = command.propertyList as? String {
            if property == "zoomIn" {
                zoomFactor = imageScrollView.zoomScale
                newZoomFactor = zoomFactor * zoomInFactor
            }
            if property == "zoomOut" {
                zoomFactor = imageScrollView.zoomScale
                newZoomFactor = zoomFactor * zoomOutFactor
            }
            if property == "resetZoom" {
                newZoomFactor = 1.0
            }
        }
        if let sender = sender as? NSToolbarItem {
            switch sender.tag {
            case 0:
                zoomFactor = imageScrollView.zoomScale
                newZoomFactor = zoomFactor * zoomInFactor
            case 1:
                zoomFactor = imageScrollView.zoomScale
                newZoomFactor = zoomFactor * zoomOutFactor
            case 2:
                newZoomFactor = 1.0
            default:
                break
            }
        }
        UIView.animate(withDuration: 0.2) {
            self.imageScrollView.zoomScale = newZoomFactor
            self.scrollViewAdjustViews(self.imageScrollView)
        }
    }

    // Diagram menu


    @IBAction func importPhoto(_ sender: Any) {
        handleSelectImage()
    }

    @IBAction func importImageFile(_ sender: Any) {
        handleSelectFile()
    }

    @IBAction func selectLadder(_ sender: Any) {
        os_log("selectLadder()", log: .action, type: .info)
        selectLadder()
    }

    @IBAction func editLadder(_ sender: Any) {
        editTemplates()
    }

    @IBAction func getDiagramInfo(_ sender: Any) {
        getDiagramInfo()
    }

    @IBAction func sampleDiagrams(_ sender: Any) {
        sampleDiagrams()
    }
}
#endif

extension DiagramViewController {
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUndoableAction(_:)), name: .didUndoableAction, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePreferences), name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIScene.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnect), name: UIScene.didDisconnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willConnect), name: UIScene.willConnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resolveFileConflicts), name: UIDocument.stateChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveImageViewHeight), name: .updatedSeparatorPosition, object: nil)
    }

    @objc func onDidUndoableAction(_ notification: Notification) {
        if notification.name == .didUndoableAction {
            updateUndoRedoButtons()
        }
    }

    func updateUndoRedoButtons() {
        DispatchQueue.main.async {
            self.undoButton.isEnabled = self.currentDocument?.undoManager?.canUndo ?? false
            self.redoButton.isEnabled = self.currentDocument?.undoManager?.canRedo ?? false
        }
    }

    @objc func didEnterBackground() {
        os_log("didEnterBackground() - DiagramViewController", log: .lifeCycle, type: .info)
    }

    @objc func didEnterForeground() {
        os_log("didEnterForeground() - DiagramViewController", log: .lifeCycle, type: .info)
    }

    @objc func didDisconnect() {
        os_log("didDisconnect() - DiagramViewController", log: .lifeCycle, type: .info)
    }

    @objc func willConnect() {
        os_log("willConnect() - DiagramViewController", log: .lifeCycle, type: .info)
    }

    func updateToolbarButtons() {
        calibrateButton.isEnabled = !marksAreHidden && !ladderView.ladderIsLocked
        selectButton.isEnabled = !marksAreHidden && !ladderView.ladderIsLocked
        connectButton.isEnabled = !marksAreHidden && !ladderView.ladderIsLocked
    }

    @objc func updatePreferences() {
        os_log("updatePreferences()", log: .action, type: .info)
        ladderView.markLineWidth = CGFloat(UserDefaults.standard.integer(forKey: Preferences.lineWidthKey))
        cursorView.lineWidth = CGFloat(UserDefaults.standard.integer(forKey: Preferences.cursorLineWidthKey))
        cursorView.caliperLineWidth = CGFloat(UserDefaults.standard.integer(forKey: Preferences.caliperLineWidthKey))
        ladderView.showBlock = UserDefaults.standard.bool(forKey: Preferences.showBlockKey)
        ladderView.showImpulseOrigin = UserDefaults.standard.bool(forKey: Preferences.showImpulseOriginKey)
        ladderView.impulseOriginContiguous = UserDefaults.standard.bool(forKey: Preferences.impulseOriginContiguousKey)
        ladderView.impulseOriginLarge = UserDefaults.standard.bool(forKey: Preferences.impulseOriginLargeKey)
        ladderView.showArrows = UserDefaults.standard.bool(forKey: Preferences.showArrowsKey)
        ladderView.showIntervals = UserDefaults.standard.bool(forKey: Preferences.showIntervalsKey)
        ladderView.showConductionTimes = UserDefaults.standard.bool(forKey: Preferences.showConductionTimesKey)
        ladderView.showMarkLabels = UserDefaults.standard.bool(forKey: Preferences.showMarkLabelsKey)
        ladderView.snapMarks = UserDefaults.standard.bool(forKey: Preferences.snapMarksKey)
        ladderView.defaultMarkStyle = Mark.Style(rawValue: UserDefaults.standard.integer(forKey: Preferences.markStyleKey)) ?? .solid
        ladderView.labelDescriptionVisibility = TextVisibility(rawValue: UserDefaults.standard.integer(forKey: Preferences.labelDescriptionVisibilityKey)) ?? .invisible
        playSounds = UserDefaults.standard.bool(forKey: Preferences.playSoundsKey)
        marksAreHidden = UserDefaults.standard.bool(forKey: Preferences.hideMarksKey)
        ladderView.doubleLineBlockMarker = UserDefaults.standard.bool(forKey: Preferences.doubleLineBlockMarkerKey)
        ladderView.rightAngleBlockMarker = UserDefaults.standard.bool(forKey: Preferences.rightAngleBlockMarkerKey)
        cursorView.showMarkers = UserDefaults.standard.bool(forKey: Preferences.showMarkersKey)
        ladderView.hideZeroCT = UserDefaults.standard.bool(forKey: Preferences.hideZeroCTKey)
        cursorView.markerLineWidth = CGFloat(UserDefaults.standard.integer(forKey: Preferences.markerLineWidthKey))
        ladderView.showPeriods = UserDefaults.standard.bool(forKey: Preferences.showPeriodsKey)
        ladderView.periodPosition = PeriodPosition(rawValue: UserDefaults.standard.integer(forKey: Preferences.periodPositionKey)) ?? .bottom
        ladderView.periodTransparency = CGFloat(UserDefaults.standard.float(forKey: Preferences.periodTransparencyKey))
        ladderView.periodTextJustification = TextJustification(rawValue: UserDefaults.standard.integer(forKey: Preferences.periodTextJustificationKey)) ?? .left
        ladderView.periodsOverlapMarks = UserDefaults.standard.bool(forKey: Preferences.periodsOverlapMarksKey)
        ladderView.periodSize = PeriodSize(rawValue: UserDefaults.standard.integer(forKey: Preferences.periodSizeKey)) ?? .small
        ladderView.periodShowBorder = UserDefaults.standard.bool(forKey: Preferences.periodShowBorderKey)
        ladderView.periodResetMethod = PeriodResetMethod(rawValue: UserDefaults.standard.integer(forKey: Preferences.periodResetMethodKey)) ?? .clip
        ladderView.intervalGrouping = IntervalGrouping(rawValue: UserDefaults.standard.integer(forKey: Preferences.intervalGroupingKey)) ?? .fullInterior

        // Colors
        if let caliperColorName = UserDefaults.standard.string(forKey: Preferences.caliperColorNameKey) {
            cursorView.caliperColor = UIColor.convertColorName(caliperColorName) ?? Preferences.defaultCaliperColor
        }
        if let cursorColorName = UserDefaults.standard.string(forKey: Preferences.cursorColorNameKey) {
            cursorView.cursorColor = UIColor.convertColorName(cursorColorName) ?? Preferences.defaultCursorColor
        }
        if let attachedColorName = UserDefaults.standard.string(forKey: Preferences.attachedColorNameKey) {
            ladderView.attachedColor = UIColor.convertColorName(attachedColorName) ?? Preferences.defaultAttachedColor
        }
        if let connectedColorName = UserDefaults.standard.string(forKey: Preferences.connectedColorNameKey) {
            ladderView.connectedColor = UIColor.convertColorName(connectedColorName) ?? Preferences.defaultConnectedColor
        }
        if let selectedColorName = UserDefaults.standard.string(forKey: Preferences.selectedColorNameKey) {
            ladderView.selectedColor = UIColor.convertColorName(selectedColorName) ?? Preferences.defaultSelectedColor
        }
        if let linkedColorName = UserDefaults.standard.string(forKey: Preferences.linkedColorNameKey) {
            ladderView.linkedColor = UIColor.convertColorName(linkedColorName) ?? Preferences.defaultLinkedColor
        }
        if let activeColorName = UserDefaults.standard.string(forKey: Preferences.activeColorNameKey) {
            ladderView.activeColor = UIColor.convertColorName(activeColorName) ?? Preferences.defaultActiveColor
        }
        if let markerColorName = UserDefaults.standard.string(forKey: Preferences.markerColorNameKey) {
            cursorView.markerColor = UIColor.convertColorName(markerColorName) ?? Preferences.defaultMarkerColor
        }
        if let periodColorName = UserDefaults.standard.string(forKey: Preferences.periodColorNameKey) {
            ladderView.periodColor = UIColor.convertColorName(periodColorName) ?? Preferences.defaultPeriodColor
        }
        ladderView.updateLadderIntervals()
        // updatePreferences() can be called in the background, so update the UI on the main thread.
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                self.updateToolbarButtons()
                self.setViewsNeedDisplay()
            }
        }
    }


    /// Saves to UserDefaults the ratio of the imageScrollView height to overall view height.
    @objc func saveImageViewHeight() {
        let multiplier = imageScrollView.frame.height / self.view.frame.height
        UserDefaults.standard.set(multiplier, forKey: Preferences.imageViewHeightKey)
    }

    /// Sets multiplier to saved ratio of imageScrollView height to overall view height.
    func getImageViewHeight() {
        let multiplier = CGFloat(UserDefaults.standard.float(forKey: Preferences.imageViewHeightKey)).clamped(to: 0.1...0.9)
        imageViewHeightConstraint = imageViewHeightConstraint.setMultiplier(multiplier: multiplier)
    }

    @objc func resolveFileConflicts() {
        // This fires off frequently; leave commented unless debugging.
        //os_log("resolveFileConflicts()", log: .action, type: .info)
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

    //TODO: At present we can only drag and drop image files.  We would like to drag and drop PDFs and also diagram files.  For PDFs it will probably be necessary to rewrite all the PDF code to use the PDFDocument class, rather than the core foundation PDF functions.  We will plan this for a future update.
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        let typeIdentifiers = [UTType.image.identifier]
        // For future implementation, add PDFs, diagram files to drag and drop.
        //let typeIdentifiers = [UTType.image.identifier, UTType.pdf.identifier]
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
        if session.hasItemsConforming(toTypeIdentifiers: [UTType.image.identifier]) {
            session.loadObjects(ofClass: UIImage.self) { imageItems in
                if let images = imageItems as? [UIImage] {
                    self.undoablySetDiagramImageAndResetLadder(images.first, imageIsUpscaled: false, transform: .identity, scale: 1.0, contentOffset: .zero)
                }
            }
        }
        else if session.hasItemsConforming(toTypeIdentifiers: [UTType.pdf.identifier]) {
            print("dropping PDF")
            _ = session.loadObjects(ofClass: URL.self) { pdfItems in
                if let url = pdfItems.first {
                    self.openURL(url: url)
                }
            }
        }
    }
}

extension DiagramViewController: NSUserActivityDelegate {
    func userActivityWillSave(_ userActivity: NSUserActivity) {

//        let currentDocumentURL: String = currentDocument?.fileURL.lastPathComponent ?? ""
//        print("currentDocumentURL", currentDocumentURL)
        if documentIsClosing {
            // intercept and kill userInfo if we closed the document with the close button
            userActivity.userInfo = nil
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
                    if let resolvedDirectoryURL = Sandbox.getPersistentDirectoryURL(forFileURL: oldURL) {
                        let startAccessing = resolvedDirectoryURL.startAccessingSecurityScopedResource()
                        defer {
                            if startAccessing {
                                resolvedDirectoryURL.stopAccessingSecurityScopedResource()
                            }
                        }

                        let error: NSError? = nil
                        let fileCoordinator = NSFileCoordinator()
                        var moveError = error
                        fileCoordinator.coordinate(writingItemAt: oldURL, options: .forMoving, writingItemAt: newURL, options: .forReplacing, error: &moveError, byAccessor: { newURL1, newURL2 in
                            let fileManager = FileManager.default
                            // Below gives sandbox error on mac
                            //fileCoordinator.item(at: oldURL, willMoveTo: newURL)
                            if (try? fileManager.moveItem(at: newURL1, to: newURL2)) != nil {
                                fileCoordinator.item(at: oldURL, didMoveTo: newURL)
                                DispatchQueue.main.async {
                                    self.currentDocument = DiagramDocument(fileURL: newURL)
                                    self.currentDocument?.open { openSuccess in
                                        guard openSuccess else {
                                            print ("could not open \(newURL)")
                                            return
                                        }
                                        self.currentDocument?.diagram = self.diagram
                                        self.setTitle()
                                        self.currentDocument?.updateChangeCount(.done)
                                        // Try to delete old document, ignore errors.
                                        DispatchQueue.global(qos: .background).async {
                                            if fileManager.isDeletableFile(atPath: oldURL.path) {
                                                try? fileManager.removeItem(atPath: oldURL.path)
                                            }
                                        }
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
}

extension DiagramViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == gotoTextFieldTag {
            textField.selectAll(nil)
        }
    }
}

// Mac catalyst specific functions
#if targetEnvironment(macCatalyst)
extension DiagramViewController {
    @IBAction func macCloseDocument(_ sender: Any) {
        closeDocument()
    }

    @IBAction func macSnapshotDiagram(_ sender: Any) {
        snapshotDiagram()
    }

    @IBAction func macShowCalibrateToolbar(_ sender: Any) {
        mode = .calibrate
        navigationController?.setToolbarHidden(false, animated: true)
    }

    @IBAction func macSelectImage(_ sender: Any) {
        selectImage()
    }

    @IBAction func addDirectoryToSandbox(_ sender: Any) {
        let currentDocumentURL: URL?
        if let _ = sender as? DiagramViewController {
            currentDocumentURL = getCurrentDirectoryURL()
        } else  {
            currentDocumentURL = nil
        }
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let plugin = appDelegate.appKitPlugin {
                if let nsWindow = self.view.window?.nsWindow {
                    let completion: ((URL)->Void) = { url in
                        self.storeDirectoryBookmark(from: url)
                        print("directoryURL", url as Any)
                    }
                    plugin.getDirectory(nsWindow: nsWindow, startingURL: currentDocumentURL, completion: completion)
                }
            }
        }
    }

    private func getCurrentDirectoryURL() -> URL? {
        if let currentDocument = currentDocument {
            let url = currentDocument.fileURL.deletingLastPathComponent()
            return url
        }
        return nil
    }

    @IBAction func clearSandbox(_ sender: Any) {
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            if key.starts(with: "AccessDirectory:") {
                print(key)
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    func storeDirectoryBookmark(from url: URL) {
        guard url.hasDirectoryPath else {
            print("URL not a directory")
            return
        }
        #if targetEnvironment(macCatalyst)
        let bookmarkOptions: URL.BookmarkCreationOptions = [.withSecurityScope]
        #else
        let bookmarkOptions: URL.BookmarkCreationOptions = []
        #endif
        let key = getAccessDirectoryKey(for: url)
        if let bookmark = try? url.bookmarkData(options: bookmarkOptions, includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.setValue(bookmark, forKey: key)
        } else {
            print("Could not create directory bookmark.")
        }
    }

    private func getAccessDirectoryKey(for url: URL) -> String {
        return "AccessDirectory:\(url.path)"
    }


}
#endif

// for debugging
extension DiagramViewController {

    #if DEBUG
    func debugPrintFonts() {
        for family: String in UIFont.familyNames
        {
            print(family)
            for names: String in UIFont.fontNames(forFamilyName: family)
            {
                print("== \(names)")
            }
        }
    }
    #endif
}

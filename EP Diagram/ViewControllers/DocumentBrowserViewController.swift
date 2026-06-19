//
//  DocumentBrowserViewController.swift
//  EP Diagram
//
//  Created by David Mann on 11/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

enum NavigationContext {
  case launched
  case browsing
  case editing
}

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentPickerDelegate {

    var presentationContest: NavigationContext = .launched
    var currentDocument: DiagramDocument?
    var editingDocument = false
    var browserDelegate = DocumentBrowserDelegate()
    var restorationInfo: [AnyHashable: Any]?

    weak var diagramViewController: DiagramViewController?

    var isEditingDocument: Bool {
        editingDocument
    }

    var stateRestorationActivity: NSUserActivity {
        guard editingDocument else {
            os_log("DocumentBrowserViewController.stateRestorationActivity returning clean activity: not editing", log: .lifeCycle, type: .info)
            return NSUserActivity(activityType: AppDelegate.mainActivityType)
        }
        guard currentDocument != nil else {
            os_log("DocumentBrowserViewController.stateRestorationActivity returning clean activity: no currentDocument", log: .lifeCycle, type: .info)
            return NSUserActivity(activityType: AppDelegate.mainActivityType)
        }
        let activity = view.window?.windowScene?.userActivity ?? NSUserActivity(activityType: AppDelegate.mainActivityType)
        os_log("DocumentBrowserViewController.stateRestorationActivity returning scene activity userInfo=%s", log: .lifeCycle, type: .info, String(describing: activity.userInfo))
        return activity
    }

    override func viewDidLoad() {
        os_log("viewDidLoad() - DocumentBrowserViewController", log: .default, type: .default)

        super.viewDidLoad()
        delegate = browserDelegate
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
        localizedCreateDocumentActionTitle = L("Create New Diagram")
        browserUserInterfaceStyle = .light
        view.tintColor = .systemBlue
        installInportHandler()

        let info = self.restorationInfo
        os_log("viewDidLoad restorationInfo=%s", log: .lifeCycle, type: .info, String(describing: info))
        if info?[DiagramViewController.restorationDoRestorationKey] as? Bool ?? false {
            if let documentURL = info?[DiagramViewController.restorationDocumentURLKey] as? URL {
                os_log("viewDidLoad restoring document URL=%s", log: .lifeCycle, type: .info, documentURL.path)
                openDocument(url: documentURL)
            } else {
                os_log("viewDidLoad restoration requested but no document URL", log: .lifeCycle, type: .info)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        os_log("viewDidAppear(_:) - DocumentBrowserViewController editing=%s hasDocument=%s", log: .viewCycle, type: .default, editingDocument ? "true" : "false", currentDocument == nil ? "false" : "true")
        super.viewDidAppear(animated)
        displayDiagramController()
     }

    override func viewWillDisappear(_ animated: Bool) {
        os_log("viewWillDisappear(_:) - DocumentBrowserViewController", log: .viewCycle, type: .default)
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        os_log("viewDidDisappear(_:) - DocumentBrowserViewController", log: .viewCycle, type: .default)
        super.viewDidDisappear(animated)
    }

    func installInportHandler() {
        browserDelegate.inportHandler = { [weak self] url, error in
            guard error == nil else {
                let alert = UIAlertController(title: L("Error Opening Diagram"), message: L("This diagram could not be opened."), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: L("OK"), style: .cancel, handler: { _ in }))
                self?.present(alert, animated: true)
                return
            }
            if let url = url, let self = self {
                self.openDocument(url: url)
            }
        }
    }

    func openDocument(url: URL) {
        os_log("openDocument(url:) %s editing=%s hasDocument=%s", log: .lifeCycle, type: .info, url.path, editingDocument ? "true" : "false", currentDocument == nil ? "false" : "true")
        guard !isDocumentCurrentlyOpen(url: url) else {
            os_log("openDocument ignored already-open document: %s", log: .lifeCycle, type: .info, url.path)
            print("openDocument(url:) - document is currently open")
            return
        }
        closeDiagramController { [weak self] in
            guard let self = self else { return }
            os_log("openDocument creating DiagramDocument for %s", log: .lifeCycle, type: .info, url.path)
            let document = DiagramDocument(fileURL: url)
            document.open { openSuccess in
                guard openSuccess else {
                    os_log("openDocument failed to open %s", log: .lifeCycle, type: .info, url.path)
                    print ("could not open \(url)")
                    self.getIOSBookmark(url: url)
                    return
                }
                os_log("openDocument succeeded %s", log: .lifeCycle, type: .info, url.path)
                self.currentDocument = document
                self.displayDiagramController()
            }
        }
    }

    // See https://developer.apple.com/documentation/uikit/view_controllers/providing_access_to_directories
    func getIOSBookmark(url: URL) {
#if !targetEnvironment(macCatalyst)
        let documentPicker =
            UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.delegate = self

        // Set the initial directory.
        documentPicker.directoryURL = url

        // Present the document picker.
        present(documentPicker, animated: true, completion: nil)
#endif

    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        UserAlert.showMessage(viewController: self, title: "File can't be opened", message: "Cannot open file unless you agree to add this directory to the app sandbox.")
        print("Cannot open file since directory is not sandboxed.")
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        // Start accessing a security-scoped resource.
        guard url.startAccessingSecurityScopedResource() else {
            // Handle the failure here.
            return
        }

        // Make sure you release the security-scoped resource when you finish.
        defer { url.stopAccessingSecurityScopedResource() }

        // Use file coordination for reading and writing any of the URL’s content.
        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { (url) in

            let keys : [URLResourceKey] = [.nameKey, .isDirectoryKey]

            // Get an enumerator for the directory's content.
            guard let fileList =
                FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys) else {
                Swift.debugPrint("*** Unable to access the contents of \(url.path) ***\n")
                return
            }

            for case let file as URL in fileList {
                // Start accessing the content's security-scoped URL.
                guard url.startAccessingSecurityScopedResource() else {
                    UserAlert.showMessage(viewController: self, title: "Access Not Granted", message: "Cannot access diagram files in this directory.")
                    return
                }

                // Do something with the file here.
                Swift.debugPrint("chosen file: \(file.lastPathComponent)")
                Sandbox.storeDirectoryBookmark(from: url)
                UserAlert.showMessage(viewController: self, title: "Access Granted", message: "Access has been granted to \(file.deletingLastPathComponent().lastPathComponent).  Select again a diagram file in this directory or select Create New Diagram.")
                // Make sure you release the security-scoped resource when you finish.
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    private func openDocumentURL(_ url: URL) {
        os_log("openDocumentURL(_:) %s", url.path)
        let document = DiagramDocument(fileURL: url)
        document.open { [weak self] openSuccess in
            guard let self = self else { return }
            guard openSuccess else {
                print ("could not open \(url)")
                return
            }
            self.currentDocument = document
            self.displayDiagramController(requestSandboxExpansion: true)
        }
    }

    func isDocumentCurrentlyOpen(url: URL) -> Bool {
        guard let document = currentDocument else { return false }
        return document.fileURL.standardizedFileURL == url.standardizedFileURL && document.documentState != .closed
    }

    func createNewDocument() {
        os_log("createNewDocument() - DocumentBrowserViewController", log: .lifeCycle, type: .info)
        closeDiagramController { [weak self] in
            guard let self = self else { return }
            let directoryURL = FileIO.getDocumentsURL() ?? FileIO.getCacheURL()
            let documentURL = self.browserDelegate.createNewDocumentURL(in: directoryURL)
            os_log("createNewDocument creating blank document at %s", log: .lifeCycle, type: .info, documentURL.path)
            self.browserDelegate.createBlankDocument(at: documentURL) { [weak self] newDocumentURL in
                guard let self = self else { return }
                guard let newDocumentURL = newDocumentURL else {
                    UserAlert.showMessage(viewController: self, title: L("Error Creating Diagram"), message: L("A new diagram could not be created."))
                    return
                }
                self.openDocument(url: newDocumentURL)
            }
        }
    }

    @objc func displayDiagramController(requestSandboxExpansion: Bool = false) {
        os_log("displayDiagramController() editing=%s hasDocument=%s hasWindow=%s presented=%s", log: .lifeCycle, type: .info, editingDocument ? "true" : "false", currentDocument == nil ? "false" : "true", view.window == nil ? "false" : "true", presentedViewController == nil ? "false" : "true")
        guard !editingDocument else {
            os_log("displayDiagramController skipped: already editing", log: .lifeCycle, type: .info)
            return
        }
        guard let document = currentDocument else {
            os_log("displayDiagramController skipped: no currentDocument", log: .lifeCycle, type: .info)
            return
        }
        guard view.window != nil else {
            os_log("Deferring diagram presentation until DocumentBrowserViewController enters the window hierarchy", log: .lifeCycle, type: .info)
            return
        }
        guard presentedViewController == nil else {
            os_log("Retrying diagram presentation after current presentation finishes", log: .lifeCycle, type: .info)
            DispatchQueue.main.async { [weak self] in
                self?.displayDiagramController(requestSandboxExpansion: requestSandboxExpansion)
            }
            return
        }

        let controller = DiagramViewController.navigationControllerFactory()

        let diagramViewController = controller.viewControllers[0] as? DiagramViewController
        diagramViewController?.currentDocument = document
        diagramViewController?.diagramEditorDelegate = self
        diagramViewController?.diagram = document.diagram
        diagramViewController?.requestSandboxExpansion = requestSandboxExpansion

        diagramViewController?.restorationInfo = restorationInfo
        restorationInfo = nil // don't need it any more

        controller.modalPresentationStyle = .fullScreen

        editingDocument = true
        os_log("displayDiagramController presenting document=%s", log: .lifeCycle, type: .info, document.fileURL.path)
        self.present(controller, animated: true)
        self.diagramViewController = diagramViewController
    }

    func closeDiagramController(completion: (()->Void)? = nil) {
        os_log("closeDiagramController() editing=%s hasDocument=%s", log: .lifeCycle, type: .info, editingDocument ? "true" : "false", currentDocument == nil ? "false" : "true")
        let compositeClosure = { [weak self] in
            guard let self = self else { return }
            os_log("closeDiagramController compositeClosure", log: .lifeCycle, type: .info)
            self.closeCurrentDocument(completion: completion)
            self.editingDocument = false
            self.diagramViewController = nil
        }
        if editingDocument {
            os_log("closeDiagramController dismissing presented diagram controller", log: .lifeCycle, type: .info)
            prepareForDocumentClose()
            self.dismiss(animated: true) {
                compositeClosure()
            }
        } else {
            os_log("closeDiagramController no presented diagram controller to dismiss", log: .lifeCycle, type: .info)
            compositeClosure()
        }
    }

    private func prepareForDocumentClose() {
        os_log("prepareForDocumentClose() clearing scene userActivity and restorationInfo", log: .lifeCycle, type: .info)
        diagramViewController?.documentIsClosing = true
        view.window?.windowScene?.userActivity = NSUserActivity(activityType: AppDelegate.mainActivityType)
        restorationInfo = nil
    }

    func closeCurrentDocument(completion: (()->Void)? = nil) {
        guard let document = currentDocument else {
            os_log("closeCurrentDocument skipped: currentDocument is nil", log: .lifeCycle, type: .info)
            print("current document is nil!")
            completion?()
            return
        }
        os_log("closeCurrentDocument closing %s", log: .lifeCycle, type: .info, document.fileURL.path)
        currentDocument?.close() { success in
            guard success else {
                os_log("closeCurrentDocument failed", log: .lifeCycle, type: .info)
                print("failed to close document")
                completion?()
                return
            }
            os_log("closeCurrentDocument succeeded", log: .lifeCycle, type: .info)
            completion?()
        }
        currentDocument = nil
    }

}

protocol DiagramEditorDelegate: AnyObject {
    func diagramEditorDidFinishEditing(_ controller: DiagramViewController, diagram: Diagram)
    func diagramEditorDidUpdateContent(_ controller: DiagramViewController, diagram: Diagram)
    func diagramEditor(_ controller: DiagramViewController, didRenameDocumentTo document: DiagramDocument)
}

extension DocumentBrowserViewController: DiagramEditorDelegate {
    func diagramEditorDidFinishEditing(_ controller: DiagramViewController, diagram: Diagram) {
        os_log("diagramEditorDidFinishEditing(_:diagram:) - DocumentBrowserViewController", log: .default, type: .default)
        currentDocument?.diagram = diagram
        closeDiagramController()
    }

    func diagramEditorDidUpdateContent(_ controller: DiagramViewController, diagram: Diagram) {
        os_log("diagramEditorDidUpdateContent(_:diagram:) - DocumentBrowserViewController", log: .default, type: .default)
        currentDocument?.diagram = diagram
    }

    func diagramEditor(_ controller: DiagramViewController, didRenameDocumentTo document: DiagramDocument) {
        currentDocument = document
    }
}

#if targetEnvironment(macCatalyst)
extension DocumentBrowserViewController {

    // Forward actions to the diagramViewController as needed

    // Edit menu

    @IBAction func undo(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.undo(sender)
        }
    }

    @IBAction func redo(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.redo(sender)
        }
    }

    // View menu

    @IBAction func doZoom(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.doZoom(sender)
        }
    }

    // Diagram menu

    @IBAction func getDiagramInfo(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.getDiagramInfo(sender)
        }
    }

    @IBAction func importPhoto(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.importPhoto(sender)
        }
    }

    @IBAction func importImageFile(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.importImageFile(sender)
        }
    }

    @IBAction func selectLadder(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.selectLadder(sender)
        }
    }

    @IBAction func editLadder(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.editLadder(sender)
        }
    }

    @IBAction func sampleDiagrams(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.sampleDiagrams(sender)
        }
    }

    @IBAction func closeWindow(_ sender: Any) {
        os_log("closeWindow(_:) - DocumentBrowserViewController", log: .lifeCycle, type: .info)
        closeDiagramController { [weak self] in
            self?.destroyCurrentScene()
        }
    }

    @IBAction func openDiagramFromMenu(_ sender: Any) {
        os_log("openDiagramFromMenu(_:) - DocumentBrowserViewController editing=%s", log: .lifeCycle, type: .info, editingDocument ? "true" : "false")
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.openDiagramFromMenu(sender)
    }

    private func closeDocumentAndOpenBrowserScene() {
        os_log("closeDocumentAndOpenBrowserScene()", log: .lifeCycle, type: .info)
        if let diagramViewController = diagramViewController {
            currentDocument?.diagram = diagramViewController.diagram
        }
        closeDiagramController { [weak self] in
            guard let self = self else { return }
            os_log("closeDocumentAndOpenBrowserScene requesting browser scene then destroying current scene", log: .lifeCycle, type: .info)
            self.requestNewDocumentBrowserScene()
            self.destroyCurrentScene()
        }
    }

    private func activateDocumentBrowserScene() {
        guard let sceneSession = view.window?.windowScene?.session else {
            os_log("activateDocumentBrowserScene fallback: no current scene session", log: .lifeCycle, type: .info)
            requestNewDocumentBrowserScene()
            return
        }
        os_log("activateDocumentBrowserScene activating current session=%s", log: .lifeCycle, type: .info, sceneSession.persistentIdentifier)
        UIApplication.shared.requestSceneSessionActivation(sceneSession, userActivity: nil, options: nil) { error in
            print("Error showing open browser", error.localizedDescription)
        }
    }

    private func requestNewDocumentBrowserScene() {
        os_log("requestNewDocumentBrowserScene() - DocumentBrowserViewController", log: .lifeCycle, type: .info)
        let activity = NSUserActivity(activityType: AppDelegate.mainActivityType)
        activity.addUserInfoEntries(from: [AppDelegate.openBrowserKey: true])
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { error in
            print("Error showing open browser", error.localizedDescription)
        }
    }

    private func destroyCurrentScene() {
        guard let sceneSession = view.window?.windowScene?.session else {
            os_log("destroyCurrentScene skipped: no current scene session", log: .lifeCycle, type: .info)
            return
        }
        os_log("destroyCurrentScene() session=%s", log: .lifeCycle, type: .info, sceneSession.persistentIdentifier)
        let options = UIWindowSceneDestructionRequestOptions()
        UIApplication.shared.requestSceneSessionDestruction(sceneSession, options: options) { error in
            print("Error closing diagram window", error.localizedDescription)
        }
    }

    @IBAction func macShowCalibrateToolbar(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.macShowCalibrateToolbar(sender)
        }
    }

    @IBAction func macSnapshotDiagram(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.macSnapshotDiagram(sender)
        }
    }

    @IBAction func macSelectImage(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.macSelectImage(sender)
        }
    }

    @IBAction func addDirectoryToSandbox(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.addDirectoryToSandbox(sender)
        }
    }

    @IBAction func clearSandbox(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.clearSandbox(sender)
        }
    }

    @objc func renameDiagram() {
        if let diagramViewController = diagramViewController {
            diagramViewController.renameDiagram()
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
         if action == #selector(undo(_:)) {
             // It appears this is a crashing bug on macOS.  When macOS restores windows left open,
             // window can be blank, without an imageScrollView, and this func can be
             // called in this situation.  Thus need to make imageScrollView optional even though
             // it is defined as a forced unwrapped optional.
             // Essentially this means that due to window restoration on Mac, there can be a
             // diagramViewController without an imageScollView.
            return diagramViewController?.imageScrollView?.isActivated ?? false &&
                currentDocument?.undoManager?.canUndo ?? false
        } else if action == #selector(redo(_:)) {
            return diagramViewController?.imageScrollView?.isActivated ?? false &&
                currentDocument?.undoManager?.canRedo ?? false
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }
}
#endif

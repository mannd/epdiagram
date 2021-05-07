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

class DocumentBrowserViewController: UIDocumentBrowserViewController {

    var presentationContest: NavigationContext = .launched
    var currentDocument: DiagramDocument?
    var editingDocument = false
    var browserDelegate = DocumentBrowserDelegate()
    var restorationInfo: [AnyHashable: Any]?

    var diagramViewController: DiagramViewController?

    var newWindow = true

    override func viewDidLoad() {
        os_log("viewDidLoad() - DocumentBrowserViewController", log: .default, type: .default)

        super.viewDidLoad()
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
        localizedCreateDocumentActionTitle = L("Create New Diagram")
        browserUserInterfaceStyle = .light
        delegate = browserDelegate
        view.tintColor = .systemBlue
        installDocumentBrowser()


    }

    override func viewDidAppear(_ animated: Bool) {
        os_log("viewDidAppear(_:) - DocumentBrowserViewController", log: .default, type: .default)
        super.viewDidAppear(animated)
//        #if targetEnvironment(macCatalyst)
//        // FIXME: What do we really need to do here?
//        view.window?.rootViewController = self
//        #endif

        let info = self.restorationInfo

        #if !targetEnvironment(macCatalyst)
        // Fail gently if cached file no longer exists.
        if let lastDocumentURLPath = info?[DiagramViewController.restorationFileNameKey] as? String,
           !lastDocumentURLPath.isEmpty,
           info?[DiagramViewController.restorationDoRestorationKey] as? Bool ?? false {
            if let docURL = FileIO.getDocumentsURL() {
                let fileURL = docURL.appendingPathComponent(lastDocumentURLPath)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    openDocument(url: fileURL)
                }
            }
        }
        #else
        var bookmarkDataIsStale: Bool = false
        if let bookmarkData = info?[DiagramViewController.restorationBookmarkKey] as? Data {
            if let resolvedURL = try? URL(resolvingBookmarkData: bookmarkData, options: NSURL.BookmarkResolutionOptions(), relativeTo: nil, bookmarkDataIsStale: &bookmarkDataIsStale) {
                if resolvedURL.startAccessingSecurityScopedResource() {
//                    if !bookmarkDataIsStale {
                        openDocument(url: resolvedURL)
//                    }
                    resolvedURL.stopAccessingSecurityScopedResource()
                }
            }
        }
        #endif
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        os_log("viewDidDisappear(_:) - DocumentBrowserViewController", log: .default, type: .default)
        super.viewDidDisappear(animated)
    }

    func installDocumentBrowser() {
        browserDelegate.presentationHandler = { [weak self] url, error in
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
}

protocol DiagramEditorDelegate: AnyObject {
    func diagramEditorDidFinishEditing(_ controller: DiagramViewController, diagram: Diagram)
    func diagramEditorDidUpdateContent(_ controller: DiagramViewController, diagram: Diagram)
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

    @objc func displayDiagramController() {
        os_log("displayDiagramController()", log: .default, type: .default)
        guard !editingDocument else { return }
        guard let document = currentDocument else { return }

        editingDocument = true

        let controller = DiagramViewController.navigationControllerFactory()

        let diagramViewController = controller.viewControllers[0] as? DiagramViewController
        diagramViewController?.currentDocument = document
        diagramViewController?.diagramEditorDelegate = self
        diagramViewController?.diagram = document.diagram

        diagramViewController?.restorationInfo = restorationInfo
        restorationInfo = nil // don't need it any more

        // This is not used, probably can delete.
//        diagramViewController?.restorationIdentifier = restorationIdentifier


        // Key step! for mac Catalyst!
//        #if targetEnvironment(macCatalyst)
//        // OK, below lets new scene work, but only the last view controller is non-blank
////        UIApplication.shared.windows.first?.rootViewController = controller
//        // Below shows all the diagram view controllers, but new scene doesn't work
//        if newWindow {
//            UIApplication.shared.windows.first?.rootViewController = controller
//        } else {
//            self.view.window?.rootViewController = controller
//        }
//        #else
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: true)
        self.diagramViewController = diagramViewController
//        #endif
    }

    // See https://stackoverflow.com/questions/57134259/how-to-resolve-keywindow-was-deprecated-in-ios-13-0
    func topMostController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

         let topController = keyWindow?.rootViewController
//         {
//            while (topController.presentedViewController != nil) {
//                topController = topController.presentedViewController!
//            }
//            return topController
//        }
        return topController
    }

    func closeDiagramController(completion: (()->Void)? = nil) {
        let compositeClosure = {
            self.closeCurrentDocument()
            self.editingDocument = false
            completion?()
        }
        if editingDocument {
            self.dismiss(animated: true) {
                compositeClosure()
            }
        } else {
            compositeClosure()
        }
    }

    private func closeCurrentDocument() {
        currentDocument?.close()
        currentDocument = nil
    }

    // FIXME: Not used...
//    func openRemoteDocument(_ inboundURL: URL, importIfNeeded: Bool) {
//        os_log("openRemoteDocument(_:importIfNeeded:)", log: .debugging, type: .debug)
//        revealDocument(at: inboundURL, importIfNeeded: importIfNeeded) { (url, error) in
//            if let error = error {
//                let alert = UIAlertController(title: L("Could Not Open Document"), message: L("EP Diagram could not open this document due to error \(error.localizedDescription)"), preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default))
//                self.present(alert, animated: true)
//                os_log("import did fail - %s", log: .errors, type: .error, error.localizedDescription)
//            } else if let url = url {
//                self.openDocument(url: url)
//            }
//        }
//    }
}

extension DocumentBrowserViewController {

    // FIXME: Looks like diagram should load when this is set to false after initial load of the windows.  New diagram should replace old.  But it isn't happening for some reason.
    func openDocument(url: URL) {
        os_log("openDocument(url:) %s", url.path)
        guard !isDocumentCurrentlyOpen(url: url) else { return }
        closeDiagramController {
            let document = DiagramDocument(fileURL: url)
//            self.loadViewIfNeeded()
            document.open { openSuccess in
                guard openSuccess else {
                    print ("could not open \(url)")
                    return
                }
                self.currentDocument = document
                self.displayDiagramController()
            }
        }
    }

    private func isDocumentCurrentlyOpen(url: URL) -> Bool {
        if let document = currentDocument {
            if document.fileURL == url && document.documentState != .closed {
                return true
            }
        }
        return false
    }

    #if targetEnvironment(macCatalyst)


    // Forward actions to the diagramViewController as needed

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

    #endif


}

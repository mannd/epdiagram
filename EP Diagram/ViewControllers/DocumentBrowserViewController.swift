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

    weak var diagramViewController: DiagramViewController?

    override func viewDidLoad() {
        os_log("viewDidLoad() - DocumentBrowserViewController", log: .default, type: .default)

        super.viewDidLoad()
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
        localizedCreateDocumentActionTitle = L("Create New Diagram")
        browserUserInterfaceStyle = .light
        delegate = browserDelegate
        view.tintColor = .systemBlue
        installPresentationHandler()

        let info = self.restorationInfo
        if info?[DiagramViewController.restorationDoRestorationKey] as? Bool ?? false {
            if let documentURL = info?[DiagramViewController.restorationDocumentURLKey] as? URL {
//                if let presentationHandler = browserDelegate.presentationHandler {
//                    presentationHandler(documentURL, nil)
                openDocument(url: documentURL)
//                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        os_log("viewDidAppear(_:) - DocumentBrowserViewController", log: .default, type: .default)
        super.viewDidAppear(animated)

     }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        os_log("viewDidDisappear(_:) - DocumentBrowserViewController", log: .default, type: .default)
        super.viewDidDisappear(animated)
    }

    func installPresentationHandler() {
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

    func openDocument(url: URL) {
        os_log("openDocument(url:) %s", url.path)
        guard !isDocumentCurrentlyOpen(url: url) else { return }

        closeDiagramController {
            let accessKey = self.getAccessKey(url: url)
            #if targetEnvironment(macCatalyst)
            let bookmarkOptions: URL.BookmarkResolutionOptions = [.withSecurityScope]
            #else
            let bookmarkOptions: URL.BookmarkResolutionOptions = []
            #endif
            if let bookmarkData = UserDefaults.standard.value(forKey: accessKey) as? Data {
                var bookmarkDataIsStale: Bool = false
                if let resolvedURL = try? URL(resolvingBookmarkData: bookmarkData, options: bookmarkOptions, relativeTo: nil, bookmarkDataIsStale: &bookmarkDataIsStale) {
                    if resolvedURL.startAccessingSecurityScopedResource() {
                        // Doesn't matter if bookmark data is stale, bookmarks are created anew
                        // when documents are opened.
                        if bookmarkDataIsStale {
                            // create new bookmark if possible
                            self.openDocumentURL(url, createBookmark: true)
                            resolvedURL.stopAccessingSecurityScopedResource()
                            print("Attempt to refresh bookmark")
                        }
                        self.openDocumentURL(resolvedURL)
                        resolvedURL.stopAccessingSecurityScopedResource()
                    }
                }
            } else {
                self.openDocumentURL(url, createBookmark: true)
            }
        }
    }

    private func openDocumentURL(_ url: URL, createBookmark: Bool = false) {
        let document = DiagramDocument(fileURL: url)
        document.open { openSuccess in
            guard openSuccess else {
                print ("could not open \(url)")
                return
            }
            if createBookmark {
                // In the case of new documents, we can't create a bookmark until the document is opened.   
                #if targetEnvironment(macCatalyst)
                let bookmarkOptions: URL.BookmarkCreationOptions = [.withSecurityScope]
                #else
                let bookmarkOptions: URL.BookmarkCreationOptions = []
                #endif
                let accessKey = self.getAccessKey(url: url)
                if let bookmarkData = try? url.bookmarkData(options: bookmarkOptions, includingResourceValuesForKeys: nil, relativeTo: nil) {
                    UserDefaults.standard.setValue(bookmarkData, forKey: accessKey)
                    print("****New bookmark created successfully")
                } else {
                    // remove saved bookmark if it exists
                    UserDefaults.standard.removeObject(forKey: accessKey)
                    print("*******Could not create bookmark")
                }
            }
            self.currentDocument = document
            self.displayDiagramController()
        }
    }

    private func getAccessKey(url: URL) -> String {
        return "Access:\(url.path)"
    }

    private func isDocumentCurrentlyOpen(url: URL) -> Bool {
        if let document = currentDocument {
            if document.fileURL == url && document.documentState != .closed {
                return true
            }
        }
        return false
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

        controller.modalPresentationStyle = .fullScreen
//        #if targetEnvironment(macCatalyst) // open one window only
//        UIApplication.topViewController()?.present(controller, animated: true)
        print("******", self as Any, controller as Any)
        self.view.window?.rootViewController?.present(controller, animated: true)
//        self.present(controller, animated: true)
        self.diagramViewController = diagramViewController
    }

    func closeDiagramController(completion: (()->Void)? = nil) {
        let compositeClosure = {
            self.closeCurrentDocument()
            self.editingDocument = false
//            self.diagramViewController = nil
            completion?()
        }
        if editingDocument {
            self.dismiss(animated: true) {
                print("$$$$dismiss called")
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

    @IBAction func macCloseDocument(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.macCloseDocument(sender)
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

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
         if action == #selector(undo(_:)) {
            return diagramViewController?.imageScrollView.isActivated ?? false &&
                currentDocument?.undoManager?.canUndo ?? false
        } else if action == #selector(redo(_:)) {
            return diagramViewController?.imageScrollView.isActivated ?? false &&
                currentDocument?.undoManager?.canRedo ?? false
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }

}
#endif

//extension UIApplication {
//    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
//        if let nav = base as? UINavigationController {
//            return topViewController(base: nav.visibleViewController)
//        }
//        if let tab = base as? UITabBarController {
//            if let selected = tab.selectedViewController {
//                return topViewController(base: selected)
//            }
//        }
//        if let presented = base?.presentedViewController {
//            return topViewController(base: presented)
//        }
//        return base
//    }
//}



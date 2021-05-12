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
                    // Doesn't matter if bookmark data is stale, bookmarks are created anew
                    // when documents are opened.
                    openDocument(url: resolvedURL)
                    resolvedURL.stopAccessingSecurityScopedResource()
                }
            }
        }
        #endif
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

    func openDocument(url: URL) {
        os_log("openDocument(url:) %s", url.path)
        guard !isDocumentCurrentlyOpen(url: url) else { return }
        // FIXME: save bookmark here to a recent files list?  Maybe array of user defaults, check if bookmark present and open it instead of url???
        let folder = url.deletingLastPathComponent()
        print("****folder", folder)
        closeDiagramController {
            let document = DiagramDocument(fileURL: url)
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
//        #if targetEnvironment(macCatalyst)
        // Sadly this might be the best solution.  Only one window open at a time.
        // FIXME: and this doesn't even work, because now the dialogs don't open.
//        UIApplication.topViewController()?.present(controller, animated: true)
//        #else
        self.present(controller, animated: true)
//        #endif
        self.diagramViewController = diagramViewController
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

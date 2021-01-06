//
//  DocumentBrowserViewController.swift
//  EP Diagram
//
//  Created by David Mann on 11/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

class DocumentBrowserViewController: UIDocumentBrowserViewController {

    var currentDocument: DiagramDocument?
    var editingDocument = false
    var browserDelegate = DocumentBrowserDelegate()
    var restorationInfo: [AnyHashable: Any]?

    override func viewDidLoad() {
        super.viewDidLoad()
        allowsDocumentCreation = true
        localizedCreateDocumentActionTitle = L("Create New Diagram")
        browserUserInterfaceStyle = .dark
        delegate = browserDelegate
        view.tintColor = .green
        installDocumentBrowser()
    }

    func installDocumentBrowser() {
        browserDelegate.presentationHandler = { [weak self] url, error in
            guard error == nil else {
                //present error to user e.g UIAlertController
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
        currentDocument?.diagram = diagram
        closeDiagramController()
    }

    func diagramEditorDidUpdateContent(_ controller: DiagramViewController, diagram: Diagram) {
        currentDocument?.diagram = diagram
    }

    func displayDiagramController() {
        guard !editingDocument, let document = currentDocument else { return }
        editingDocument = true
        let controller = DiagramViewController.navigationControllerFactory()
        let diagramViewController = controller.viewControllers[0] as? DiagramViewController
        diagramViewController?.diagramEditorDelegate = self
        diagramViewController?.diagram = document.diagram
        diagramViewController?.restorationInfo = restorationInfo
        // FIXME: below needed?
        diagramViewController?.restorationIdentifier = restorationIdentifier
        diagramViewController?.currentDocument = document
        controller.modalPresentationStyle = .fullScreen
        let topVC = topMostController()
        topVC.present(controller, animated: true)
    }

    // See https://developer.apple.com/forums/thread/114337 and https://stackoverflow.com/questions/57134259/how-to-resolve-keywindow-was-deprecated-in-ios-13-0
    func topMostController() -> UIViewController {
        //        return UIApplication.shared.windows.first(where: \.isKeyWindow)!.rootViewController!
        var topController: UIViewController = keyWindow().rootViewController!
        while (topController.presentedViewController != nil) {
            topController = topController.presentedViewController!
        }
        return topController
    }

    func keyWindow() -> UIWindow {
        return UIApplication.shared.windows.first(where: \.isKeyWindow)!

    }


    // FIXME: editing document not set right on mac when closing opened (not new) document.
    func closeDiagramController(completion: (()->Void)? = nil) {
        let compositeClosure = {
            self.closeCurrentDocument()
            self.editingDocument = false
            completion?()
        }
        if editingDocument {
            print("****dismiss called")
            self.present(self, animated: true, completion: compositeClosure)
            let topVC = topMostController()
            topVC.dismiss(animated: true) {
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

    func openRemoteDocument(_ inboundURL: URL, importIfNeeded: Bool) {
        revealDocument(at: inboundURL, importIfNeeded: importIfNeeded) { (url, error) in
            if let error = error {
                let alert = UIAlertController(title: L("Could Not Open Document"), message: L("EP Diagram could not open this document due to error \(error.localizedDescription)"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default))
                self.present(alert, animated: true)
                os_log("import did fail - %s", log: .errors, type: .error, error.localizedDescription)
            } else if let url = url {
                self.openDocument(url: url)
            }
        }
    }
}

extension DocumentBrowserViewController {
    func openDocument(url: URL) {
        guard !isDocumentCurrentlyOpen(url: url) else { return }
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
}

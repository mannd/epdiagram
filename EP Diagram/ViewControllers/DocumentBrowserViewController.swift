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
        installInportHandler()

        let info = self.restorationInfo
        if info?[DiagramViewController.restorationDoRestorationKey] as? Bool ?? false {
            if let documentURL = info?[DiagramViewController.restorationDocumentURLKey] as? URL {
                if let presentationHandler = browserDelegate.inportHandler {
                    presentationHandler(documentURL, nil)
                openDocument(url: documentURL)
                }
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

    func openDocument3(url: URL) {
        os_log("openDocument(url:) %s", url.path)
        guard !isDocumentCurrentlyOpen(url: url) else {
            print("document is not currently open")
            return }
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
                            print("Bookmark is stale")
                            resolvedURL.stopAccessingSecurityScopedResource()
                            // create new bookmark if possible
                            self.openDocumentURL(url, createBookmark: true)
                            print("Attempt to refresh bookmark")
                        } else {
                            self.openDocumentURL(resolvedURL)
                        }
                        resolvedURL.stopAccessingSecurityScopedResource()
                    }
                }
            } else {
                print("could not find bookmark")
                self.openDocumentURL(url, createBookmark: true)
            }
        }
    }

    func openDocument(url: URL) {
        os_log("openDocument(url:) %s", url.path)
        guard !isDocumentCurrentlyOpen(url: url) else {
            print("document is not currently open")
            return
        }
//        if self.getDirectoryBookmarkData(url: url.deletingLastPathComponent()) == nil {
//            print("No bookmark data")
//            addDirectoryToSandbox(self)
//            return
//        }
        closeDiagramController {
            if var persistentDirectoryURL = self.getPersistentDirectoryURL(forFileURL: url) {
                let didStartAccessing = persistentDirectoryURL.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        persistentDirectoryURL.stopAccessingSecurityScopedResource()
                    }
                }
                persistentDirectoryURL = persistentDirectoryURL.appendingPathComponent(url.lastPathComponent)
                let document = DiagramDocument(fileURL: persistentDirectoryURL)
                document.open { openSuccess in
                    guard openSuccess else {
                        print ("could not open \(url)")
                        return
                    }
                    self.currentDocument = document
                    self.displayDiagramController()
                }
            } else {
                print("could not get bookmark")
//                self.createBookmarkFromURL(url.deletingLastPathComponent())
            }
        }
    }


    private func openDocumentURL(_ url: URL, createBookmark: Bool = false) {
        os_log("openDocumentURL(_:) %s", url.path)

        let document = DiagramDocument(fileURL: url)
        document.open { openSuccess in
            guard openSuccess else {
                print ("could not open \(url)")
                return
            }
//            if createBookmark {
//                self.createBookmarkFromURL(url)
//            }
            self.currentDocument = document
            self.displayDiagramController()
        }
    }

    func createBookmarkFromURL(_ url: URL) {
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

    private func getAccessKey(url: URL) -> String {
        return "Access:\(url.path)"
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

    /// Get the persisted directory location via bookmarks for a file url
    /// - Parameter url: The URL of the file to be opened.
    /// - Returns: The persistent URL of the directory containing that file.
    func getPersistentDirectoryURL(forFileURL url: URL) -> URL? {
        if let bookmark = getDirectoryBookmarkData(url: url) {
            if let persistentURL = getPersistenDirectoryURL(forBookmarkData: bookmark, directoryURL: url) {
                return persistentURL
            } else {
                print("Could not retrieve bookmark")
                return nil
            }
        }
        else {
            print("Could not get bookmark from UserDefaults")
            return nil
        }
//        // Get directory part of url
//        let directory = url.deletingLastPathComponent()
//        guard directory.hasDirectoryPath else { return nil }
//        let key = getAccessDirectoryKey(for: directory)
//        if let bookmark = UserDefaults.standard.value(forKey: key) as? Data {
//            #if targetEnvironment(macCatalyst)
//            let bookmarkOptions: URL.BookmarkResolutionOptions = [.withSecurityScope]
//            #else
//            let bookmarkOptions: URL.BookmarkResolutionOptions = []
//            #endif
//            var bookmarkDataIsStale: Bool = false
//            if let urlForBookmark = try? URL(resolvingBookmarkData: bookmark, options: bookmarkOptions, relativeTo: nil, bookmarkDataIsStale: &bookmarkDataIsStale) {
//                if bookmarkDataIsStale {
//                    print("Regenerating stale bookmark")
//                    storeDirectoryBookmark(from: directory)
//                    return nil
//                } else {
//                    return urlForBookmark
//                }
//            } else {
//                print("Could not retrieve bookmark")
//                return nil
//            }
//        } else {
//            print("Could not get bookmark from UserDefaults")
//            return nil
//        }
    }

    func getPersistenDirectoryURL(forBookmarkData bookmark: Data, directoryURL directory: URL) -> URL? {
        #if targetEnvironment(macCatalyst)
        let bookmarkOptions: URL.BookmarkResolutionOptions = [.withSecurityScope]
        #else
        let bookmarkOptions: URL.BookmarkResolutionOptions = []
        #endif
        var bookmarkDataIsStale: Bool = false
        if let urlForBookmark = try? URL(resolvingBookmarkData: bookmark, options: bookmarkOptions, relativeTo: nil, bookmarkDataIsStale: &bookmarkDataIsStale) {
            if bookmarkDataIsStale {
                print("Regenerating stale bookmark")
                storeDirectoryBookmark(from: directory)
                return nil
            } else {
                return urlForBookmark
            }
        } else {
            print("Could not retrieve bookmark")
            return nil
        }
    }

    func getDirectoryBookmarkData(url: URL) -> Data? {
        let directory = url.deletingLastPathComponent()
        guard directory.hasDirectoryPath else { return nil }
        let key = getAccessDirectoryKey(for: directory)
        return UserDefaults.standard.value(forKey: key) as? Data
    }

    private func getAccessDirectoryKey(for url: URL) -> String {
        return "AccessDirectory:\(url.path)"
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
//        UIApplication.topViewController()?.present(controller, animated: true)
        self.present(controller, animated: true)
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
                compositeClosure()
            }
        } else {
            compositeClosure()
        }
    }

    private func closeCurrentDocument() {
        guard currentDocument != nil else {
            print("current document is nil!"); return
        }
        currentDocument?.close() { success in
            guard success else {
                print("failed to close document")
                return
            }
        }
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

    @IBAction func macSelectImage(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.macSelectImage(sender)
        }
    }

    @IBAction func addDirectoryToSandbox(_ sender: Any) {
        let action: ((UIAlertAction)->Void) = { _ in
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                if let plugin = appDelegate.appKitPlugin {
                    if let nsWindow = self.view.window?.nsWindow {
                        let completion: ((URL)->Void) = { url in
                            self.storeDirectoryBookmark(from: url)
                            print("directoryURL", url as Any)
                        }
                        plugin.getDirectory(nsWindow: nsWindow, startingURL: nil, completion: completion)
                    }
                }
            }
        }
        UserAlert.showWarning(viewController: self, title: L("Add Directory To Sandbox"), message: L("In order to save diagram files to this folder, it is necessary to add the folder to the app sandbox.  Use the open dialog that appears when you select OK to select the folder.  You should only need to do this once per folder.  If you want to abort opening the file, select Cancel.  Note: You can reset the app sandbox at any time using the Clear Sandbox menu item in the Files menu."), action: action)
    }

    @IBAction func clearSandbox(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.clearSandbox(sender)
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



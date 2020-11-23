//
//  DocumentBrowserDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 11/22/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

class DocumentBrowserDelegate: NSObject, UIDocumentBrowserViewControllerDelegate {
    var presentationHandler: ((URL?, Error?) -> Void)?

    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {

        let cacheDocumentURL = createNewDocumentURL()
        let newDocument = DiagramDocument(fileURL: cacheDocumentURL)
        newDocument.save(to: cacheDocumentURL, for: .forCreating) { saveSuccess in
            guard saveSuccess else {
                importHandler(nil, .none)
                return
            }
            newDocument.close { closeSuccess in
                guard closeSuccess else {
                    importHandler(nil, .none)
                    return
                }

                importHandler(cacheDocumentURL, .move)
            }

        }
  }

  func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
    guard let pickedURL = documentURLs.first else { return }
    print("pickedURL = \(pickedURL)")
    presentationHandler?(pickedURL, nil)
  }

  func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
    presentationHandler?(destinationURL, nil)
  }

  func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
    presentationHandler?(documentURL, error)
  }

}

extension DocumentBrowserDelegate {
    private func getDocumentName() -> String {
        let newDocTag = UUID().uuidString
        return "\(newDocTag)"
    }

    func createNewDocumentURL() -> URL {
        guard let cachePath = FileIO.getURL(for: .cache) else {
            fatalError()
        }
        let newName = getDocumentName()
        let tempURL = cachePath
            .appendingPathComponent(newName)
            .appendingPathExtension(DiagramDocument.extensionName)
        print("tempURL = \(tempURL)")
        return tempURL
    }
}



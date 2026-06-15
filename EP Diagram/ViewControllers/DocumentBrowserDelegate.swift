//
//  DocumentBrowserDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 11/22/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

class DocumentBrowserDelegate: NSObject, UIDocumentBrowserViewControllerDelegate {
    var inportHandler: ((URL?, Error?) -> Void)?

    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        createBlankDocument { documentURL in
            guard let documentURL = documentURL else {
                importHandler(nil, .none)
                return
            }
            importHandler(documentURL, .move)
        }
    }

    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let pickedURL = documentURLs.first else { return }
        inportHandler?(pickedURL, nil)
    }

    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        inportHandler?(destinationURL, nil)
    }

    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        inportHandler?(documentURL, error)
    }
}

extension DocumentBrowserDelegate {
    static let newDocumentNumberKey = "newDocumentNumberKey"

    private func documentName(for number: Int) -> String {
        return "Untitled \(number)"
    }

    private func nextDocumentNumber(after number: Int) -> Int {
        let newDocNumber = number + 1
        return newDocNumber >= Int.max ? 1 : newDocNumber
    }

    func createNewDocumentURL(in directory: URL? = nil, name: String? = nil) -> URL {
        guard let baseURL = directory ?? FileIO.getCacheURL() else {
            fatalError()
        }

        if let name = name {
            UserDefaults.standard.set(nextDocumentNumber(after: UserDefaults.standard.integer(forKey: DocumentBrowserDelegate.newDocumentNumberKey)), forKey: DocumentBrowserDelegate.newDocumentNumberKey)
            return baseURL
                .appendingPathComponent(name)
                .appendingPathExtension(DiagramDocument.extensionName)
        }

        var documentNumber = UserDefaults.standard.integer(forKey: DocumentBrowserDelegate.newDocumentNumberKey)
        var documentURL: URL
        repeat {
            documentURL = baseURL
                .appendingPathComponent(documentName(for: documentNumber))
                .appendingPathExtension(DiagramDocument.extensionName)
            documentNumber = nextDocumentNumber(after: documentNumber)
        } while FileManager.default.fileExists(atPath: documentURL.path)

        UserDefaults.standard.set(documentNumber, forKey: DocumentBrowserDelegate.newDocumentNumberKey)
        return documentURL
    }

    func createBlankDocument(at documentURL: URL? = nil, completion: @escaping (URL?) -> Void) {
        let newDocumentURL = documentURL ?? createNewDocumentURL()
        let newDocument = DiagramDocument(fileURL: newDocumentURL)
        newDocument.save(to: newDocumentURL, for: .forCreating) { saveSuccess in
            guard saveSuccess else {
                completion(nil)
                return
            }
            newDocument.close { closeSuccess in
                guard closeSuccess else {
                    completion(nil)
                    return
                }
                completion(newDocumentURL)
            }
        }
    }
}



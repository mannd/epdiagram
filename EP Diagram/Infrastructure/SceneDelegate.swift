//
//  SceneDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 10/23/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    #if targetEnvironment(macCatalyst)
    private let zoomInToolbarButton = NSToolbarItem.Identifier(rawValue: "macZoomInButton")
    private let zoomOutToolbarButton = NSToolbarItem.Identifier(rawValue: "macZoomOutButton")
    private let zoomResetToolbarButton = NSToolbarItem.Identifier(rawValue: "macZoomResetButton")
    private let undoToolbarButton = NSToolbarItem.Identifier(rawValue: "macUndoButton")
    private let redoToolbarButton = NSToolbarItem.Identifier(rawValue: "macRedoButton")
    private let snapshotToolbarButton = NSToolbarItem.Identifier(rawValue: "macSnapshotButton")
    private let importImageToolbarButton = NSToolbarItem.Identifier(rawValue: "macImportImageButton")
    #endif

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        os_log("scene(scene:willConnectTo:options:) - SceneDelegate session=%s userActivities=%d urlContexts=%d", log: .lifeCycle, type: .info, session.persistentIdentifier, connectionOptions.userActivities.count, connectionOptions.urlContexts.count)
        guard let scene = (scene as? UIWindowScene) else { return }
        if let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController {
            scene.title = L("EP Diagram")
            if connectionOptions.userActivities.isEmpty && !connectionOptions.urlContexts.isEmpty {
                os_log("willConnect using URL contexts and clearing restoration info", log: .lifeCycle, type: .info)
                scene.userActivity = NSUserActivity(activityType: AppDelegate.mainActivityType)
                documentBrowserViewController.restorationInfo = nil
            } else {
                scene.userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity ?? NSUserActivity(activityType: AppDelegate.mainActivityType)
                documentBrowserViewController.restorationInfo = scene.userActivity?.userInfo
                os_log("willConnect selected userActivity type=%s userInfo=%s", log: .lifeCycle, type: .info, scene.userActivity?.activityType ?? "nil", String(describing: scene.userActivity?.userInfo))
            }

            #if targetEnvironment(macCatalyst)
            if shouldShowMacWelcomeScene(for: scene, connectionOptions: connectionOptions) {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                      appDelegate.claimMacWelcomeScene(session: session) else {
                    os_log("willConnect destroying duplicate Mac welcome scene session=%s", log: .lifeCycle, type: .info, session.persistentIdentifier)
                    UIApplication.shared.requestSceneSessionDestruction(session, options: nil) { error in
                        print("Error closing duplicate welcome window", error.localizedDescription)
                    }
                    return
                }
                os_log("willConnect routing Mac welcome scene", log: .lifeCycle, type: .info)
                scene.title = L("EP Diagram")
                scene.userActivity = NSUserActivity(activityType: AppDelegate.mainActivityType)
                documentBrowserViewController.restorationInfo = nil
                window?.rootViewController = MacWelcomeViewController()
                return
            }

            let toolbar = NSToolbar(identifier: "EP Diagram Mac Toolbar")
            toolbar.delegate = self
            toolbar.displayMode = .iconOnly
            toolbar.allowsUserCustomization = true
            scene.titlebar?.toolbar = toolbar
            scene.titlebar?.toolbarStyle = .automatic
            scene.titlebar?.titleVisibility = .visible
            scene.windowingBehaviors?.isClosable = true
            #endif

            if !connectionOptions.urlContexts.isEmpty {
                os_log("willConnect routing URL contexts", log: .lifeCycle, type: .info)
                scene.userActivity = NSUserActivity(activityType: AppDelegate.mainActivityType)
                documentBrowserViewController.restorationInfo = nil
                self.scene(scene, openURLContexts: connectionOptions.urlContexts)
            } else if shouldOpenBrowser(from: scene.userActivity) {
                os_log("willConnect routing open browser activity", log: .lifeCycle, type: .info)
                scene.userActivity = NSUserActivity(activityType: AppDelegate.mainActivityType)
                documentBrowserViewController.restorationInfo = nil
            } else if shouldCreateNewDocument(from: scene.userActivity) {
                os_log("willConnect routing create new document activity", log: .lifeCycle, type: .info)
                scene.userActivity = NSUserActivity(activityType: AppDelegate.mainActivityType)
                documentBrowserViewController.createNewDocument()
            } else if let documentURL = documentURL(from: scene.userActivity) {
                os_log("willConnect routing open document activity url=%s", log: .lifeCycle, type: .info, documentURL.path)
                documentBrowserViewController.openDocument(url: documentURL)
            } else {
                os_log("willConnect routing idle browser/restoration scene", log: .lifeCycle, type: .info)
            }
        } else if (window?.rootViewController as? MacPreferencesViewController) != nil  {
            scene.title = L("Preferences")
            //            scene.userActivity = session.stateRestorationActivity ?? NSUserActivity(activityType: AppDelegate.mainActivityType)

            // See https://stackoverflow.com/questions/68614784/how-to-set-a-default-preferred-window-size-for-a-mac-catalyst-app
            // Default preferences window size is too big, so resize new window.
            scene.sizeRestrictions?.minimumSize = CGSize(width: 500, height: 600)
            // This will be the "preferred size" i.e. the default size
            scene.sizeRestrictions?.maximumSize = CGSize(width: 600, height: 800)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // This allows window to be resized after it appears.
                scene.sizeRestrictions?.maximumSize = CGSize(width: 9000, height: 9000)
            }
        } else {
            fatalError("Unknown scene")
        }
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        os_log("stateRestorationActivity(scene:) - SceneDelegate session=%s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
        guard let documentBrowserViewController = self.window?.rootViewController as? DocumentBrowserViewController else {
            os_log("stateRestorationActivity returning scene.userActivity because root is not DocumentBrowserViewController", log: .lifeCycle, type: .info)
            return scene.userActivity
        }
        let activity = documentBrowserViewController.stateRestorationActivity
        os_log("stateRestorationActivity returning type=%s userInfo=%s", log: .lifeCycle, type: .info, activity.activityType, String(describing: activity.userInfo))
        return activity
    }

    private func shouldCreateNewDocument(from userActivity: NSUserActivity?) -> Bool {
        return userActivity?.userInfo?[AppDelegate.createNewDocumentKey] as? Bool ?? false
    }

    private func shouldOpenBrowser(from userActivity: NSUserActivity?) -> Bool {
        return userActivity?.userInfo?[AppDelegate.openBrowserKey] as? Bool ?? false
    }

    private func documentURL(from userActivity: NSUserActivity?) -> URL? {
        guard let value = userActivity?.userInfo?[AppDelegate.openDocumentURLKey] else { return nil }
        if let url = value as? URL {
            return url
        }
        if let urlString = value as? String {
            return URL(string: urlString)
        }
        return nil
    }

    #if targetEnvironment(macCatalyst)
    private func shouldShowMacWelcomeScene(for scene: UIWindowScene, connectionOptions: UIScene.ConnectionOptions) -> Bool {
        guard connectionOptions.urlContexts.isEmpty else { return false }
        if shouldCreateNewDocument(from: scene.userActivity) { return false }
        if documentURL(from: scene.userActivity) != nil { return false }
        return true
    }

    #endif

    // Used for opening external documents (from Finder or Open Recent menu).
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        os_log("scene(_:openURLContexts:) - SceneDelegate session=%s count=%d", log: .lifeCycle, type: .info, scene.session.persistentIdentifier, URLContexts.count)
        guard let documentBrowserViewController = self.window?.rootViewController as? DocumentBrowserViewController else {
            os_log("openURLContexts routing file URLs to new scenes because root is not DocumentBrowserViewController", log: .lifeCycle, type: .info)
            let openedFileURLs = URLContexts.filter { $0.url.isFileURL }
            for context in openedFileURLs {
                openDocumentInNewScene(url: context.url)
            }
            #if targetEnvironment(macCatalyst)
            if !openedFileURLs.isEmpty, self.window?.rootViewController is MacWelcomeViewController {
                closeMacWelcomeScene(scene)
            }
            #endif
            return
        }
        for context in URLContexts {
            print("context path", context.url.path)
            let url = context.url
            if url.isFileURL {
                if documentBrowserViewController.isDocumentCurrentlyOpen(url: url) {
                    os_log("openURLContexts ignored duplicate already-open document: %s", log: .lifeCycle, type: .info, url.path)
                } else if documentBrowserViewController.isEditingDocument {
                    os_log("openURLContexts routing to new scene because current browser is editing: %s", log: .lifeCycle, type: .info, url.path)
                    openDocumentInNewScene(url: url)
                } else {
                    os_log("openURLContexts routing to current scene: %s", log: .lifeCycle, type: .info, url.path)
                    documentBrowserViewController.openDocument(url: url)
                }
            } else {
                os_log("openURLContexts ignored non-file URL: %s", log: .lifeCycle, type: .info, url.absoluteString)
            }
         }
    }

    private func openDocumentInNewScene(url: URL) {
        os_log("openDocumentInNewScene(url:) - SceneDelegate url=%s", log: .lifeCycle, type: .info, url.path)
        let activity = NSUserActivity(activityType: AppDelegate.mainActivityType)
        activity.addUserInfoEntries(from: [AppDelegate.openDocumentURLKey: url.absoluteString])
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { error in
            print("Error opening document in new window", error.localizedDescription)
        }
    }

    #if targetEnvironment(macCatalyst)
    private func closeMacWelcomeScene(_ scene: UIScene) {
        os_log("closeMacWelcomeScene(_:) session=%s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
        UIApplication.shared.requestSceneSessionDestruction(scene.session, options: nil) { error in
            print("Error closing welcome window", error.localizedDescription)
        }
    }
    #endif

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        os_log("scene(_:continue:) - SceneDelegate, %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
        if let window = self.window {
            window.rootViewController?.restoreUserActivityState(userActivity)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        os_log("sceneDidDisconnect(_:) - SceneDelegate, %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
        #if targetEnvironment(macCatalyst)
        if self.window?.rootViewController is MacWelcomeViewController,
           let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.releaseMacWelcomeScene(session: scene.session)
            return
        }
        #endif
        guard let documentBrowserViewController = self.window?.rootViewController as? DocumentBrowserViewController else { return }
        documentBrowserViewController.closeCurrentDocument()
    }


    func sceneWillResignActive(_ scene: UIScene) {
        os_log("sceneWillResignActive(_:) - SceneDeleage", log: .lifeCycle, type: .info)
    }

    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        print("scene did fail to continue user activity")
    }

}

#if targetEnvironment(macCatalyst)
extension SceneDelegate: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        let space = NSToolbarItem.Identifier.space
        return [NSToolbarItem.Identifier.flexibleSpace, importImageToolbarButton, space,  undoToolbarButton, redoToolbarButton, space, zoomInToolbarButton, zoomOutToolbarButton, zoomResetToolbarButton, space, snapshotToolbarButton]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case zoomInToolbarButton:
            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus.magnifyingglass"), style: .plain, target: nil, action:  #selector(DiagramViewController.doZoom(_:)))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            button.tag = 0
            button.toolTip = L("Zoom in")
            return button
        case zoomOutToolbarButton:
            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "minus.magnifyingglass"), style: .plain, target: nil, action:  #selector(DiagramViewController.doZoom(_:)))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            button.tag = 1
            button.toolTip = L("Zoom out")
            return button
        case zoomResetToolbarButton:
            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "1.magnifyingglass"), style: .plain, target: nil, action:  #selector(DiagramViewController.doZoom(_:)))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            button.tag = 2
            button.toolTip = L("Reset zoom")
            return button
        case undoToolbarButton:
            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.left"), style: .plain, target: nil, action: #selector(DiagramViewController.undo))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            button.toolTip = L("Undo")
            return button
        case redoToolbarButton:
            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.right"), style: .plain, target: nil, action: #selector(DiagramViewController.redo))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            button.toolTip = L("Redo")
            return button
        case snapshotToolbarButton:
            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "camera.on.rectangle"), style: .plain, target: nil, action: #selector(DiagramViewController.macSnapshotDiagram(_:)))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            button.toolTip = L("Save screenshot of diagram")
            return button
        case importImageToolbarButton:
            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"), style: .plain, target: nil, action: #selector(DiagramViewController.macSelectImage(_:)))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            button.toolTip = L("Import image")
            return button
        default:
            return nil
        }
    }

}
#endif

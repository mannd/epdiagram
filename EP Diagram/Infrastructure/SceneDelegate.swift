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
    private let closeToolbarButton = NSToolbarItem.Identifier(rawValue: "macCloseButton")
    private let undoToolbarButton = NSToolbarItem.Identifier(rawValue: "macUndoButton")
    private let redoToolbarButton = NSToolbarItem.Identifier(rawValue: "macRedoButton")
    private let snapshotToolbarButton = NSToolbarItem.Identifier(rawValue: "macSnapshotButton")
    #endif

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        os_log("scene(scene:willConnectTo:options:) - SceneDelegate", log: .lifeCycle, type: .info)
        guard let scene = (scene as? UIWindowScene) else { return }
        if let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController {
            scene.title = L("EP Diagram")
            scene.userActivity = session.stateRestorationActivity ?? NSUserActivity(activityType: AppDelegate.mainActivityType)
            documentBrowserViewController.restorationInfo = scene.userActivity?.userInfo

            #if targetEnvironment(macCatalyst)
            let toolbar = NSToolbar(identifier: "EP Diagram Mac Toolbar")
            toolbar.delegate = self
            toolbar.displayMode = .iconOnly
            toolbar.allowsUserCustomization = true
            scene.titlebar?.toolbar = toolbar
            scene.titlebar?.toolbarStyle = .automatic
            scene.titlebar?.titleVisibility = .visible
            // populate toolbar

            #endif
            // This appears to be necessary for double click to open diagram on Mac (and ? on iPad too).
            // FIXME: don't we still need this at least for iOS???
//            self.scene(scene, openURLContexts: connectionOptions.urlContexts)
        } else if (window?.rootViewController as? MacPreferencesViewController) != nil  {
            scene.title = L("Preferences")
        } else {
            fatalError("Unknown scene")
        }
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        os_log("stateRestorationActivity(scene:) - SceneDelegate", log: .lifeCycle, type: .info)
        return scene.userActivity
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        os_log("scene(_:openURLContexts:) - SceneDelegate", log: .lifeCycle, type: .info)
        guard let documentBrowserViewController = self.window?.rootViewController as? DocumentBrowserViewController else { return }
        for context in URLContexts {
            print("context path", context.url.path)
            let url = context.url
            if url.isFileURL && UIApplication.shared.canOpenURL(url) {
                documentBrowserViewController.openDocument(url: url)
            }
         }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        os_log("scene(_:continue:) - SceneDelegate, %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
        if let window = self.window {
            window.rootViewController?.restoreUserActivityState(userActivity)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        os_log("$$$sceneDidDisconnect(_:) - SceneDelegate, %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        os_log("$$$sceneWillResignActive(_:) - SceneDeleage", log: .lifeCycle, type: .info)
    }

    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        print("****scene did fail to continue user activity")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print("sceneDid")
    }
}

#if targetEnvironment(macCatalyst)
extension SceneDelegate: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        let space = NSToolbarItem.Identifier.space
        return [NSToolbarItem.Identifier.flexibleSpace, undoToolbarButton, redoToolbarButton, space, zoomInToolbarButton, zoomOutToolbarButton, zoomResetToolbarButton, space, snapshotToolbarButton, space, closeToolbarButton]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case closeToolbarButton:
            let barButtonItem = UIBarButtonItem(title: L("Close"), style: .done, target: nil, action: #selector(DiagramViewController.macCloseDocument(_:)))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            button.toolTip = L("Close diagram")
            return button
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
            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "photo.on.rectangle"), style: .plain, target: nil, action: #selector(DiagramViewController.macSnapshotDiagram(_:)))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            button.toolTip = L("Snapshot diagram")
            return button
        default:
            return nil
        }
    }

}
#endif

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

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        os_log("scene(scene:willConnectTo:options:) - SceneDelegate", log: .lifeCycle, type: .info)
        guard let scene = (scene as? UIWindowScene) else { return }
        if let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController {
            print("*****connecting to documentBrowserVC")
            scene.title = L("EP Diagram")
            scene.userActivity = session.stateRestorationActivity ?? NSUserActivity(activityType: AppDelegate.mainActivityType)
            documentBrowserViewController.restorationInfo = scene.userActivity?.userInfo

            #if targetEnvironment(macCatalyst)
            scene.titlebar?.toolbar = NSToolbar()
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

    // from https://gist.github.com/steipete/30c33740bf0ebc34a0da897cba52fefe
//    func nsWindow(from window: UIWindow) -> AnyObject? {
//        guard let nsWindows = NSClassFromString("NSApplication")?.value(forKeyPath: "sharedApplication.windows") as? [AnyObject] else { return nil }
//        for nsWindow in nsWindows {
//            let uiWindows = nsWindow.value(forKeyPath: "uiWindows") as? [UIWindow] ?? []
//            if uiWindows.contains(window) { return nsWindow }
//        }
//        return nil
//    }
  
}

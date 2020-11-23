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
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        os_log("scene(scene:willConnectTo:options:), %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
        guard let scene = (scene as? UIWindowScene) else { return }
        scene.title = L("EP Diagram")
        scene.userActivity = session.stateRestorationActivity ?? NSUserActivity(activityType: "org.epstudios.epdiagram.mainActivity")

        if let rvc = window?.rootViewController as? RootViewController {



            rvc.restorationInfo = scene.userActivity?.userInfo
            rvc.persistentID = scene.session.persistentIdentifier
        }
    }

   
    func sceneWillEnterForeground(_ scene: UIScene) {
        os_log("sceneWillEnterForeground(scene:), %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        os_log("sceneDidEnterBackground(scene:), %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        os_log("sceneWillResignActive(scene:), %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        os_log("sceneDidBecomeActive(scene:), %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        os_log("sceneDidDisconnect(scene:), %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        os_log("stateRestorationActivity(scene:), %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
        return scene.userActivity
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        os_log("scene(_:openURLContexts), %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
//        let navigationController = self.window?.rootViewController as? UINavigationController
//        let viewController = navigationController?.viewControllers[0] as? ViewController
//        for context in URLContexts {
//            let url = context.url
//            // FIXME: Handle diagrams and ladders differently??
//            if url.isFileURL && url.pathExtension.uppercased() != "DIAGRAM" {
//                viewController?.launchFromURL = true
//                viewController?.launchURL = url
//                viewController?.openURL(url: url)
//            }
//        }
    }
}

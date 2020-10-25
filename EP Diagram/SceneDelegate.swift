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
        guard let _ = (scene as? UIWindowScene) else { return }
    }


    func sceneWillEnterForeground(_ scene: UIScene) {
        os_log("sceneWillEnterForeground(scene:)", log: .lifeCycle, type: .info)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        os_log("sceneDidEnterBackground(scene:)", log: .lifeCycle, type: .info)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        os_log("sceneWillResignActive(scene:)", log: .lifeCycle, type: .info)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        os_log("sceneDidBecomeActive(scene:)", log: .lifeCycle, type: .info)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        let navigationController = self.window?.rootViewController as? UINavigationController
        let viewController = navigationController?.viewControllers[0] as? ViewController
        for context in URLContexts {
            let url = context.url
            if url.isFileURL {
                viewController?.launchFromURL = true
                viewController?.launchURL = url
                viewController?.openURL(url: url)
            }
        }
    }
}

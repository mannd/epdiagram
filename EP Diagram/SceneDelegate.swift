//
//  SceneDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 10/23/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    // FIXME: will we open external urls (images, pdfs?)
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

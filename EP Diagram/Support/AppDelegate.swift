//
//  AppDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/29/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var ubiqURL: URL?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // TODO: Add further defaults here.
        UserDefaults.standard.register(defaults: [
            Preferences.defaultLineWidthKey: Preferences.lineWidth,
            Preferences.defaultCursorLineWidthKey: Preferences.cursorLineWidth,
            Preferences.defaultShowImpulseOriginKey: Preferences.showImpulseOrigin,
            Preferences.defaultShowBlockKey: Preferences.showBlock,
            Preferences.defaultShowIntervalsKey: Preferences.showIntervals,
            Preferences.defaultSnapMarksKey: Preferences.snapMarks,
        ])
        // Check for iCloud availability
        // TODO: test this!
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            let ubiqURL = fileManager.url(forUbiquityContainerIdentifier: nil)
            DispatchQueue.main.async {
                self.ubiqURL = ubiqURL
            }
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        let sceneConfiguration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        return sceneConfiguration
    }
}



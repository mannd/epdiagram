//
//  AppDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/29/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UserDefaults.standard.register(defaults: [Preferences.defaultLineWidthKey: 2, Preferences.defaultShowImpulseOriginKey: false, Preferences.defaultShowBlockKey: true, Preferences.defaultShowIntervalsKey: false, Preferences.defaultLastDiagramKey: "" ])
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let navigationController = self.window?.rootViewController as? UINavigationController
        let viewController = navigationController?.viewControllers[0] as? ViewController
        if url.isFileURL {
            viewController?.launchFromURL = true
            viewController?.launchURL = url
            viewController?.openURL(url: url)
        }
        return true
    }


//        UINavigationController *navigationController = (UINavigationController *)  self.window.rootViewController;
//        EPSMainViewController *mainViewController = (EPSMainViewController *) [navigationController.viewControllers objectAtIndex:0];
//
//
//        if (url != nil && [url isFileURL]) {
//            // Note that openURL won't run the first time program loads, so we pass the relevant info
//            // to mainViewController which calls openURL in viewDidLoad.
//            mainViewController.launchFromURL = YES;
//            mainViewController.launchURL = url;
//            [mainViewController openURL:url];
//        }
//        return YES;

    }



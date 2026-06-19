//
//  AppDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/29/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import os.log
#if targetEnvironment(macCatalyst)
import AppKit
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var ubiqURL: URL?
    var preferencesDialogIsOpen: Bool = false
    var appKitPlugin: SharedAppKitProtocol?

    static let mainActivityType = "org.epstudios.epdiagram.mainActivity"
    static let preferencesActivityType = "org.epstudios.epdiagram.preferencesActivity"
    static let openDocumentURLKey = "org.epstudios.epdiagram.openDocumentURL"
    static let createNewDocumentKey = "org.epstudios.epdiagram.createNewDocument"
    static let openBrowserKey = "org.epstudios.epdiagram.openBrowser"
    #if targetEnvironment(macCatalyst)
    private var hasHandledInitialCatalystActivation = false
    private var macWelcomeSceneSessionIdentifier: String?
    #endif

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        os_log("application(_:didFinishLaunchingWithOptions:) - AppDelegate", log: .lifeCycle, type: .info)

        // Register defaults for preferences.
        UserDefaults.standard.register(defaults: Preferences.defaults())

        // Check for iCloud availability.
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            let ubiqURL = fileManager.url(forUbiquityContainerIdentifier: nil)
            DispatchQueue.main.async {
                self.ubiqURL = ubiqURL
            }
        }
        #if targetEnvironment(macCatalyst)
        loadAppKitPlugin()

        // Saving a million startup issues, force startup without restoring old windows.
        // Yes, this really exists.
        // See https://stackoverflow.com/questions/69552157/mac-catalyst-prevent-scene-creation-or-create-with-invisible-window
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
        #endif

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        #if targetEnvironment(macCatalyst)
        guard hasHandledInitialCatalystActivation else {
            hasHandledInitialCatalystActivation = true
            os_log("applicationDidBecomeActive skipped initial Catalyst activation", log: .lifeCycle, type: .info)
            return
        }
        showWelcomeWindowIfNoVisibleWindows(reason: "applicationDidBecomeActive")
        #endif
    }

    // MARK: UISceneSession Lifecycle
    // NB: This is only called the first time an application is launched.  If there are windows
    // that are being restored by the operating system (macOS), this is skipped.
    // See https://stackoverflow.com/questions/63520008/why-is-uiapplicationdelegate-method-application-configurationforconnectingop
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        os_log("application(_:configurationForConnecting:options:) session=%s userActivities=%d urlContexts=%d", log: .lifeCycle, type: .info, connectingSceneSession.persistentIdentifier, options.userActivities.count, options.urlContexts.count)
        if let userActivity = options.userActivities.first {
            os_log("configuration userActivity type=%s userInfo=%s", log: .lifeCycle, type: .info, userActivity.activityType, String(describing: userActivity.userInfo))
        }
        if options.userActivities.first?.activityType == Self.preferencesActivityType {
            os_log("configuration returning Preferences Configuration", log: .lifeCycle, type: .info)
            let sceneConfiguration = UISceneConfiguration(name: "Preferences Configuration", sessionRole: connectingSceneSession.role)
            return sceneConfiguration
        } else { //if options.userActivities.first?.activityType == Self.mainActivityType {
            os_log("configuration returning Default Configuration", log: .lifeCycle, type: .info)
            let sceneConfiguration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
            return sceneConfiguration
        }
    }
}

#if targetEnvironment(macCatalyst)
extension AppDelegate {

    // MARK: - Mac support app kit plugin

    @objc func loadAppKitPlugin() {
        let bundleFileName = "MacSupport.bundle"
        guard let bundleURL = Bundle.main.builtInPlugInsURL?
                .appendingPathComponent(bundleFileName) else { return }

        guard let bundle = Bundle(url: bundleURL) else { return }

        let className = "MacSupport.MacSupport"
        guard let pluginClass = bundle.classNamed(className) as? SharedAppKitProtocol.Type else { return }

        self.appKitPlugin = pluginClass.init()
    }

    // MARK: - macOS menu

    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        guard builder.system == .main else { return }

        // Remove unwanted menus
        builder.remove(menu: .format)

        // Settings menu
        let preferencesCommand = UIKeyCommand(
            title: NSLocalizedString("Settings...", comment: "Menu item title that opens the app settings window."),
            action: #selector(showMacPreferences(_:)),
            input: ",",
            modifierFlags: [.command]
        )
        let openPreferencesMenu = UIMenu(
            title: "",
            image: nil,
            identifier: UIMenu.Identifier("openPreferences"),
            options: .displayInline,
            children: [preferencesCommand]
        )
        builder.insertSibling(openPreferencesMenu, afterMenu: .about)

        // File menu
        let newDiagramCommand = UIKeyCommand(
            title: L("New"),
            action: #selector(newDiagramWindow(_:)),
            input: "n",
            modifierFlags: [.command]
        )
        let openDiagramCommand = UIKeyCommand(
            title: L("Open..."),
            action: #selector(openDiagramFromMenu(_:)),
            input: "o",
            modifierFlags: [.command]
        )
        let newOpenMenu = UIMenu(
            title: "",
            identifier: UIMenu.Identifier("newOpenMenu"),
            options: .displayInline,
            children: [newDiagramCommand, openDiagramCommand]
        )
        builder.replaceChildren(ofMenu: .file) { oldChildren in
            func isDuplicateNewOrOpenCommand(_ element: UIMenuElement) -> Bool {
                guard let keyCommand = element as? UIKeyCommand,
                      keyCommand.modifierFlags.contains(.command),
                      let input = keyCommand.input?.lowercased() else { return false }
                return input == "n" || input == "o"
            }

            func removingDuplicateNewAndOpenCommands(from elements: [UIMenuElement]) -> [UIMenuElement] {
                elements.compactMap { element in
                    if isDuplicateNewOrOpenCommand(element) {
                        return nil
                    }
                    if let menu = element as? UIMenu {
                        if menu.identifier == UIMenu.Identifier("newOpenMenu") {
                            return nil
                        }
                        let children = removingDuplicateNewAndOpenCommands(from: menu.children)
                        return menu.replacingChildren(children)
                    }
                    return element
                }
            }

            var newChildren = removingDuplicateNewAndOpenCommands(from: oldChildren)
            newChildren.insert(newOpenMenu, at: 0)
            return newChildren
        }

        let saveScreenshotCommand = UIKeyCommand(
            title: "Save Screenshot",
            action: #selector(DiagramViewController.macSnapshotDiagram),
            input: "s",
            modifierFlags: [.command]
        )
        let saveScreenshotMenu = UIMenu(
            title: "",
            identifier: UIMenu.Identifier("saveScreenshotMenu"),
            options: .displayInline,
            children: [saveScreenshotCommand]
        )

        let addDirectoryToSandboxCommand = UICommand(
            title: L("Grant Folder Access..."),
            action: #selector(DiagramViewController.addDirectoryToSandbox(_:))
        )
        let clearSandbox = UICommand(
            title: L("Clear Saved Folder Access"),
            action: #selector(DiagramViewController.clearSandbox(_:))
        )
        let sandboxMenu = UIMenu(
            title: "",
            identifier: UIMenu.Identifier("sandboxMenu"),
            options: .displayInline,
            children: [addDirectoryToSandboxCommand, clearSandbox]
        )

        let renameCommand = UIKeyCommand(
            title: L("Rename Diagram..."),
            action: #selector(DiagramViewController.renameDiagram),
            input: "r",
            modifierFlags: [.command]
        )

        let closeWindowCommand = UIKeyCommand(
            title: L("Close Window"),
            action: #selector(DocumentBrowserViewController.closeWindow(_:)),
            input: "w",
            modifierFlags: [.command]
        )
        let closeDiagramMenu = UIMenu(
            title: "",
            identifier: UIMenu.Identifier("closeDiagramMenu"),
            options: .displayInline,
            children: [renameCommand, closeWindowCommand]
        )
        builder.replace(menu: .close, with: closeDiagramMenu)
        builder.insertSibling(saveScreenshotMenu, beforeMenu: UIMenu.Identifier("closeDiagramMenu"))
        builder.insertSibling(sandboxMenu, beforeMenu: UIMenu.Identifier("saveScreenshotMenu"))

        // View menu
        let zoomInCommand = UIKeyCommand(
            title: L("Zoom In"),
            action: #selector(DiagramViewController.doZoom(_:)),
            input: "+",
            modifierFlags: [.command],
            propertyList: "zoomIn"
        )
        let zoomOutCommand = UIKeyCommand(
            title: L("Zoom Out"),
            action: #selector(DiagramViewController.doZoom(_:)),
            input: "-",
            modifierFlags: [.command],
            propertyList: "zoomOut"
        )
        let resetZoomCommand = UIKeyCommand(
            title: L("Reset Zoom"),
            action: #selector(DiagramViewController.doZoom(_:)),
            input: "0",
            modifierFlags: [.command],
            propertyList: "resetZoom"
        )
        let zoomMenu = UIMenu(
            title: L("Zoom..."),
            identifier: UIMenu.Identifier("zoomMenu"),
            options: .displayInline,
            children: [zoomInCommand, zoomOutCommand, resetZoomCommand]
        )
        builder.insertChild(zoomMenu, atStartOfMenu: .view)

        // Diagram menu
        let importPhotoCommand = UICommand(
            title: L("Photo"),
            action: #selector(DiagramViewController.importPhoto(_:))
        )

        let importImageFileCommand = UICommand(
            title: L("File"),
            action: #selector(DiagramViewController.importImageFile(_:))
        )

        let importMenu = UIMenu(
            title: L("Import Image"),
            image: nil,
            identifier: UIMenu.Identifier("importMenu"),
            children: [importPhotoCommand, importImageFileCommand]
        )

        let sampleCommand = UICommand(
            title: L("Samples"),
            action: #selector(DiagramViewController.sampleDiagrams(_:))
        )

        let diagramInfoCommand = UICommand(
            title: L("Diagram Info..."),
            action: #selector(DiagramViewController.getDiagramInfo(_:))
        )
        let diagramInfoMenu = UIMenu(
            title: "",
            identifier: UIMenu.Identifier("diagramInfoMenu"),
            options: .displayInline,
            children: [diagramInfoCommand]
        )

        let editLadderCommand = UICommand(
            title: L("Edit Ladders"),
            action: #selector(DiagramViewController.editLadder(_:))
        )
        let selectLadderCommand = UICommand(
            title: L("Select Ladder"),
            action: #selector(DiagramViewController.selectLadder(_:))
        )

//        let testCommand = UIKeyCommand(
//            title: "Test",
//            action: #selector(DiagramViewController.renameDiagram),
//            input: "t",
//            modifierFlags: [.command]
//        )

        let ladderMenu = UIMenu(title: L("Ladder"), children: [selectLadderCommand, editLadderCommand])

        let diagramMenu = UIMenu(
            title: L("Diagram"),
            identifier: UIMenu.Identifier("diagramMenu"),
            children: [importMenu, ladderMenu, sampleCommand, diagramInfoMenu]
        )
        builder.insertSibling(diagramMenu, afterMenu: .view)

    }

    @IBAction func newDiagramWindow(_ sender: Any) {
        requestNewDiagramScene()
    }

    @IBAction func openDiagramFromMenu(_ sender: Any) {
        os_log("openDiagramFromMenu(_:) - AppDelegate", log: .lifeCycle, type: .info)
        openDiagramWithAppKitPanel { [weak self] url in
            os_log("openDiagramFromMenu selected URL=%s", log: .lifeCycle, type: .info, url.path)
            self?.requestOpenDocumentScene(url: url)
        }
    }

    func openDiagramFromWelcome(_ welcomeViewController: UIViewController) {
        os_log("openDiagramFromWelcome(_:) - AppDelegate", log: .lifeCycle, type: .info)
        openDiagramWithAppKitPanel { [weak self, weak welcomeViewController] url in
            os_log("openDiagramFromWelcome selected URL=%s", log: .lifeCycle, type: .info, url.path)
            self?.requestOpenDocumentScene(url: url)
            if let welcomeViewController = welcomeViewController {
                self?.closeWelcomeWindow(containing: welcomeViewController)
            }
        }
    }

    private func openDiagramWithAppKitPanel(completion: @escaping (URL) -> Void) {
        guard let plugin = appKitPlugin else {
            os_log("openDiagramWithAppKitPanel fallback: AppKit plugin is nil", log: .lifeCycle, type: .info)
            requestMainDocumentBrowserScene(errorMessage: "Error showing open browser")
            return
        }

        let documentBrowserViewController = activeDocumentBrowserViewController()
        let startingURL = documentBrowserViewController?.currentDocument?.fileURL.deletingLastPathComponent()
        os_log("openDiagramWithAppKitPanel showing app-modal AppKit open panel startingURL=%s", log: .lifeCycle, type: .info, startingURL?.path ?? "nil")
        plugin.getDiagram(nsWindow: nil, startingURL: startingURL, completion: completion)
    }

    private func requestNewDiagramScene() {
        os_log("requestNewDiagramScene() - AppDelegate", log: .lifeCycle, type: .info)
        let activity = NSUserActivity(activityType: Self.mainActivityType)
        activity.addUserInfoEntries(from: [Self.createNewDocumentKey: true])
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { error in
            print("Error creating new diagram window", error.localizedDescription)
        }
    }

    private func requestMainDocumentBrowserScene(errorMessage: String) {
        requestMacWelcomeScene(errorMessage: errorMessage)
    }

    private func requestMacWelcomeScene(errorMessage: String) {
        os_log("requestMacWelcomeScene() - AppDelegate errorMessage=%s", log: .lifeCycle, type: .info, errorMessage)
        let activity = NSUserActivity(activityType: Self.mainActivityType)
        activity.addUserInfoEntries(from: [Self.openBrowserKey: true])
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { error in
            print(errorMessage, error.localizedDescription)
        }
    }

    private func requestOpenDocumentScene(url: URL) {
        os_log("requestOpenDocumentScene(url:) - AppDelegate url=%s", log: .lifeCycle, type: .info, url.path)
        let activity = NSUserActivity(activityType: Self.mainActivityType)
        activity.addUserInfoEntries(from: [Self.openDocumentURLKey: url.absoluteString])
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { error in
            print("Error opening diagram", error.localizedDescription)
        }
    }

    func closeWelcomeWindow(containing viewController: UIViewController) {
        guard let sceneSession = viewController.view.window?.windowScene?.session else { return }
        let options = UIWindowSceneDestructionRequestOptions()
        UIApplication.shared.requestSceneSessionDestruction(sceneSession, options: options) { error in
            print("Error closing welcome window", error.localizedDescription)
        }
    }

    func claimMacWelcomeScene(session: UISceneSession) -> Bool {
        if let existingIdentifier = macWelcomeSceneSessionIdentifier,
           existingIdentifier != session.persistentIdentifier {
            os_log("claimMacWelcomeScene rejected duplicate session=%s existing=%s", log: .lifeCycle, type: .info, session.persistentIdentifier, existingIdentifier)
            return false
        }

        macWelcomeSceneSessionIdentifier = session.persistentIdentifier
        os_log("claimMacWelcomeScene accepted session=%s", log: .lifeCycle, type: .info, session.persistentIdentifier)
        return true
    }

    func releaseMacWelcomeScene(session: UISceneSession) {
        guard macWelcomeSceneSessionIdentifier == session.persistentIdentifier else { return }
        os_log("releaseMacWelcomeScene session=%s", log: .lifeCycle, type: .info, session.persistentIdentifier)
        macWelcomeSceneSessionIdentifier = nil
    }

    private func showWelcomeWindowIfNoVisibleWindows(reason: String) {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let visibleWindowCount = windowScenes.reduce(0) { count, scene in
            count + scene.windows.filter { !$0.isHidden }.count
        }
        os_log("showWelcomeWindowIfNoVisibleWindows reason=%s windowScenes=%d visibleWindows=%d", log: .lifeCycle, type: .info, reason, windowScenes.count, visibleWindowCount)
        guard visibleWindowCount == 0 else { return }
        requestMacWelcomeScene(errorMessage: "Error showing welcome window")
    }

    private func activeDocumentBrowserViewController() -> DocumentBrowserViewController? {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScenes = windowScenes.filter { $0.activationState == .foregroundActive }
        let inactiveScenes = windowScenes.filter { $0.activationState == .foregroundInactive }
        let candidateScenes = activeScenes + inactiveScenes
        os_log("activeDocumentBrowserViewController() windowScenes=%d active=%d inactive=%d", log: .lifeCycle, type: .info, windowScenes.count, activeScenes.count, inactiveScenes.count)

        for scene in candidateScenes {
            if let window = scene.windows.first(where: { $0.isKeyWindow }),
               !window.isHidden,
               let documentBrowserViewController = window.rootViewController as? DocumentBrowserViewController {
                os_log("activeDocumentBrowserViewController returning key scene=%s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
                return documentBrowserViewController
            }
        }

        for scene in candidateScenes {
            if let window = scene.windows.first(where: { !$0.isHidden }),
               let documentBrowserViewController = window.rootViewController as? DocumentBrowserViewController {
                os_log("activeDocumentBrowserViewController returning visible scene=%s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
                return documentBrowserViewController
            }
        }

        os_log("activeDocumentBrowserViewController returning nil", log: .lifeCycle, type: .info)
        return nil
    }

    func showMacHelp(_ sender: Any) {
        os_log("showMacHelp(_:) - AppDelegate", log: .lifeCycle, type: .info)
        appKitPlugin?.showHelp()
    }

    // See https://stackoverflow.com/questions/58882047/open-a-new-window-in-mac-catalyst
    @IBAction func showMacPreferences(_ sender: Any) {
        // prevent the menu from opening more than one.
        guard !preferencesDialogIsOpen else { return }
        let activity = NSUserActivity(activityType: Self.preferencesActivityType)
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { (error) in
            print("Error showing Mac preferences", error.localizedDescription)
        }
        preferencesDialogIsOpen = true
    }

}
#endif

//
//  MacWelcomeViewController.swift
//  EP Diagram
//
//  Created by OpenAI on 6/18/26.
//  Copyright © 2026 EP Studios. All rights reserved.
//

#if targetEnvironment(macCatalyst)
import SwiftUI
import UIKit

struct MacWelcomeView: View {
    var newDiagramAction: () -> Void
    var openDiagramAction: () -> Void
    var settingsAction: () -> Void
    var helpAction: () -> Void

    var body: some View {
        VStack(spacing: 46) {
            Text("Welcome to EP Diagram")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.primary)

            VStack(spacing: 14) {
                WelcomeActionButton(title: "Click here or type ⌘ N to create a new diagram", action: newDiagramAction)
                WelcomeActionButton(title: "Click here or type ⌘ O to open a saved diagram", action: openDiagramAction)
                WelcomeActionButton(title: "Click here to change settings", action: settingsAction)
                WelcomeActionButton(title: "Click here for help", action: helpAction)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

private struct WelcomeActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.blue)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

class MacWelcomeViewController: UIHostingController<MacWelcomeView> {
    init() {
        super.init(rootView: MacWelcomeView(
            newDiagramAction: {},
            openDiagramAction: {},
            settingsAction: {},
            helpAction: {}
        ))
        rootView = MacWelcomeView(
            newDiagramAction: {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                appDelegate.newDiagramWindow(appDelegate)
            },
            openDiagramAction: {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                appDelegate.openDiagramFromMenu(appDelegate)
            },
            settingsAction: { [weak self] in
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                appDelegate.showMacPreferences(appDelegate)
                if let self = self {
                    appDelegate.closeWelcomeWindow(containing: self)
                }
            },
            helpAction: { [weak self] in
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                appDelegate.showMacHelp(appDelegate)
                if let self = self {
                    appDelegate.closeWelcomeWindow(containing: self)
                }
            }
        )
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: MacWelcomeView(
            newDiagramAction: {},
            openDiagramAction: {},
            settingsAction: {},
            helpAction: {}
        ))
    }
}
#endif

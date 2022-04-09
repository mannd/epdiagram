//
//  Global.swift
//  EP Diagram
//
//  Created by David Mann on 1/1/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit

// A few macro-like functions in the global namespace

/// Language localization "macro."
/// - Parameters:
///   - s: string to be translated
///   - comment: optional comment for translator
func L(_ s: String, comment: String = "") -> String {
    return NSLocalizedString(s, comment: comment)
}

#if DEBUG
// Make false to suppress printing of messages, even in debug mode.
enum PrintFlags {
    static var printMessages = false
}

/// Print only while in debug mode and when 'printMessages' = true.
///
///  Note that this has largely been supplanted by log statements.
/// - Parameter s: logging message to print
func P(_ s: String) {
    if PrintFlags.printMessages {
        print(s)
    }
}
#else
func P(_ s: String) {}
#endif

// Determine specific platforms
func isRunningOnMac() -> Bool {
    #if targetEnvironment(macCatalyst)
    return true
    #else
    return false
    #endif
}

func isIPad() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

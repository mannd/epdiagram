//
//  Version.swift
//  EP Diagram
//
//  Created by David Mann on 4/17/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

class Version: NSObject {

    typealias VersionBuild = (version: String?, build: String?)
    static func appVersion() -> VersionBuild {
        let dictionary = Bundle.main.infoDictionary
        let version = dictionary?["CFBundleShortVersionString"] as? String
        let build = dictionary?["CFBundleVersion"] as? String
        return (version, build)
    }
}

//
//  String+isBlank.swift
//  EP Diagram
//
//  Created by David Mann on 7/19/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import Foundation

extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespaces).isEmpty
    }
}

extension Optional where Wrapped == String {
    var isBlank: Bool {
        self?.isBlank ?? true
    }
}

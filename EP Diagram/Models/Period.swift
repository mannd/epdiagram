//
//  Period.swift
//  Period
//
//  Created by David Mann on 9/2/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit
import BetterCodable
import os.log

struct Period: Codable {

    var name: String = ""
    var duration: Int = 0

    // height depends on Region height and number of Periods in the region.
}

//
//  Diagram.swift
//  EP Diagram
//
//  Created by David Mann on 6/3/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

struct Diagram: Codable {
    var name: String? // Not used except for samples.  document.name used instead.
    var longDescription: String // Not used except for samples.

    var imageWrapper: ImageWrapper
    var image: UIImage? {
        get { imageWrapper.image }
        set { imageWrapper = ImageWrapper(image: newValue) }
    }
    var imageIsUpscaled: Bool = false
    var ladder: Ladder
    var calibration: Calibration = Calibration()
    var transform: CGAffineTransform
    var leftMargin: CGFloat {
        get { ladder.leftMargin }
        set { ladder.leftMargin = newValue }
    }

    init(name: String?, description: String, image: UIImage?, ladder: Ladder) {
        self.name = name
        self.longDescription = description
        self.imageWrapper = ImageWrapper(image: image)
        self.ladder = ladder
        self.transform = CGAffineTransform.identity
    }

    static func defaultDiagram(name: String? = nil) -> Diagram {
        return Diagram(name: name, description: "Normal ECG", image: UIImage(named: "SampleECG")!, ladder: Ladder.defaultLadder())
    }

    static func blankDiagram(name: String? = nil) -> Diagram {
        let diagram = Diagram(name: name, description: "Blank diagram", image: nil, ladder: Ladder.defaultLadder())
        return diagram
    }

    static func scrollableBlankDiagram() -> Diagram {
        return Diagram(name: L("Scrollable Blank Diagram"), description: L("Wide scrollable blank image"), image: UIImage.emptyImage(size: CGSize(width: 1, height: 1), color: UIColor.systemTeal), ladder: Ladder.defaultLadder())
    }
}

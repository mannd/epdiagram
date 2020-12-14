//
//  UIImage+emptyImage.swift
//  EP Diagram
//
//  Created by David Mann on 8/13/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

// Based on https://stackoverflow.com/questions/14594782/how-can-i-make-an-uiimage-programmatically
extension UIImage {
    static func emptyImage(size: CGSize, color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.addRect(CGRect(origin: CGPoint(), size: size))
            context.drawPath(using: .fill)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
}

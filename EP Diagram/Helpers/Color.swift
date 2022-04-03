//
//  Color.swift
//  EP Diagram
//
//  Created by David Mann on 2/28/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit
import SwiftUI

extension Color {

    var toString: String {
        let uiColor = UIColor(self)
        return uiColor.toString
    }

    static func convertColorName(_ colorName: String) -> Color? {
        if !colorName.isEmpty {
            let rgbArray = colorName.components(separatedBy: ",")
            guard rgbArray.count >= 4 else { return nil }
            if let red = Double(rgbArray[0]), let green = Double(rgbArray[1]), let blue = Double(rgbArray[2]), let alpha = Double(rgbArray[3]) {
                return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
            }
        }
        return nil
    }


    static func colorToString(color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return ("\(red),\(green),\(blue),\(alpha)")
    }

    // TODO: redundant func also in PreferencesView
    static func getColorPicker(title: LocalizedStringKey, selection: Binding<Color>) -> some View {
    #if targetEnvironment(macCatalyst)
        return HStack {
            Text(title)
            Spacer()
            ColorPicker("", selection: selection).frame(maxWidth: 100)
        }
    #else
        return ColorPicker(title, selection: selection)
    #endif
    }
}

extension UIColor {

    var toString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return ("\(red),\(green),\(blue),\(alpha)")
    }

    static func convertColorName(_ colorName: String) -> UIColor? {
        if !colorName.isEmpty {
            let rgbArray = colorName.components(separatedBy: ",")
            guard rgbArray.count >= 4 else { return nil }
            if let red = Double(rgbArray[0]), let green = Double(rgbArray[1]), let blue = Double(rgbArray[2]), let alpha = Double(rgbArray[3]) {
                let uiColor: UIColor = UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
                return uiColor
            }
        }
        return nil
    }
}



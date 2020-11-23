//
//  UIView+PinToInside.swift
//  EP Diagram
//
//  Created by David Mann on 11/22/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

extension UIView {
  func pinToInside(view child: UIView) {
    child.translatesAutoresizingMaskIntoConstraints = false
    addSubview(child)
    NSLayoutConstraint.activate([
      child.leadingAnchor.constraint(equalTo: leadingAnchor),
      child.trailingAnchor.constraint(equalTo: trailingAnchor),
      child.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
      child.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
      ])
  }
}

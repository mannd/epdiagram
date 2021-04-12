//
//  HamburgerCell.swift
//  EP Diagram
//
//  Created by David Mann on 4/15/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

/// Cell used in "hamburger" table view (side menu), containing an SF icon and a text label
final class HamburgerCell: UITableViewCell {
    @IBOutlet var label: UILabel!
    @IBOutlet var icon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        icon.tintColor = UIColor.systemBlue // colors the icon
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

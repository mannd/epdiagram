//
//  HamburgerTableViewController.swift
//  EP Diagram
//
//  Created by David Mann on 4/15/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

class HamburgerTableViewController: UITableViewController {
    var rows: Array<HamburgerLayer> = []
    var delegate: HamburgerTableDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem

        let hamburgerViewModel = HamburgerViewModel()
        rows = hamburgerViewModel.allLayers()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HamburgerCell", for: indexPath) as! HamburgerCell

        let row = rows[indexPath.row]

        cell.label?.text = row.name
        cell.label?.adjustsFontSizeToFitWidth = true
        cell.icon?.image = UIImage(named: row.iconName!)
        return cell
    }

    // Default header is a little too big when using a grouped tableview.
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected row")
        delegate?.hideHamburgerMenu()
        let row = rows[indexPath.row]
        switch row.layer {
        case .camera:
            delegate?.takePhoto()
        case .photoGallery:
            delegate?.selectPhoto()
        case .open:
            delegate?.openDiagram()
        case .save:
            delegate?.saveDiagram()
        case .help:
            delegate?.help()
        case .about:
            delegate?.about()
        default:
            break
        }
    }
}

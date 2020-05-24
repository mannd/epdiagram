//
//  HamburgerTableViewController.swift
//  EP Diagram
//
//  Created by David Mann on 4/15/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

class HamburgerTableViewController: UITableViewController {
    var rows = [HamburgerLayer]()
    var delegate: HamburgerTableDelegate?
    var imageIsLocked: Bool = false

    override func viewDidLoad() {
        os_log("viewDidLoad() - HamburgerView", log: OSLog.viewCycle, type: .info)
        super.viewDidLoad()

        let hamburgerViewModel = HamburgerViewModel()
        rows = hamburgerViewModel.allLayers()
    }

    override func viewWillAppear(_ animated: Bool) {
        os_log("viewWillAppear() - HamburgerView", log: OSLog.viewCycle, type: .info)
        super.viewWillAppear(animated)
        imageIsLocked = delegate?.imageIsLocked ?? false
    }

    func reloadData() {
        imageIsLocked = delegate?.imageIsLocked ?? false
        self.tableView.reloadData()
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

        if row.layer == .lock && imageIsLocked {
            cell.label?.text = row.altName
            cell.icon?.image = UIImage(named: row.altIconName!)
        }
        else {
            cell.label?.text = row.name
            cell.icon?.image = UIImage(named: row.iconName!)
        }
        cell.label?.adjustsFontSizeToFitWidth = true
        return cell
    }

    // Default header is a little too big when using a grouped tableview.
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.hideHamburgerMenu()
        let row = rows[indexPath.row]
        switch row.layer {
        case .camera:
            delegate?.takePhoto()
        case .photoGallery:
            delegate?.selectPhoto()
        case .lock:
            delegate?.lockImage()
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

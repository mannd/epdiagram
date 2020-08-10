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
    var hamburgerViewModel: HamburgerViewModel = HamburgerViewModel()
    var rows = [HamburgerLayer]()
    var delegate: HamburgerTableDelegate?
    var imageIsLocked: Bool = false
    var diagramIsLocked: Bool = false

    override func viewDidLoad() {
        os_log("viewDidLoad() - HamburgerView", log: OSLog.viewCycle, type: .info)
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        os_log("viewWillAppear() - HamburgerView", log: OSLog.viewCycle, type: .info)
        super.viewWillAppear(animated)
        loadData()
    }

    func reloadData() {
        loadData()
        self.tableView.reloadData()
    }

    private func loadData() {
        imageIsLocked = delegate?.imageIsLocked ?? false
        diagramIsLocked = delegate?.diagramIsLocked ?? false
        hamburgerViewModel.diagramSaved = delegate?.diagramSaved ?? false
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

        if (row.layer == .lockImage && imageIsLocked) || (row.layer == .lockLadder && diagramIsLocked) {
            cell.label?.text = row.altName
            cell.icon?.image = UIImage(named: row.altIconName!)
        }
        else {
            cell.label?.text = row.name
            cell.label?.isEnabled = row.isEnabled
            cell.icon?.alpha = row.isEnabled ? 1.0 : 0.4
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
        case .takePhoto:
            delegate?.takePhoto()
        case .selectImage:
            delegate?.selectImage()
        case .selectLadder:
            delegate?.selectLadder()
        case .lockImage:
            delegate?.lockImage()
        case .newDiagram:
            delegate?.newDiagram()
        case .openDiagram:
            delegate?.selectDiagram()
        case .saveDiagram:
            delegate?.saveDiagram()
        case .renameDiagram:
            if !row.isEnabled{
                delegate?.showNeedToSaveMessage()
                return
            } else {
                delegate?.renameDiagram()
            }
        case .duplicateDiagram:
            if !row.isEnabled{
                delegate?.showNeedToSaveMessage()
                return
            } else {
                delegate?.duplicateDiagram()
            }
        case .getInfo:
            delegate?.getDiagramInfo()
        case .lockLadder:
            delegate?.lockLadder()
        case .sample:
            delegate?.sampleDiagrams()
        case .snapshot:
            delegate?.snapshotDiagram()
        case .preferences:
            delegate?.showPreferences()
        case .templates:
            delegate?.editTemplates()
        case .help:
            delegate?.help()
        case .about:
            delegate?.about()
        case .test:
            delegate?.test()
        case .none:
            break
        }
    }
}

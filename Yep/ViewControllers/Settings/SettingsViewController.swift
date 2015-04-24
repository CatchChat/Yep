//
//  SettingsViewController.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var settingsTableView: UITableView!

    let settingsUserCellIdentifier = "SettingsUserCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Settings", comment: "")

        settingsTableView.registerNib(UINib(nibName: settingsUserCellIdentifier, bundle: nil), forCellReuseIdentifier: settingsUserCellIdentifier)
    }

}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {

    enum Section: Int {
        case User = 0
        case More
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.User.rawValue:
            return 1
        case Section.More.rawValue:
            return 0
        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.User.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(settingsUserCellIdentifier) as! SettingsUserCell
            return cell
        case Section.More.rawValue:
            return UITableViewCell()
        default:
            return UITableViewCell()
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case Section.User.rawValue:
            return 120
        case Section.More.rawValue:
            return 0
        default:
            return 0
        }
    }
}
//
//  NotificationsViewController.swift
//  Yep
//
//  Created by NIX on 15/8/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class NotificationsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!


    struct DoNotDisturbPeriod {
        var isOn: Bool = false
        var start: String = "22:00"
        var end: String = "07:00"
    }

    var doNotDisturbPeriod = DoNotDisturbPeriod()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Notifications", comment: "")

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return doNotDisturbPeriod.isOn ? 2 : 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! UITableViewCell
        cell.textLabel?.text = NSLocalizedString("Do Not Disturb", comment: "")

        return cell
    }
}


//
//  BlackListViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class BlackListViewController: UIViewController {

    @IBOutlet weak var blockedUsersTableView: UITableView!

    let cellIdentifier = "ContactsCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Blocked Users", comment: "")

        blockedUsersTableView.separatorColor = UIColor.yepCellSeparatorColor()
        blockedUsersTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        blockedUsersTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        blockedUsersTableView.rowHeight = 80
        blockedUsersTableView.tableFooterView = UIView()
    }
}

extension BlackListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 15
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell
        return cell
    }
}


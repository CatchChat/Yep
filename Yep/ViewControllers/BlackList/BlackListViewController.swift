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

    var blockedUsers = [DiscoveredUser]() {
        didSet {
            blockedUsersTableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Blocked Users", comment: "")

        blockedUsersTableView.separatorColor = UIColor.yepCellSeparatorColor()
        blockedUsersTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        blockedUsersTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        blockedUsersTableView.rowHeight = 80
        blockedUsersTableView.tableFooterView = UIView()


        blockedUsersByMe(failureHandler: nil, completion: { blockedUsers in
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.blockedUsers = blockedUsers
            }
        })
    }
}

extension BlackListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUsers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell

        let discoveredUser = blockedUsers[indexPath.row]

        cell.configureWithDiscoveredUser(discoveredUser, tableView: tableView, indexPath: indexPath)

        return cell
    }
}


//
//  CreatorsOfBlockedFeedsViewController.swift
//  Yep
//
//  Created by NIX on 16/4/13.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

class CreatorsOfBlockedFeedsViewController: UIViewController {

    @IBOutlet private weak var creatorsOfBlockedFeedsTableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private let cellIdentifier = "ContactsCell"

    private var creatorsOfBlockedFeeds = [DiscoveredUser]() {
        willSet {
            if newValue.count == 0 {
                creatorsOfBlockedFeedsTableView.tableFooterView = InfoView(NSLocalizedString("No blocked creators.", comment: ""))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Blocked Creators", comment: "")

        creatorsOfBlockedFeedsTableView.separatorColor = UIColor.yepCellSeparatorColor()
        creatorsOfBlockedFeedsTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        creatorsOfBlockedFeedsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        creatorsOfBlockedFeedsTableView.rowHeight = 80
        creatorsOfBlockedFeedsTableView.tableFooterView = UIView()

        activityIndicator.startAnimating()
    }
}

extension CreatorsOfBlockedFeedsViewController: UITableViewDataSource, UITabBarDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return creatorsOfBlockedFeeds.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell

        cell.selectionStyle = .None

        let discoveredUser = creatorsOfBlockedFeeds[indexPath.row]

        cell.configureWithDiscoveredUser(discoveredUser)

        return cell
    }

    // Edit (for Unblock)

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if editingStyle == .Delete {

            let discoveredUser = creatorsOfBlockedFeeds[indexPath.row]

            // TODO
        }
    }
    
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return NSLocalizedString("Unblock", comment: "")
    }
}


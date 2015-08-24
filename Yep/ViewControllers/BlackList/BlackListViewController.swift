//
//  BlackListViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

class BlackListViewController: UIViewController {

    @IBOutlet weak var blockedUsersTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    let cellIdentifier = "ContactsCell"

    var blockedUsers = [DiscoveredUser]() {
        willSet {
            if newValue.count == 0 {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: blockedUsersTableView.bounds.width, height: 240))

                label.textAlignment = .Center
                label.text = NSLocalizedString("No blocked users.", comment: "")
                label.textColor = UIColor.lightGrayColor()

                blockedUsersTableView.tableFooterView = label
            }
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


        activityIndicator.startAnimating()

        blockedUsersByMe(failureHandler: { [weak self] reason, errorMessage in
            dispatch_async(dispatch_get_main_queue()) {
                self?.activityIndicator.stopAnimating()
            }

            YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("Netword Error: Faild to get blocked users!", comment: ""), inViewController: self)

        }, completion: { blockedUsers in
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.activityIndicator.stopAnimating()

                self?.blockedUsers = blockedUsers
                self?.blockedUsersTableView.reloadData()
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

    // Edit (for Unblock)

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if editingStyle == .Delete {

            let discoveredUser = blockedUsers[indexPath.row]

            unblockUserWithUserID(discoveredUser.id, failureHandler: nil, completion: { success in
                println("unblockUserWithUserID \(success)")

                dispatch_async(dispatch_get_main_queue()) { [weak self] in

                    let realm = Realm()

                    if let user = userWithUserID(discoveredUser.id, inRealm: realm) {
                        realm.write {
                            user.blocked = false
                        }
                    }

                    if let strongSelf = self {
                        if let index = find(strongSelf.blockedUsers, discoveredUser)  {

                            strongSelf.blockedUsers.removeAtIndex(index)

                            let indexPathToDelete = NSIndexPath(forRow: index, inSection: 0)
                            strongSelf.blockedUsersTableView.deleteRowsAtIndexPaths([indexPathToDelete], withRowAnimation: .Automatic)
                        }
                    }
                }
            })
        }
    }

    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String! {
        return NSLocalizedString("Unblock", comment: "")
    }
}


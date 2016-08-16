//
//  BlackListViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift

final class BlackListViewController: BaseViewController {

    @IBOutlet private weak var blockedUsersTableView: UITableView! {
        didSet {
            blockedUsersTableView.separatorColor = UIColor.yepCellSeparatorColor()
            blockedUsersTableView.separatorInset = YepConfig.ContactsCell.separatorInset

            blockedUsersTableView.rowHeight = 80
            blockedUsersTableView.tableFooterView = UIView()

            blockedUsersTableView.registerNibOf(ContactsCell)
        }
    }
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private let cellIdentifier = "ContactsCell"

    private var blockedUsers: [DiscoveredUser] = [] {
        willSet {
            if newValue.count == 0 {
                blockedUsersTableView.tableFooterView = InfoView(NSLocalizedString("No blocked users.", comment: ""))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleBlockedUsers

        activityIndicator.startAnimating()

        blockedUsersByMe(failureHandler: { [weak self] reason, errorMessage in
            SafeDispatch.async {
                self?.activityIndicator.stopAnimating()
            }

            YepAlert.alertSorry(message: NSLocalizedString("Network Error: Failed to get blocked users!", comment: ""), inViewController: self)

        }, completion: { blockedUsers in
            SafeDispatch.async { [weak self] in
                self?.activityIndicator.stopAnimating()

                self?.blockedUsers = blockedUsers
                self?.blockedUsersTableView.reloadData()
            }
        })
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showProfile":
            let vc = segue.destinationViewController as! ProfileViewController

            let discoveredUser = (sender as! Box<DiscoveredUser>).value
            vc.prepare(withDiscoveredUser: discoveredUser)

        default:
            break
        }
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

        let cell: ContactsCell = tableView.dequeueReusableCell()

        cell.selectionStyle = .None

        let discoveredUser = blockedUsers[indexPath.row]

        cell.configureWithDiscoveredUser(discoveredUser)

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        let discoveredUser = blockedUsers[indexPath.row]
        performSegueWithIdentifier("showProfile", sender: Box<DiscoveredUser>(discoveredUser))
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

                SafeDispatch.async { [weak self] in

                    guard let realm = try? Realm() else {
                        return
                    }

                    if let user = userWithUserID(discoveredUser.id, inRealm: realm) {
                        let _ = try? realm.write {
                            user.blocked = false
                        }
                    }

                    if let strongSelf = self {
                        if let index = strongSelf.blockedUsers.indexOf(discoveredUser)  {

                            strongSelf.blockedUsers.removeAtIndex(index)

                            let indexPathToDelete = NSIndexPath(forRow: index, inSection: 0)
                            strongSelf.blockedUsersTableView.deleteRowsAtIndexPaths([indexPathToDelete], withRowAnimation: .Automatic)
                        }
                    }
                }
            })
        }
    }

    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return NSLocalizedString("Unblock", comment: "")
    }
}


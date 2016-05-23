//
//  FriendsInContactsViewController.swift
//  Yep
//
//  Created by NIX on 15/6/1.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepConfig
import YepNetworking

final class FriendsInContactsViewController: BaseViewController {

    struct Notification {
        static let NewFriends = "NewFriendsInContactsNotification"
    }

    private let cellIdentifier = "ContactsCell"

    @IBOutlet private weak var friendsTableView: UITableView! {
        didSet {
            friendsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            friendsTableView.separatorInset = YepConfig.ContactsCell.separatorInset

            friendsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
            friendsTableView.rowHeight = 80
            friendsTableView.tableFooterView = UIView()
        }
    }

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private var discoveredUsers = [DiscoveredUser]() {
        didSet {
            if discoveredUsers.count > 0 {
                updateFriendsTableView()

                NSNotificationCenter.defaultCenter().postNotificationName(Notification.NewFriends, object: nil)

            } else {
                friendsTableView.tableFooterView = InfoView(NSLocalizedString("No more new friends.", comment: ""))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Available Friends", comment: "")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        uploadContactsToMatchNewFriends()
    }

    // MARK: Upload Contacts

    func uploadContactsToMatchNewFriends() {

        let uploadContacts = UploadContactsMaker.make()

        //println("uploadContacts: \(uploadContacts)")
        println("uploadContacts.count: \(uploadContacts.count)")

        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.activityIndicator.startAnimating()
        }

        friendsInContacts(uploadContacts, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.activityIndicator.stopAnimating()
            }

        }, completion: { discoveredUsers in
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.discoveredUsers = discoveredUsers

                self?.activityIndicator.stopAnimating()
            }
        })
    }

    // MARK: Actions

    private func updateFriendsTableView() {
        friendsTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showProfile" {
            if let indexPath = sender as? NSIndexPath {
                let discoveredUser = discoveredUsers[indexPath.row]

                let vc = segue.destinationViewController as! ProfileViewController

                if discoveredUser.id != YepUserDefaults.userID.value {
                    vc.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
                }

                vc.setBackButtonWithTitle()

                vc.hidesBottomBarWhenPushed = true
            }
        }
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate

extension FriendsInContactsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredUsers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell

        let discoveredUser = discoveredUsers[indexPath.row]

        cell.configureWithDiscoveredUser(discoveredUser)

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        performSegueWithIdentifier("showProfile", sender: indexPath)
    }
}


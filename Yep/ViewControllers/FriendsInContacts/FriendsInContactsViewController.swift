//
//  FriendsInContactsViewController.swift
//  Yep
//
//  Created by NIX on 15/6/1.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking

final class FriendsInContactsViewController: BaseViewController {

    @IBOutlet private weak var friendsTableView: UITableView! {
        didSet {
            friendsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            friendsTableView.separatorInset = YepConfig.ContactsCell.separatorInset

            friendsTableView.registerNibOf(ContactsCell)
            friendsTableView.rowHeight = 80
            friendsTableView.tableFooterView = UIView()
        }
    }

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private var discoveredUsers = [DiscoveredUser]() {
        didSet {
            if discoveredUsers.count > 0 {
                updateFriendsTableView()

                NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.newFriendsInContacts, object: nil)

            } else {
                friendsTableView.tableFooterView = InfoView(String.trans_promptNoNewFriends)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleAvailableFriends
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

        SafeDispatch.async { [weak self] in
            self?.activityIndicator.startAnimating()
        }

        friendsInContacts(uploadContacts, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            SafeDispatch.async { [weak self] in
                self?.activityIndicator.stopAnimating()
            }

        }, completion: { discoveredUsers in
            SafeDispatch.async { [weak self] in
                self?.discoveredUsers = discoveredUsers

                self?.activityIndicator.stopAnimating()
            }
        })
    }

    // MARK: Actions

    private func updateFriendsTableView() {

        friendsTableView.reloadData()
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showProfile" {
            guard let indexPath = sender as? NSIndexPath else {
                println("showProfile no indexPath!")
                return
            }

            let vc = segue.destinationViewController as! ProfileViewController

            let discoveredUser = discoveredUsers[indexPath.row]
            vc.prepare(with: discoveredUser)
        }
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate

extension FriendsInContactsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredUsers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell: ContactsCell = tableView.dequeueReusableCell()

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


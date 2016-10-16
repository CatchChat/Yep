//
//  FriendsInContactsViewController.swift
//  Yep
//
//  Created by NIX on 15/6/1.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class FriendsInContactsViewController: BaseViewController {

    @IBOutlet fileprivate weak var friendsTableView: UITableView! {
        didSet {
            friendsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            friendsTableView.separatorInset = YepConfig.ContactsCell.separatorInset

            friendsTableView.registerNibOf(ContactsCell.self)
            friendsTableView.rowHeight = 80
            friendsTableView.tableFooterView = UIView()
        }
    }

    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

    fileprivate var discoveredUsers = [DiscoveredUser]() {
        didSet {
            if discoveredUsers.count > 0 {
                updateFriendsTableView()

                NotificationCenter.default.post(name: YepConfig.NotificationName.newFriendsInContacts, object: nil)

            } else {
                friendsTableView.tableFooterView = InfoView(String.trans_promptNoNewFriends)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleAvailableFriends
    }

    override func viewWillAppear(_ animated: Bool) {
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

    fileprivate func updateFriendsTableView() {

        friendsTableView.reloadData()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "showProfile" {
            guard let indexPath = sender as? IndexPath else {
                println("showProfile no indexPath!")
                return
            }

            let vc = segue.destination as! ProfileViewController

            let discoveredUser = discoveredUsers[indexPath.row]
            vc.prepare(with: discoveredUser)
        }
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate

extension FriendsInContactsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: ContactsCell = tableView.dequeueReusableCell()

        let discoveredUser = discoveredUsers[indexPath.row]

        cell.configureWithDiscoveredUser(discoveredUser)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        performSegue(withIdentifier: "showProfile", sender: indexPath)
    }
}


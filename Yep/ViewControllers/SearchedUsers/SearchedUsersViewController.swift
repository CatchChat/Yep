//
//  SearchedUsersViewController.swift
//  Yep
//
//  Created by NIX on 15/5/22.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepNetworking
import YepKit

final class SearchedUsersViewController: BaseViewController {

    var searchText = "NIX"

    @IBOutlet private weak var searchedUsersTableView: UITableView! {
        didSet {
            searchedUsersTableView.registerNibOf(ContactsCell)

            searchedUsersTableView.rowHeight = 80

            searchedUsersTableView.separatorColor = UIColor.yepCellSeparatorColor()
            searchedUsersTableView.separatorInset = YepConfig.ContactsCell.separatorInset
        }
    }

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private var searchedUsers = [DiscoveredUser]() {
        didSet {
            if searchedUsers.count > 0 {
                updateSearchedUsersTableView()

            } else {
                searchedUsersTableView.tableFooterView = InfoView(NSLocalizedString("No search results.", comment: ""))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Search", comment: "") + " \"\(searchText)\""

        activityIndicator.startAnimating()

        searchUsersByQ(searchText, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            SafeDispatch.async {
                self?.activityIndicator.stopAnimating()
            }

        }, completion: { [weak self] users in
            SafeDispatch.async {
                self?.activityIndicator.stopAnimating()
                self?.searchedUsers = users
            }
        })
    }

    // MARK: Actions

    private func updateSearchedUsersTableView() {
        SafeDispatch.async {
            self.searchedUsersTableView.reloadData()
        }
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showProfile" {
            if let indexPath = sender as? NSIndexPath {

                let vc = segue.destinationViewController as! ProfileViewController

                let discoveredUser = searchedUsers[indexPath.row]
                vc.prepare(withDiscoveredUser: discoveredUser)
            }
        }
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate

extension SearchedUsersViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedUsers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell: ContactsCell = tableView.dequeueReusableCell()

        let discoveredUser = searchedUsers[indexPath.row]

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


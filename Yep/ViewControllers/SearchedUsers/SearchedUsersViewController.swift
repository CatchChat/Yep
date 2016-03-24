//
//  SearchedUsersViewController.swift
//  Yep
//
//  Created by NIX on 15/5/22.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SearchedUsersViewController: BaseViewController {

    var searchText = "NIX"

    @IBOutlet private weak var searchedUsersTableView: UITableView!
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

    private let cellIdentifier = "ContactsCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Search", comment: "") + " \"\(searchText)\""

        searchedUsersTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        searchedUsersTableView.rowHeight = 80

        searchedUsersTableView.separatorColor = UIColor.yepCellSeparatorColor()
        searchedUsersTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        activityIndicator.startAnimating()

        searchUsersByQ(searchText, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            dispatch_async(dispatch_get_main_queue()) {
                self?.activityIndicator.stopAnimating()
            }

        }, completion: { [weak self] users in
            dispatch_async(dispatch_get_main_queue()) {
                self?.activityIndicator.stopAnimating()
                self?.searchedUsers = users
            }
        })
    }

    // MARK: Actions

    private func updateSearchedUsersTableView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.searchedUsersTableView.reloadData()
        }
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showProfile" {
            if let indexPath = sender as? NSIndexPath {
                let discoveredUser = searchedUsers[indexPath.row]

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

extension SearchedUsersViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedUsers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell

        let discoveredUser = searchedUsers[indexPath.row]

        cell.configureWithDiscoveredUser(discoveredUser, tableView: tableView, indexPath: indexPath)

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        performSegueWithIdentifier("showProfile", sender: indexPath)
    }
}


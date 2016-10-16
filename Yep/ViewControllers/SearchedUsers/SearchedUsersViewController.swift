//
//  SearchedUsersViewController.swift
//  Yep
//
//  Created by NIX on 15/5/22.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class SearchedUsersViewController: BaseViewController {

    var searchText = "NIX"

    @IBOutlet fileprivate weak var searchedUsersTableView: UITableView! {
        didSet {
            searchedUsersTableView.registerNibOf(ContactsCell.self)

            searchedUsersTableView.rowHeight = 80

            searchedUsersTableView.separatorColor = UIColor.yepCellSeparatorColor()
            searchedUsersTableView.separatorInset = YepConfig.ContactsCell.separatorInset
        }
    }

    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

    fileprivate var searchedUsers = [DiscoveredUser]() {
        didSet {
            if searchedUsers.count > 0 {
                updateSearchedUsersTableView()

            } else {
                searchedUsersTableView.tableFooterView = InfoView(String.trans_promptNoSearchResults)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Search", comment: "") + " \"\(searchText)\""

        activityIndicator.startAnimating()

        searchUsersByQ(searchText, failureHandler: { [weak self] reason, errorMessage in
            SafeDispatch.async {
                self?.activityIndicator.stopAnimating()
            }

        }, completion: { users in
            SafeDispatch.async { [weak self] in
                self?.activityIndicator.stopAnimating()
                self?.searchedUsers = users
            }
        })
    }

    // MARK: Actions

    fileprivate func updateSearchedUsersTableView() {

        SafeDispatch.async { [weak self] in
            self?.searchedUsersTableView.reloadData()
        }
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "showProfile" {
            guard let indexPath = sender as? IndexPath else {
                println("Error: showProfile no indexPath!")
                return
            }

            let vc = segue.destination as! ProfileViewController

            let discoveredUser = searchedUsers[indexPath.row]
            vc.prepare(with: discoveredUser)
        }
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate

extension SearchedUsersViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: ContactsCell = tableView.dequeueReusableCell()

        let discoveredUser = searchedUsers[indexPath.row]

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


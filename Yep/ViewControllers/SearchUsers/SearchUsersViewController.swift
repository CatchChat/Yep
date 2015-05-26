//
//  SearchUsersViewController.swift
//  Yep
//
//  Created by NIX on 15/4/9.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SearchUsersViewController: BaseViewController {

    @IBOutlet weak var searchedUsersTableView: UITableView!

    lazy var searchController: UISearchController = {
        var searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.sizeToFit()
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false

        searchController.searchBar.searchBarStyle = .Minimal
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = NSLocalizedString("Search by mobile", comment: "")
        searchController.searchBar.keyboardType = .NumberPad

        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let searchButton = UIBarButtonItem(title: NSLocalizedString("Search", comment: ""), style: .Plain, target: self, action: "doSearch")
        toolBar.items = [searchButton]
        searchController.searchBar.inputAccessoryView = toolBar

        return searchController
        }()
    
    var searchedUsers = [JSONDictionary]() {
        willSet {
            dispatch_async(dispatch_get_main_queue()) {
                self.searchedUsersTableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Add Friends", comment: "")

        searchedUsersTableView.tableHeaderView = searchController.searchBar

        searchedUsersTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    var isFirstAppear = false
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstAppear {
            isFirstAppear = false

            searchController.active = true
            searchController.searchBar.becomeFirstResponder()
        }
    }

    // MARK: Actions

    func doSearch() {
        let mobile = searchController.searchBar.text

        searchMobile(mobile)

        searchController.active = false
        //searchController.searchBar.resignFirstResponder()
    }

    private func searchMobile(mobile: String) {
        searchUsersByMobile(mobile, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

        }, completion: { users in
            self.searchedUsers = users
        })
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate

extension SearchUsersViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedUsers.count
    }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! UITableViewCell

        let userInfo = searchedUsers[indexPath.row]

        cell.textLabel?.text = userInfo["nickname"] as? String

        return cell
    }
}

// MARK: UISearchControllerDelegate

extension SearchUsersViewController: UISearchControllerDelegate {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
    }
}

// MARK: UISearchBarDelegate

extension SearchUsersViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {

    }
}

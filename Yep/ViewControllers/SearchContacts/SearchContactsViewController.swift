//
//  SearchContactsViewController.swift
//  Yep
//
//  Created by NIX on 16/3/21.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift
import KeypathObserver

final class SearchContactsViewController: BaseSearchViewController {

    @IBOutlet weak var contactsTableView: UITableView! {
        didSet {
            //contactsTableView.separatorColor = YepConfig.SearchTableView.separatorColor // not work here
            contactsTableView.backgroundColor = YepConfig.SearchTableView.backgroundColor

            contactsTableView.registerHeaderFooterClassOf(TableSectionTitleView)
            contactsTableView.registerNibOf(SearchSectionTitleCell)
            contactsTableView.registerNibOf(SearchedUserCell)
            contactsTableView.registerNibOf(SearchedDiscoveredUserCell)

            contactsTableView.sectionHeaderHeight = 0
            contactsTableView.sectionFooterHeight = 0
            contactsTableView.contentInset = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)

            contactsTableView.tableFooterView = UIView()

            contactsTableView.keyboardDismissMode = .OnDrag
        }
    }

    private var searchTask: CancelableTask?

    private lazy var friends = normalFriends()
    private var filteredFriends: Results<User>?

    private var searchedUsers = [DiscoveredUser]()

    private var countOfFilteredFriends: Int {
        return filteredFriends?.count ?? 0
    }
    private var countOfSearchedUsers: Int {
        return searchedUsers.count
    }

    private var keyword: String? {
        didSet {
            if keyword == nil {
                clearSearchResults()
            }
            if let keyword = keyword where keyword.isEmpty {
                clearSearchResults()
            }
        }
    }

    deinit {
        println("deinit SearchContacts")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Search", comment: "")

        searchBar.placeholder = NSLocalizedString("Search Friend", comment: "")

        contactsTableView.separatorColor = YepConfig.SearchTableView.separatorColor

        searchBarBottomLineView.alpha = 0
    }

    // MARK: Private

    private func updateContactsTableView(scrollsToTop scrollsToTop: Bool = false) {
        SafeDispatch.async { [weak self] in
            self?.contactsTableView.reloadData()

            if scrollsToTop {
                self?.contactsTableView.yep_scrollsToTop()
            }
        }
    }

    private func hideKeyboard() {

        searchBar.resignFirstResponder()
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showProfile":
            let vc = segue.destinationViewController as! ProfileViewController

            if let user = sender as? User {
                vc.prepare(withUser: user)

            } else if let discoveredUser = (sender as? Box<DiscoveredUser>)?.value {
                vc.prepare(with: discoveredUser)
            }

            prepareOriginalNavigationControllerDelegate()

        default:
            break
        }
    }
}

// MARK: - UISearchBarDelegate

extension SearchContactsViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {

        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] _ in
            self?.searchBarBottomLineView.alpha = 1
        }, completion: nil)

        return true
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {

        searchBar.text = nil
        searchBar.resignFirstResponder()

        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] _ in
            self?.searchBarBottomLineView.alpha = 0
        }, completion: nil)

        navigationController?.popViewControllerAnimated(true)
    }

    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {

        cancel(searchTask)

        searchTask = delay(YepConfig.Search.delayInterval) { [weak self] in
            if let searchText = searchBar.yep_fullSearchText {
                self?.updateSearchResultsWithText(searchText)
            }
        }
        
        return true
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {

        cancel(searchTask)

        if searchText.isEmpty {
            self.keyword = nil
            return
        }

        searchTask = delay(YepConfig.Search.delayInterval) { [weak self] in
            self?.updateSearchResultsWithText(searchText)
        }
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {

        hideKeyboard()
    }

    private func clearSearchResults() {

        filteredFriends = nil
        searchedUsers = []

        updateContactsTableView(scrollsToTop: true)
    }

    private func updateSearchResultsWithText(searchText: String) {

        let searchText = searchText.trimming(.Whitespace)

        // 不要重复搜索一样的内容
        if let keyword = self.keyword where keyword == searchText {
            return
        }

        self.keyword = searchText

        guard !searchText.isEmpty else {
            return
        }

        let predicate = NSPredicate(format: "nickname CONTAINS[c] %@ OR username CONTAINS[c] %@", searchText, searchText)
        let filteredFriends = friends.filter(predicate)
        self.filteredFriends = filteredFriends

        updateContactsTableView(scrollsToTop: !filteredFriends.isEmpty)

        searchUsersByQ(searchText, failureHandler: nil, completion: { [weak self] users in

            //println("searchUsersByQ users: \(users)")

            SafeDispatch.async {

                guard let filteredFriends = self?.filteredFriends else {
                    return
                }

                // 剔除 filteredFriends 里已有的

                var searchedUsers = [DiscoveredUser]()

                let filteredFriendUserIDSet = Set<String>(filteredFriends.map({ $0.userID }))

                for user in users {
                    if !filteredFriendUserIDSet.contains(user.id) {
                        searchedUsers.append(user)
                    }
                }

                self?.searchedUsers = searchedUsers
                
                self?.updateContactsTableView()
            }
        })
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension SearchContactsViewController: UITableViewDataSource, UITableViewDelegate {

    enum Section: Int {
        case Local
        case Online
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    private func numberOfRowsInSection(section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            return 0
        }

        func numberOfRowsWithCountOfItems(countOfItems: Int) -> Int {
            let count = countOfItems
            if count > 0 {
                return 1 + count
            } else {
                return 0
            }
        }

        switch section {
        case .Local:
            return numberOfRowsWithCountOfItems(countOfFilteredFriends)
        case .Online:
            return numberOfRowsWithCountOfItems(countOfSearchedUsers)
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection(section)
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        guard numberOfRowsInSection(section) > 0 else {
            return nil
        }

        let header: TableSectionTitleView = tableView.dequeueReusableHeaderFooter()
        header.titleLabel.text = nil

        return header
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        guard numberOfRowsInSection(section) > 0 else {
            return 0
        }

        return 15
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        guard indexPath.row > 0 else {
            return 40
        }

        return 70
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        if indexPath.row == 0 {

            let cell: SearchSectionTitleCell = tableView.dequeueReusableCell()

            switch section {
            case .Local:
                cell.sectionTitleLabel.text = String.trans_titleFriends
            case .Online:
                cell.sectionTitleLabel.text = NSLocalizedString("Users", comment: "")
            }

            return cell
        }

        switch section {

        case .Local:
            let cell: SearchedUserCell = tableView.dequeueReusableCell()
            return cell

        case .Online:
            let cell: SearchedDiscoveredUserCell = tableView.dequeueReusableCell()
            return cell
        }
    }

    private func friendAtIndex(index: Int) -> User? {

        let friend = filteredFriends?[safe: index]
        return friend
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        guard indexPath.row > 0 else {
            return
        }



        guard let section = Section(rawValue: indexPath.section) else {
            return
        }

        let itemIndex = indexPath.row - 1

        switch section {

        case .Local:

            guard let friend = friendAtIndex(itemIndex) else {
                return
            }
            guard let cell = cell as? SearchedUserCell else {
                return
            }

            cell.configureWithUserRepresentation(friend, keyword: keyword)

        case .Online:

            let discoveredUser = searchedUsers[itemIndex]

            guard let cell = cell as? SearchedDiscoveredUserCell else {
                return
            }

            cell.configureWithUserRepresentation(discoveredUser, keyword: keyword)
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        guard indexPath.row > 0 else {
            return
        }

        hideKeyboard()

        guard let section = Section(rawValue: indexPath.section) else {
            return
        }

        let itemIndex = indexPath.row - 1

        switch section {

        case .Local:

            if let friend = friendAtIndex(itemIndex) {
                performSegueWithIdentifier("showProfile", sender: friend)
            }

        case .Online:

            let discoveredUser = searchedUsers[itemIndex]
            performSegueWithIdentifier("showProfile", sender: Box<DiscoveredUser>(discoveredUser))
        }
    }
}


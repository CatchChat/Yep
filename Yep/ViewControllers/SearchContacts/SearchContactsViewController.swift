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

            contactsTableView.registerHeaderFooterClassOf(TableSectionTitleView.self)
            contactsTableView.registerNibOf(SearchSectionTitleCell.self)
            contactsTableView.registerNibOf(SearchedUserCell.self)
            contactsTableView.registerNibOf(SearchedDiscoveredUserCell.self)

            contactsTableView.sectionHeaderHeight = 0
            contactsTableView.sectionFooterHeight = 0
            contactsTableView.contentInset = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)

            contactsTableView.tableFooterView = UIView()

            contactsTableView.keyboardDismissMode = .onDrag
        }
    }

    fileprivate var searchTask: CancelableTask?

    fileprivate lazy var friends = normalFriends()
    fileprivate var filteredFriends: Results<User>?

    fileprivate var searchedUsers = [DiscoveredUser]()

    fileprivate var countOfFilteredFriends: Int {
        return filteredFriends?.count ?? 0
    }
    fileprivate var countOfSearchedUsers: Int {
        return searchedUsers.count
    }

    fileprivate var keyword: String? {
        didSet {
            if keyword == nil {
                clearSearchResults()
            }
            if let keyword = keyword , keyword.isEmpty {
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

    fileprivate func updateContactsTableView(scrollsToTop: Bool = false) {
        SafeDispatch.async { [weak self] in
            self?.contactsTableView.reloadData()

            if scrollsToTop {
                self?.contactsTableView.yep_scrollsToTop()
            }
        }
    }

    fileprivate func hideKeyboard() {

        searchBar.resignFirstResponder()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showProfile":
            let vc = segue.destination as! ProfileViewController

            if let user = sender as? User {
                vc.prepare(withUser: user)

            } else if let discoveredUser = sender as? DiscoveredUser {
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

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {

        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] _ in
            self?.searchBarBottomLineView.alpha = 1
        }, completion: nil)

        return true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {

        searchBar.text = nil
        searchBar.resignFirstResponder()

        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] _ in
            self?.searchBarBottomLineView.alpha = 0
        }, completion: nil)

        _ = navigationController?.popViewController(animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        cancel(searchTask)

        searchTask = delay(YepConfig.Search.delayInterval) { [weak self] in
            if let searchText = searchBar.yep_fullSearchText {
                self?.updateSearchResultsWithText(searchText)
            }
        }
        
        return true
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        cancel(searchTask)

        if searchText.isEmpty {
            self.keyword = nil
            return
        }

        searchTask = delay(YepConfig.Search.delayInterval) { [weak self] in
            self?.updateSearchResultsWithText(searchText)
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        hideKeyboard()
    }

    fileprivate func clearSearchResults() {

        filteredFriends = nil
        searchedUsers = []

        updateContactsTableView(scrollsToTop: true)
    }

    fileprivate func updateSearchResultsWithText(_ searchText: String) {

        let searchText = searchText.trimming(.whitespace)

        // 不要重复搜索一样的内容
        if let keyword = self.keyword , keyword == searchText {
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
        case local
        case online
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    fileprivate func numberOfRowsInSection(_ section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            return 0
        }

        func numberOfRowsWithCountOfItems(_ countOfItems: Int) -> Int {
            let count = countOfItems
            if count > 0 {
                return 1 + count
            } else {
                return 0
            }
        }

        switch section {
        case .local:
            return numberOfRowsWithCountOfItems(countOfFilteredFriends)
        case .online:
            return numberOfRowsWithCountOfItems(countOfSearchedUsers)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection(section)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        guard numberOfRowsInSection(section) > 0 else {
            return nil
        }

        let header: TableSectionTitleView = tableView.dequeueReusableHeaderFooter()
        header.titleLabel.text = nil

        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        guard numberOfRowsInSection(section) > 0 else {
            return 0
        }

        return 15
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        guard indexPath.row > 0 else {
            return 40
        }

        return 70
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        if indexPath.row == 0 {

            let cell: SearchSectionTitleCell = tableView.dequeueReusableCell()

            switch section {
            case .local:
                cell.sectionTitleLabel.text = String.trans_titleFriends
            case .online:
                cell.sectionTitleLabel.text = NSLocalizedString("Users", comment: "")
            }

            return cell
        }

        switch section {

        case .local:
            let cell: SearchedUserCell = tableView.dequeueReusableCell()
            return cell

        case .online:
            let cell: SearchedDiscoveredUserCell = tableView.dequeueReusableCell()
            return cell
        }
    }

    fileprivate func friendAtIndex(_ index: Int) -> User? {

        let friend = filteredFriends?[safe: index]
        return friend
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        guard indexPath.row > 0 else {
            return
        }



        guard let section = Section(rawValue: indexPath.section) else {
            return
        }

        let itemIndex = indexPath.row - 1

        switch section {

        case .local:

            guard let friend = friendAtIndex(itemIndex) else {
                return
            }
            guard let cell = cell as? SearchedUserCell else {
                return
            }

            cell.configureWithUserRepresentation(friend, keyword: keyword)

        case .online:

            let discoveredUser = searchedUsers[itemIndex]

            guard let cell = cell as? SearchedDiscoveredUserCell else {
                return
            }

            cell.configureWithUserRepresentation(discoveredUser, keyword: keyword)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
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

        case .local:

            if let friend = friendAtIndex(itemIndex) {
                performSegue(withIdentifier: "showProfile", sender: friend)
            }

        case .online:

            let discoveredUser = searchedUsers[itemIndex]
            performSegue(withIdentifier: "showProfile", sender: discoveredUser)
        }
    }
}


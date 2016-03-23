//
//  SearchContactsViewController.swift
//  Yep
//
//  Created by NIX on 16/3/21.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import KeyboardMan

class SearchContactsViewController: SegueViewController {

    var originalNavigationControllerDelegate: UINavigationControllerDelegate?
    private var contactsSearchTransition: ContactsSearchTransition?

    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            searchBar.placeholder = NSLocalizedString("Search Friend", comment: "")
        }
    }
    @IBOutlet weak var searchBarTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var contactsTableView: UITableView! {
        didSet {
            contactsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            contactsTableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

            contactsTableView.registerClass(TableSectionTitleView.self, forHeaderFooterViewReuseIdentifier: headerIdentifier)
            contactsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
            contactsTableView.rowHeight = 80
            contactsTableView.tableFooterView = UIView()
        }
    }

    private let keyboardMan = KeyboardMan()

    private lazy var friends = normalFriends()
    private var filteredFriends: Results<User>?

    private var searchedUsers = [DiscoveredUser]()

    private var searchControllerIsActive = false

    private let headerIdentifier = "TableSectionTitleView"
    private let cellIdentifier = "ContactsCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        title = "Search Contacts"

        keyboardMan.animateWhenKeyboardAppear = { [weak self] _, keyboardHeight, _ in
            self?.contactsTableView.contentInset.bottom = keyboardHeight
            self?.contactsTableView.scrollIndicatorInsets.bottom = keyboardHeight
        }

        keyboardMan.animateWhenKeyboardDisappear = { [weak self] _ in
            self?.contactsTableView.contentInset.bottom = 0
            self?.contactsTableView.scrollIndicatorInsets.bottom = 0
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)

        //(tabBarController as? YepTabBarController)?.setTabBarHidden(true, animated: true)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let delegate = contactsSearchTransition {
            navigationController?.delegate = delegate
        }

        searchBar.becomeFirstResponder()
    }

    private func updateContactsTableView(scrollsToTop scrollsToTop: Bool = false) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.contactsTableView.reloadData()

            if scrollsToTop {
                self?.contactsTableView.yep_scrollsToTop()
            }
        }
    }

    private func hideKeyboard() {
        searchBar.resignFirstResponder()

        //(tabBarController as? YepTabBarController)?.setTabBarHidden(true, animated: true)
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
                if user.userID != YepUserDefaults.userID.value {
                    vc.profileUser = .UserType(user)
                }

            } else if let discoveredUser = (sender as? Box<DiscoveredUser>)?.value {
                vc.profileUser = .DiscoveredUserType(discoveredUser)
            }

            vc.hidesBottomBarWhenPushed = true
            
            vc.setBackButtonWithTitle()

            // 记录原始的 contactsSearchTransition 以便 pop 后恢复
            contactsSearchTransition = navigationController?.delegate as? ContactsSearchTransition

            navigationController?.delegate = originalNavigationControllerDelegate

        default:
            break
        }
    }
}

// MARK: - UISearchBarDelegate

extension SearchContactsViewController: UISearchBarDelegate {

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {

        searchBar.text = nil
        searchBar.resignFirstResponder()

        (tabBarController as? YepTabBarController)?.setTabBarHidden(false, animated: true)

        navigationController?.popViewControllerAnimated(true)
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {

        searchControllerIsActive = !searchText.isEmpty

        updateSearchResultsWithText(searchText)
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {

        hideKeyboard()
    }

    private func updateSearchResultsWithText(searchText: String) {

        let predicate = NSPredicate(format: "nickname CONTAINS[c] %@ OR username CONTAINS[c] %@", searchText, searchText)
        let filteredFriends = friends.filter(predicate)
        self.filteredFriends = filteredFriends

        updateContactsTableView(scrollsToTop: !filteredFriends.isEmpty)

        searchUsersByQ(searchText, failureHandler: nil, completion: { [weak self] users in

            //println("searchUsersByQ users: \(users)")

            dispatch_async(dispatch_get_main_queue()) {

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

        switch section {
        case .Local:
            return searchControllerIsActive ? (filteredFriends?.count ?? 0) : friends.count
        case .Online:
            return searchControllerIsActive ? searchedUsers.count : 0
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection(section)
    }

    /*
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        guard numberOfRowsInSection(section) > 0 else {
            return nil
        }

        if searchControllerIsActive {

            guard let section = Section(rawValue: section) else {
                return nil
            }

            switch section {
            case .Local:
                return NSLocalizedString("Friends", comment: "")
            case .Online:
                return NSLocalizedString("Users", comment: "")
            }

        } else {
            return nil
        }
    }
    */

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        guard numberOfRowsInSection(section) > 0 else {
            return nil
        }

        if searchControllerIsActive {

            guard let section = Section(rawValue: section) else {
                return nil
            }

            let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(headerIdentifier) as? TableSectionTitleView

            switch section {
            case .Local:
                header?.titleLabel.text = NSLocalizedString("Friends", comment: "")
            case .Online:
                header?.titleLabel.text = NSLocalizedString("Users", comment: "")
            }

            return header

        } else {
            return nil
        }
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        guard numberOfRowsInSection(section) > 0 else {
            return 0
        }

        if searchControllerIsActive {
            return 25
            
        } else {
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell
        return cell
    }

    private func friendAtIndexPath(indexPath: NSIndexPath) -> User? {
        let index = indexPath.row
        let friend = searchControllerIsActive ? filteredFriends?[safe: index] : friends[safe: index]
        return friend
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        guard let cell = cell as? ContactsCell else {
            return
        }

        guard let section = Section(rawValue: indexPath.section) else {
            return
        }


        switch section {

        case .Local:

            guard let friend = friendAtIndexPath(indexPath) else {
                return
            }

            if searchControllerIsActive {
                cell.configureForSearchWithUser(friend)
            } else {
                cell.configureWithUser(friend)
            }

        case .Online:

            let discoveredUser = searchedUsers[indexPath.row]
            cell.configureForSearchWithDiscoveredUser(discoveredUser)
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        hideKeyboard()

        guard let section = Section(rawValue: indexPath.section) else {
            return
        }

        switch section {

        case .Local:

            if let friend = friendAtIndexPath(indexPath) {
                performSegueWithIdentifier("showProfile", sender: friend)
            }

        case .Online:

            let discoveredUser = searchedUsers[indexPath.row]
            performSegueWithIdentifier("showProfile", sender: Box<DiscoveredUser>(discoveredUser))
        }
    }
}


//
//  ContactsViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import Ruler
import KeyboardMan

class ContactsViewController: BaseViewController {

    @IBOutlet weak var contactsTableView: UITableView!

    @IBOutlet private weak var coverUnderStatusBarView: UIView!

    #if DEBUG
    private lazy var contactsFPSLabel: FPSLabel = {
        let label = FPSLabel()
        return label
    }()
    #endif

    private var searchController: UISearchController?
    private var searchControllerIsActive: Bool {
        return searchController?.active ?? false
    }

    private let keyboardMan = KeyboardMan()
    private var normalContactsTableViewContentInsetBottom: CGFloat?

    private let cellIdentifier = "ContactsCell"

    private lazy var friends = normalFriends()
    private var filteredFriends: Results<User>?

    private var searchedUsers = [DiscoveredUser]()

    private var realmNotificationToken: NotificationToken?

    private lazy var noContactsFooterView: InfoView = InfoView(NSLocalizedString("No friends yet.\nTry discover or add some.", comment: ""))

    private var noContacts = false {
        didSet {
            if noContacts != oldValue {
                contactsTableView.tableFooterView = noContacts ? noContactsFooterView : UIView()
            }
        }
    }

    private struct Listener {
        static let Nickname = "ContactsViewController.Nickname"
        static let Avatar = "ContactsViewController.Avatar"
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)

        YepUserDefaults.avatarURLString.removeListenerWithName(Listener.Avatar)
        YepUserDefaults.nickname.removeListenerWithName(Listener.Nickname)

        contactsTableView?.delegate = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Contacts", comment: "")

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "syncFriendships:", name: FriendsInContactsViewController.Notification.NewFriends, object: nil)

        coverUnderStatusBarView.hidden = true

        // 超过一定人数才显示搜索框

        //if friends.count > Ruler.iPhoneVertical(6, 8, 10, 12).value {
        if friends.count > 0 {

            let searchController = UISearchController(searchResultsController: nil)
            searchController.delegate = self

            searchController.searchResultsUpdater = self
            searchController.dimsBackgroundDuringPresentation = false

            searchController.searchBar.backgroundColor = UIColor.whiteColor()
            searchController.searchBar.barTintColor = UIColor.whiteColor()
            searchController.searchBar.searchBarStyle = .Minimal
            searchController.searchBar.placeholder = NSLocalizedString("Search Friend", comment: "")
            searchController.searchBar.sizeToFit()

            searchController.searchBar.delegate = self

            contactsTableView.tableHeaderView = searchController.searchBar

            self.searchController = searchController

            // ref http://stackoverflow.com/questions/30937275/uisearchcontroller-doesnt-hide-view-when-pushed
            self.definesPresentationContext = true
        }

        contactsTableView.separatorColor = UIColor.yepCellSeparatorColor()
        contactsTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        contactsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        contactsTableView.rowHeight = 80
        contactsTableView.tableFooterView = UIView()

        noContacts = friends.isEmpty

        realmNotificationToken = friends.realm?.addNotificationBlock { [weak self] notification, realm in
            if let strongSelf = self {
                strongSelf.noContacts = strongSelf.friends.isEmpty
            }
            
            self?.updateContactsTableView()
        }

        YepUserDefaults.nickname.bindListener(Listener.Nickname) { [weak self] _ in
            dispatch_async(dispatch_get_main_queue()) {
                self?.updateContactsTableView()
            }
        }

        YepUserDefaults.avatarURLString.bindListener(Listener.Avatar) { [weak self] _ in
            dispatch_async(dispatch_get_main_queue()) {
                self?.updateContactsTableView()
            }
        }

        keyboardMan.animateWhenKeyboardAppear = { [weak self] _, keyboardHeight, _ in
            self?.normalContactsTableViewContentInsetBottom = self?.contactsTableView.contentInset.bottom
            self?.contactsTableView.contentInset.bottom = keyboardHeight
            self?.contactsTableView.scrollIndicatorInsets.bottom = keyboardHeight
        }

        keyboardMan.animateWhenKeyboardDisappear = { [weak self] _ in
            if let bottom = self?.normalContactsTableViewContentInsetBottom {
                self?.contactsTableView.contentInset.bottom = bottom
                self?.contactsTableView.scrollIndicatorInsets.bottom = bottom
            }
        }

        #if DEBUG
            //view.addSubview(contactsFPSLabel)
        #endif
    }

    // MARK: Actions

    private func updateContactsTableView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.contactsTableView.reloadData()
        }
    }

    @objc private func syncFriendships(sender: NSNotification) {
        syncFriendshipsAndDoFurtherAction {
            dispatch_async(dispatch_get_main_queue()) {
                self.updateContactsTableView()
            }
        }
    }

    @IBAction private func showAddFriends(sender: UIBarButtonItem) {
        performSegueWithIdentifier("showAddFriends", sender: nil)
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showProfile" {
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
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ContactsViewController: UITableViewDataSource, UITableViewDelegate {

    enum Section: Int {
        case Local
        case Online
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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

    private func friendAtIndexPath(indexPath: NSIndexPath) -> User? {
        let index = indexPath.row
        let friend = searchControllerIsActive ? filteredFriends?[safe: index] : friends[safe: index]
        return friend
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell
        return cell
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

            let userAvatar = UserAvatar(userID: friend.userID, avatarURLString: friend.avatarURLString, avatarStyle: miniAvatarStyle)
            cell.avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

            cell.nameLabel.text = friend.nickname

            if let badge = BadgeView.Badge(rawValue: friend.badge) {
                cell.badgeImageView.image = badge.image
                cell.badgeImageView.tintColor = badge.color
            } else {
                cell.badgeImageView.image = nil
            }

            cell.joinedDateLabel.text = friend.introduction
            cell.lastTimeSeenLabel.text = String(format:NSLocalizedString("Last seen %@", comment: ""), NSDate(timeIntervalSince1970: friend.lastSignInUnixTime).timeAgo.lowercaseString)

        case .Online:
            
            let discoveredUser = searchedUsers[indexPath.row]
            cell.configureWithDiscoveredUser(discoveredUser, tableView: tableView, indexPath: indexPath)
        }
    }

    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        guard let cell = cell as? ContactsCell else {
            return
        }

        cell.avatarImageView.image = nil
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

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

// MARK: - UISearchResultsUpdating 

extension ContactsViewController: UISearchResultsUpdating {

    func updateSearchResultsForSearchController(searchController: UISearchController) {

        guard let searchText = searchController.searchBar.text else {
            return
        }
        
        let predicate = NSPredicate(format: "nickname CONTAINS[c] %@ OR username CONTAINS[c] %@", searchText, searchText)
        filteredFriends = friends.filter(predicate)

        updateContactsTableView()

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

// MARK: - UISearchBarDelegate

extension ContactsViewController: UISearchBarDelegate {

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {

        if let searchController = searchController {
            updateSearchResultsForSearchController(searchController)
        }
    }
}

extension ContactsViewController: UISearchControllerDelegate {

    func willPresentSearchController(searchController: UISearchController) {
        coverUnderStatusBarView.hidden = false
    }

    func willDismissSearchController(searchController: UISearchController) {
        coverUnderStatusBarView.hidden = true
    }
}


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

class ContactsViewController: BaseViewController {

    @IBOutlet weak var contactsTableView: UITableView!

    @IBOutlet weak var coverUnderStatusBarView: UIView!
    
    var searchController: UISearchController?
    var searchControllerIsActive: Bool {
        return searchController?.active ?? false
    }

    let cellIdentifier = "ContactsCell"

    lazy var friends = normalFriends()
    var filteredFriends: Results<User>?

    var realmNotificationToken: NotificationToken?

    lazy var noContactsFooterView: InfoView = InfoView(NSLocalizedString("No friends yet.\nTry discover or add some.", comment: ""))

    var noContacts = false {
        didSet {
            if noContacts != oldValue {
                contactsTableView.tableFooterView = noContacts ? noContactsFooterView : UIView()
            }
        }
    }

    struct Listener {
        static let Nickname = "ContactsViewController.Nickname"
        static let Avatar = "ContactsViewController.Avatar"
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)

        YepUserDefaults.avatarURLString.removeListenerWithName(Listener.Avatar)
        YepUserDefaults.nickname.removeListenerWithName(Listener.Nickname)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        syncFriendshipsAndDoFurtherAction {
        }

        title = NSLocalizedString("Contacts", comment: "")

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "syncFriendships", name: FriendsInContactsViewController.Notification.NewFriends, object: nil)

        coverUnderStatusBarView.hidden = true

        // 超过一定人数才显示搜索框

        if friends.count > Ruler.iPhoneVertical(6, 8, 10, 12).value {

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
    }

    // MARK: Actions

    func updateContactsTableView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.contactsTableView.reloadData()
        }
    }

    func syncFriendships() {
        syncFriendshipsAndDoFurtherAction {
            dispatch_async(dispatch_get_main_queue()) {
                self.updateContactsTableView()
            }
        }
    }

    @IBAction func presentAddFriends(sender: UIBarButtonItem) {
        performSegueWithIdentifier("presentAddFriends", sender: nil)
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showProfile" {
            let vc = segue.destinationViewController as! ProfileViewController

            if let user = sender as? User {
                if user.userID != YepUserDefaults.userID.value {
                    vc.profileUser = ProfileUser.UserType(user)
                }
            }

            vc.hidesBottomBarWhenPushed = true
            
            vc.setBackButtonWithTitle()
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ContactsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchControllerIsActive ? (filteredFriends?.count ?? 0) : friends.count
    }

    private func friendAtIndexPath(indexPath: NSIndexPath) -> User? {
        let index = indexPath.row
        let friend = searchControllerIsActive ? filteredFriends?[safe: index] : friends[safe: index]
        return friend
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell

        if let friend = friendAtIndexPath(indexPath) {

//            let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5
//
//            AvatarCache.sharedInstance.roundAvatarOfUser(friend, withRadius: radius) { [weak cell] roundImage in
//                dispatch_async(dispatch_get_main_queue()) {
//                    if let _ = tableView.cellForRowAtIndexPath(indexPath) {
//                        cell?.avatarImageView.image = roundImage
//                    }
//                }
//            }
            let userAvatar = UserAvatar(userID: friend.userID, avatarStyle: miniAvatarStyle)
            cell.avatarImageView.navi_setAvatar(userAvatar)

            cell.nameLabel.text = friend.nickname

            if let badge = BadgeView.Badge(rawValue: friend.badge) {
                cell.badgeImageView.image = badge.image
                cell.badgeImageView.tintColor = badge.color
            } else {
                cell.badgeImageView.image = nil
            }

            cell.joinedDateLabel.text = friend.introduction
            cell.lastTimeSeenLabel.text = NSLocalizedString("Last seen ", comment: "") + NSDate(timeIntervalSince1970: friend.lastSignInUnixTime).timeAgo.lowercaseString
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if let friend = friendAtIndexPath(indexPath) {

            searchController?.active = false

            performSegueWithIdentifier("showProfile", sender: friend)
        }
   }
}

// MARK: - UISearchResultsUpdating 

extension ContactsViewController: UISearchResultsUpdating {

    func updateSearchResultsForSearchController(searchController: UISearchController) {

        guard let searchText = searchController.searchBar.text else {
            return
        }
        
        let predicate = NSPredicate(format: "nickname CONTAINS[c] %@", searchText)
        filteredFriends = friends.filter(predicate)

        updateContactsTableView()
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


//
//  ContactsViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift
import Ruler

final class ContactsViewController: BaseViewController {

    @IBOutlet weak var contactsTableView: UITableView! {
        didSet {
            searchBar.sizeToFit()
            contactsTableView.tableHeaderView = searchBar

            contactsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            contactsTableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

            contactsTableView.rowHeight = 80
            contactsTableView.tableFooterView = UIView()

            contactsTableView.registerNibOf(ContactsCell)
        }
    }

    @IBOutlet private weak var coverUnderStatusBarView: UIView!

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .Minimal
        searchBar.placeholder = NSLocalizedString("Search Friend", comment: "")
        searchBar.setSearchFieldBackgroundImage(UIImage.yep_searchbarTextfieldBackground, forState: .Normal)
        searchBar.delegate = self
        return searchBar
    }()

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

    var originalNavigationControllerDelegate: UINavigationControllerDelegate?
    lazy var searchTransition: SearchTransition = {
        return SearchTransition()
    }()

    private lazy var friends = normalFriends()
    private var filteredFriends: Results<User>?

    private var searchedUsers: [DiscoveredUser] = []

    private var friendsNotificationToken: NotificationToken?

    private lazy var noContactsFooterView: InfoView = InfoView(NSLocalizedString("No friends yet.\nTry discover or add some.", comment: ""))

    private var noContacts = false {
        didSet {
            //contactsTableView.tableHeaderView = noContacts ? nil : searchBar

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

        friendsNotificationToken?.stop()

        /*
        // ref http://stackoverflow.com/a/33281648
        if let superView = searchController?.view.superview {
            superView.removeFromSuperview()
        }
         */

        println("deinit Contacts")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = String.trans_titleContacts

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ContactsViewController.syncFriendships(_:)), name: FriendsInContactsViewController.Notification.NewFriends, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ContactsViewController.deactiveSearchController(_:)), name: YepConfig.Notification.switchedToOthersFromContactsTab, object: nil)

        coverUnderStatusBarView.hidden = true

        // 超过一定人数才显示搜索框

        /*
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
            searchController.searchBar.setSearchFieldBackgroundImage(UIImage(named: "searchbar_textfield_background"), forState: .Normal)
            searchController.searchBar.sizeToFit()

            searchController.searchBar.delegate = self

            contactsTableView.tableHeaderView = searchController.searchBar

            self.searchController = searchController

            // ref http://stackoverflow.com/questions/30937275/uisearchcontroller-doesnt-hide-view-when-pushed
            //self.definesPresentationContext = true

            //contactsTableView.contentOffset.y = CGRectGetHeight(searchController.searchBar.frame)
        }
         */

        friendsNotificationToken = friends.addNotificationBlock({ [weak self] (change: RealmCollectionChange) in

            guard let strongSelf = self else {
                return
            }

            strongSelf.noContacts = strongSelf.friends.isEmpty

            let tableView = strongSelf.contactsTableView

            switch change {

            case .Initial:
                tableView.reloadData()

            case .Update(_, let deletions, let insertions, let modifications):
                let section = Section.Local.rawValue
                tableView.beginUpdates()
                tableView.insertRowsAtIndexPaths(insertions.map({ NSIndexPath(forRow: $0, inSection: section) }), withRowAnimation: .Automatic)
                tableView.deleteRowsAtIndexPaths(deletions.map({ NSIndexPath(forRow: $0, inSection: section) }), withRowAnimation: .Automatic)
                tableView.reloadRowsAtIndexPaths(modifications.map({ NSIndexPath(forRow: $0, inSection: section) }), withRowAnimation: .Automatic)
                tableView.endUpdates()

            case .Error(let error):
                fatalError("\(error)")
            }
        })

        YepUserDefaults.nickname.bindListener(Listener.Nickname) { [weak self] _ in
            SafeDispatch.async {
                self?.updateContactsTableView()
            }
        }

        YepUserDefaults.avatarURLString.bindListener(Listener.Avatar) { [weak self] _ in
            SafeDispatch.async {
                self?.updateContactsTableView()
            }
        }

        if traitCollection.forceTouchCapability == .Available {
            registerForPreviewingWithDelegate(self, sourceView: contactsTableView)
        }

        #if DEBUG
            //view.addSubview(contactsFPSLabel)
        #endif
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        recoverOriginalNavigationDelegate()
    }

    // MARK: Actions

    @objc private func deactiveSearchController(sender: NSNotification) {
        if let searchController = searchController {
            searchController.active = false
        }
    }

    private func updateContactsTableView(scrollsToTop scrollsToTop: Bool = false) {
        SafeDispatch.async { [weak self] in
            self?.contactsTableView.reloadData()

            if scrollsToTop {
                self?.contactsTableView.yep_scrollsToTop()
            }
        }
    }

    @objc private func syncFriendships(sender: NSNotification) {
        syncFriendshipsAndDoFurtherAction {
            SafeDispatch.async {
                self.updateContactsTableView()
            }
        }
    }

    @IBAction private func showAddFriends(sender: UIBarButtonItem) {
        performSegueWithIdentifier("showAddFriends", sender: nil)
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {
            
        case "showConversation":

            guard let realm = try? Realm() else {
                return
            }

            let vc = segue.destinationViewController as! ConversationViewController

            if let user = sender as? User where !user.isMe {

                if user.conversation == nil {
                    let newConversation = Conversation()
                    
                    newConversation.type = ConversationType.OneToOne.rawValue
                    newConversation.withFriend = user
                    
                    let _ = try? realm.write {
                        realm.add(newConversation)
                    }
                }

                vc.conversation = user.conversation

                NSNotificationCenter.defaultCenter().postNotificationName(Config.Notification.changedConversation, object: nil)
            }

            recoverOriginalNavigationDelegate()
            
        case "showProfile":

            let vc = segue.destinationViewController as! ProfileViewController

            if let user = sender as? User {
               vc.prepare(withUser: user)
                
            } else if let discoveredUser = (sender as? Box<DiscoveredUser>)?.value {
                vc.prepare(withDiscoveredUser: discoveredUser)
            }

            recoverOriginalNavigationDelegate()
            
        case "showSearchContacts":
            
            let vc = segue.destinationViewController as! SearchContactsViewController
            vc.originalNavigationControllerDelegate = navigationController?.delegate
            
            vc.hidesBottomBarWhenPushed = true
            
            prepareSearchTransition()
            
        default:
            break
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
        return 1
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

    private func friendAtIndexPath(indexPath: NSIndexPath) -> User? {
        let index = indexPath.row
        let friend = searchControllerIsActive ? filteredFriends?[safe: index] : friends[safe: index]
        return friend
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell: ContactsCell = tableView.dequeueReusableCell()
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

            if searchControllerIsActive {
                cell.configureForSearchWithUser(friend)
            } else {
                cell.configureWithUser(friend)
            }
            cell.showProfileAction = { [weak self] in
                if let friend = self?.friendAtIndexPath(indexPath) {
                    self?.searchController?.active = false
                    self?.performSegueWithIdentifier("showProfile", sender: friend)
                }
            }
            
        case .Online:
            
            let discoveredUser = searchedUsers[indexPath.row]
            cell.configureForSearchWithDiscoveredUser(discoveredUser)
            cell.showProfileAction = { [weak self] in
                if let discoveredUser = self?.searchedUsers[indexPath.row] {
                    self?.searchController?.active = false
                    self?.performSegueWithIdentifier("showProfile", sender: Box<DiscoveredUser>(discoveredUser))
                }
            }
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
                searchController?.active = false
                performSegueWithIdentifier("showProfile", sender: friend)
            }
            
        case .Online:
            
            let discoveredUser = searchedUsers[indexPath.row]
            searchController?.active = false
            performSegueWithIdentifier("showProfile", sender: Box<DiscoveredUser>(discoveredUser))
        }
    }

    // MARK: UITableViewRowAction

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {

        guard let section = Section(rawValue: indexPath.section) else {
            return false
        }

        switch section {
        case .Local:
            return true
        case .Online:
            return false
        }
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {

        let user = friends[indexPath.row]
        let userID = user.userID
        let nickname = user.nickname

        let unfriendAction = UITableViewRowAction(style: .Default, title: NSLocalizedString("Unfriend", comment: "")) { [weak self, weak tableView] action, indexPath in

            tableView?.setEditing(false, animated: true)

            YepAlert.confirmOrCancel(title: NSLocalizedString("Unfriend", comment: ""), message: String(format: NSLocalizedString("Do you want to unfriend with %@?", comment: ""), nickname), confirmTitle: String.trans_confirm, cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                unfriend(withUserID: userID, failureHandler: { [weak self] (reason, errorMessage) in
                    let message = errorMessage ?? NSLocalizedString("Unfriend failed!", comment: "")
                    YepAlert.alertSorry(message: message, inViewController: self)

                }, completion: {
                    SafeDispatch.async { [weak self] in
                        if let user = self?.friends[indexPath.row], let realm = user.realm {
                            realm.beginWrite()
                            user.friendState = UserFriendState.Stranger.rawValue
                            _ = try? realm.commitWrite()
                        }
                    }
                })

            }, cancelAction: {
            })
        }

        return [unfriendAction]
    }
}

// MARK: - UISearchResultsUpdating 

extension ContactsViewController: UISearchResultsUpdating {

    func updateSearchResultsForSearchController(searchController: UISearchController) {

        guard let searchText = searchController.searchBar.text else {
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

                var searchedUsers: [DiscoveredUser] = []

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

    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {

        performSegueWithIdentifier("showSearchContacts", sender: nil)

        return false
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {

        if let searchController = searchController {
            updateSearchResultsForSearchController(searchController)
        }
    }
}

extension ContactsViewController: UISearchControllerDelegate {

    func willPresentSearchController(searchController: UISearchController) {
        println("willPresentSearchController")
        coverUnderStatusBarView.hidden = false
    }

    func willDismissSearchController(searchController: UISearchController) {
        println("willDismissSearchController")
        coverUnderStatusBarView.hidden = true
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension ContactsViewController: UIViewControllerPreviewingDelegate {

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let indexPath = contactsTableView.indexPathForRowAtPoint(location), cell = contactsTableView.cellForRowAtIndexPath(indexPath) else {
            return nil
        }

        previewingContext.sourceRect = cell.frame

        let vc = UIStoryboard.Scene.profile

        let user = friends[indexPath.row]
        vc.prepare(withUser: user)

        recoverOriginalNavigationDelegate()

        return vc
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {

        showViewController(viewControllerToCommit, sender: self)
    }
}


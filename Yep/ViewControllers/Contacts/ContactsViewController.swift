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

final class ContactsViewController: BaseViewController, CanScrollsToTop {

    @IBOutlet private weak var contactsTableView: UITableView! {
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

    // CanScrollsToTop
    var scrollView: UIScrollView? {
        return contactsTableView
    }

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

    var originalNavigationControllerDelegate: UINavigationControllerDelegate?
    lazy var searchTransition: SearchTransition = {
        return SearchTransition()
    }()

    private lazy var friends = normalFriends()

    private var friendsNotificationToken: NotificationToken?

    private lazy var noContactsFooterView: InfoView = InfoView(String.trans_promptNoFriends)

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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ContactsViewController.syncFriendships(_:)), name: YepConfig.Notification.newFriendsInContacts, object: nil)

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

    private func updateContactsTableView(scrollsToTop scrollsToTop: Bool = false) {
        SafeDispatch.async { [weak self] in
            self?.contactsTableView.reloadData()

            if scrollsToTop {
                self?.contactsTableView.yep_scrollsToTop()
            }
        }
    }

    @objc private func syncFriendships(sender: NSNotification) {

        syncFriendshipsAndDoFurtherAction { [weak self] in
            self?.updateContactsTableView()
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
                vc.prepare(with: discoveredUser)
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
            return friends.count
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection(section)
    }

    private func friendAtIndexPath(indexPath: NSIndexPath) -> User? {

        let index = indexPath.row
        let friend = friends[safe: index]
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

            cell.configureWithUser(friend)

            cell.showProfileAction = { [weak self] in
                if let friend = self?.friendAtIndexPath(indexPath) {
                    self?.performSegueWithIdentifier("showProfile", sender: friend)
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
                performSegueWithIdentifier("showProfile", sender: friend)
            }
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
        }
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {

        let user = friends[indexPath.row]
        let userID = user.userID
        let nickname = user.nickname

        let unfriendAction = UITableViewRowAction(style: .Default, title: NSLocalizedString("Unfriend", comment: "")) { [weak self, weak tableView] action, indexPath in

            tableView?.setEditing(false, animated: true)

            YepAlert.confirmOrCancel(title: NSLocalizedString("Unfriend", comment: ""), message: String.trans_promptTryUnfriendWith(nickname), confirmTitle: String.trans_confirm, cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

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

// MARK: - UISearchBarDelegate

extension ContactsViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {

        performSegueWithIdentifier("showSearchContacts", sender: nil)

        return false
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


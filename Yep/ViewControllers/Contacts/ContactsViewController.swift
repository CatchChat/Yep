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

    @IBOutlet fileprivate weak var contactsTableView: UITableView! {
        didSet {
            searchBar.sizeToFit()
            contactsTableView.tableHeaderView = searchBar

            contactsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            contactsTableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

            contactsTableView.rowHeight = 80
            contactsTableView.tableFooterView = UIView()

            contactsTableView.registerNibOf(ContactsCell.self)
        }
    }

    // CanScrollsToTop
    var scrollView: UIScrollView? {
        return contactsTableView
    }

    fileprivate lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = NSLocalizedString("Search Friend", comment: "")
        searchBar.setSearchFieldBackgroundImage(UIImage.yep_searchbarTextfieldBackground, for: UIControlState())
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

    fileprivate lazy var friends = normalFriends()

    fileprivate var friendsNotificationToken: NotificationToken?

    fileprivate lazy var noContactsFooterView: InfoView = InfoView(String.trans_promptNoFriends)

    fileprivate var noContacts = false {
        didSet {
            //contactsTableView.tableHeaderView = noContacts ? nil : searchBar

            if noContacts != oldValue {
                contactsTableView.tableFooterView = noContacts ? noContactsFooterView : UIView()
            }
        }
    }

    fileprivate struct Listener {
        static let Nickname = "ContactsViewController.Nickname"
        static let Avatar = "ContactsViewController.Avatar"
    }

    deinit {
        NotificationCenter.default.removeObserver(self)

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

        NotificationCenter.default.addObserver(self, selector: #selector(ContactsViewController.syncFriendships(_:)), name: YepConfig.NotificationName.newFriendsInContacts, object: nil)

        friendsNotificationToken = friends.addNotificationBlock({ [weak self] (change: RealmCollectionChange) in

            guard let strongSelf = self else {
                return
            }

            strongSelf.noContacts = strongSelf.friends.isEmpty

            guard let tableView = strongSelf.contactsTableView else {
                return
            }

            switch change {

            case .initial:
                tableView.reloadData()

            case .update(_, let deletions, let insertions, let modifications):
                let section = Section.local.rawValue
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: section) }), with: .automatic)
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: section) }), with: .automatic)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: section) }), with: .automatic)
                tableView.endUpdates()

            case .error(let error):
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

        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: contactsTableView)
        }

        #if DEBUG
            //view.addSubview(contactsFPSLabel)
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        recoverOriginalNavigationDelegate()
    }

    // MARK: Actions

    fileprivate func updateContactsTableView(scrollsToTop: Bool = false) {
        SafeDispatch.async { [weak self] in
            self?.contactsTableView.reloadData()

            if scrollsToTop {
                self?.contactsTableView.yep_scrollsToTop()
            }
        }
    }

    @objc fileprivate func syncFriendships(_ sender: Notification) {

        syncFriendshipsAndDoFurtherAction { [weak self] in
            self?.updateContactsTableView()
        }
    }

    @IBAction fileprivate func showAddFriends(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showAddFriends", sender: nil)
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {
            
        case "showConversation":

            guard let realm = try? Realm() else {
                return
            }

            let vc = segue.destination as! ConversationViewController

            if let user = sender as? User , !user.isMe {

                if user.conversation == nil {
                    let newConversation = Conversation()
                    
                    newConversation.type = ConversationType.oneToOne.rawValue
                    newConversation.withFriend = user
                    
                    let _ = try? realm.write {
                        realm.add(newConversation)
                    }
                }

                vc.conversation = user.conversation

                NotificationCenter.default.post(name: Config.NotificationName.changedConversation, object: nil)
            }

            recoverOriginalNavigationDelegate()
            
        case "showProfile":

            let vc = segue.destination as! ProfileViewController

            let user = sender as! User
            vc.prepare(withUser: user)

            recoverOriginalNavigationDelegate()
            
        case "showSearchContacts":
            
            let vc = segue.destination as! SearchContactsViewController
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
        case local
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    fileprivate func numberOfRowsInSection(_ section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            return 0
        }

        switch section {
        case .local:
            return friends.count
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection(section)
    }

    fileprivate func friendAtIndexPath(_ indexPath: IndexPath) -> User? {

        let index = indexPath.row
        let friend = friends[safe: index]
        return friend
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: ContactsCell = tableView.dequeueReusableCell()
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        guard let cell = cell as? ContactsCell else {
            return
        }

        guard let section = Section(rawValue: indexPath.section) else {
            return
        }

        switch section {

        case .local:

            guard let friend = friendAtIndexPath(indexPath) else {
                return
            }

            cell.configureWithUser(friend)

            cell.showProfileAction = { [weak self] in
                if let friend = self?.friendAtIndexPath(indexPath) {
                    self?.performSegue(withIdentifier: "showProfile", sender: friend)
                }
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        guard let cell = cell as? ContactsCell else {
            return
        }

        cell.avatarImageView.image = nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        guard let section = Section(rawValue: indexPath.section) else {
            return
        }
        
        switch section {
        case .local:
            if let friend = friendAtIndexPath(indexPath) {
                performSegue(withIdentifier: "showProfile", sender: friend)
            }
        }
    }

    // MARK: UITableViewRowAction

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        guard let section = Section(rawValue: indexPath.section) else {
            return false
        }

        switch section {
        case .local:
            return true
        }
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let user = friends[indexPath.row]
        let userID = user.userID
        let nickname = user.nickname

        let unfriendAction = UITableViewRowAction(style: .default, title: NSLocalizedString("Unfriend", comment: "")) { [weak self, weak tableView] action, indexPath in

            tableView?.setEditing(false, animated: true)

            YepAlert.confirmOrCancel(title: NSLocalizedString("Unfriend", comment: ""), message: String.trans_promptTryUnfriendWith(nickname), confirmTitle: String.trans_confirm, cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                unfriend(withUserID: userID, failureHandler: { [weak self] (reason, errorMessage) in
                    let message = errorMessage ?? NSLocalizedString("Unfriend failed!", comment: "")
                    YepAlert.alertSorry(message: message, inViewController: self)

                }, completion: {
                    SafeDispatch.async { [weak self] in
                        if let user = self?.friends[indexPath.row], let realm = user.realm {
                            realm.beginWrite()
                            user.friendState = UserFriendState.stranger.rawValue
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

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {

        performSegue(withIdentifier: "showSearchContacts", sender: nil)

        return false
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension ContactsViewController: UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let indexPath = contactsTableView.indexPathForRow(at: location), let cell = contactsTableView.cellForRow(at: indexPath) else {
            return nil
        }

        previewingContext.sourceRect = cell.frame

        let vc = UIStoryboard.Scene.profile

        let user = friends[indexPath.row]
        vc.prepare(withUser: user)

        recoverOriginalNavigationDelegate()

        return vc
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {

        show(viewControllerToCommit, sender: self)
    }
}


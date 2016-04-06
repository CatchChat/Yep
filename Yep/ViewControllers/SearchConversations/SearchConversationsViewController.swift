//
//  SearchConversationsViewController.swift
//  Yep
//
//  Created by NIX on 16/4/1.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import KeyboardMan
import RealmSwift

class SearchConversationsViewController: SegueViewController {

    var originalNavigationControllerDelegate: UINavigationControllerDelegate?
    private var conversationsSearchTransition: ConversationsSearchTransition?

    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            searchBar.placeholder = NSLocalizedString("Search", comment: "")
        }
    }
    @IBOutlet weak var searchBarTopConstraint: NSLayoutConstraint!

    private let headerIdentifier = "TableSectionTitleView"
    //private let searchSectionTitleCellID = "SearchSectionTitleCell"
    private let searchedUserCellID = "SearchedUserCell"
    private let searchedMessageCellID = "SearchedMessageCell"
    private let searchedFeedCellID = "SearchedFeedCell"

    @IBOutlet weak var resultsTableView: UITableView! {
        didSet {
            resultsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            resultsTableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

            resultsTableView.registerClass(TableSectionTitleView.self, forHeaderFooterViewReuseIdentifier: headerIdentifier)
            //resultsTableView.registerNib(UINib(nibName: searchSectionTitleCellID, bundle: nil), forCellReuseIdentifier: searchSectionTitleCellID)
            resultsTableView.registerNib(UINib(nibName: searchedUserCellID, bundle: nil), forCellReuseIdentifier: searchedUserCellID)
            resultsTableView.registerNib(UINib(nibName: searchedMessageCellID, bundle: nil), forCellReuseIdentifier: searchedMessageCellID)
            resultsTableView.registerNib(UINib(nibName: searchedFeedCellID, bundle: nil), forCellReuseIdentifier: searchedFeedCellID)

            resultsTableView.rowHeight = 80
            //resultsTableView.sectionHeaderHeight = 10
            //resultsTableView.sectionFooterHeight = 10
            //resultsTableView.contentInset = UIEdgeInsets(top: -36, left: 0, bottom: 0, right: 0)

            resultsTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 0))
            resultsTableView.tableFooterView = UIView()
        }
    }

    private lazy var friends = normalFriends()
    private var filteredFriends: Results<User>?

    private var realm: Realm!

    private lazy var oneToOneConversations: Results<Conversation> = {
        return oneToOneConversationsInRealm(self.realm)
    }()
    struct UserMessages {
        let user: User
        let messages: [Message]
    }
    private var filteredUserMessages: [UserMessages]?

//    private lazy var messages: Results<Message> = {
//        return self.realm.objects(Message)
//    }()
//    private var filteredMessages: [Message]?

    private lazy var feeds: Results<Feed> = {
        return self.realm.objects(Feed)
    }()
    private var filteredFeeds: [Feed]?

    private var keyword: String?
    
    private let keyboardMan = KeyboardMan()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Search", comment: "") 

        realm = try! Realm()

        keyboardMan.animateWhenKeyboardAppear = { [weak self] _, keyboardHeight, _ in
            self?.resultsTableView.contentInset.bottom = keyboardHeight
            self?.resultsTableView.scrollIndicatorInsets.bottom = keyboardHeight
        }

        keyboardMan.animateWhenKeyboardDisappear = { [weak self] _ in
            self?.resultsTableView.contentInset.bottom = 0
            self?.resultsTableView.scrollIndicatorInsets.bottom = 0
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let delegate = conversationsSearchTransition {
            navigationController?.delegate = delegate
        }

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] _ in
            self?.searchBarTopConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }, completion: nil)

        searchBar.becomeFirstResponder()
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        func hackNavigationDelegate() {
            // 记录原始的 conversationsSearchTransition 以便 pop 后恢复
            conversationsSearchTransition = navigationController?.delegate as? ConversationsSearchTransition

            println("originalNavigationControllerDelegate: \(originalNavigationControllerDelegate)")
            navigationController?.delegate = originalNavigationControllerDelegate
        }

        switch identifier {

        case "showProfile":
            let vc = segue.destinationViewController as! ProfileViewController

            let user = sender as! User
            vc.profileUser = .UserType(user)

            vc.hidesBottomBarWhenPushed = true

            vc.setBackButtonWithTitle()

            hackNavigationDelegate()

        case "showConversation":
            let vc = segue.destinationViewController as! ConversationViewController
            let info = (sender as! Box<[String: AnyObject]>).value
            vc.conversation = info["conversation"] as! Conversation
            vc.indexOfSearchedMessage = info["indexOfSearchedMessage"] as? Int

            hackNavigationDelegate()

        case "showSearchedUserMessages":
            let vc = segue.destinationViewController as! SearchedUserMessagesViewController
            let userMessages = (sender as! Box<UserMessages>).value

            vc.messages = userMessages.messages
            vc.keyword = keyword

            hackNavigationDelegate()

        default:
            break
        }
    }

    // MARK: - Private

    private func hideKeyboard() {

        searchBar.resignFirstResponder()
    }

    private func updateResultsTableView(scrollsToTop scrollsToTop: Bool = false) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.resultsTableView.reloadData()

            if scrollsToTop {
                self?.resultsTableView.yep_scrollsToTop()
            }
        }
    }
}

// MARK: - UISearchBarDelegate

extension SearchConversationsViewController: UISearchBarDelegate {

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {

        searchBar.text = nil
        searchBar.resignFirstResponder()

        (tabBarController as? YepTabBarController)?.setTabBarHidden(false, animated: true)

        navigationController?.popViewControllerAnimated(true)
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {

        hideKeyboard()
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {

        let searchText = searchText.trimming(.Whitespace)
        updateSearchResultsWithText(searchText)
    }

    private func updateSearchResultsWithText(searchText: String) {

        guard !searchText.isEmpty else {
            filteredFriends = nil
            filteredUserMessages = nil
            //filteredMessages = nil
            filteredFeeds = nil

            updateResultsTableView(scrollsToTop: true)

            return
        }

        self.keyword = searchText

        var scrollsToTop = false

        defer {

        }

        // users
        do {
            let predicate = NSPredicate(format: "nickname CONTAINS[c] %@ OR username CONTAINS[c] %@", searchText, searchText)
            let filteredFriends = friends.filter(predicate)
            self.filteredFriends = filteredFriends

            scrollsToTop = !filteredFriends.isEmpty
        }

        // messages
        do {
            let filteredUserMessages: [UserMessages] = oneToOneConversations.map({
                let messages = $0.messages
                let filteredMessages = filterValidMessages(messages)
                let searchedMessages = filteredMessages
                    .filter({ $0.textContent.localizedStandardContainsString(searchText) })

                guard let user = $0.withFriend where !searchedMessages.isEmpty else {
                    return nil
                }
                return UserMessages(user: user, messages: searchedMessages)
            }).flatMap({ $0 })

            self.filteredUserMessages = filteredUserMessages

            scrollsToTop = !filteredUserMessages.isEmpty
        }
//        do {
//            let predicate = NSPredicate(format: "textContent CONTAINS[c] %@", searchText)
//            let filteredMessages = filterValidMessages(messages.filter(predicate))
//            self.filteredMessages = filteredMessages
//
//            scrollsToTop = !filteredMessages.isEmpty
//        }

        // feeds
        do {
            let predicate = NSPredicate(format: "body CONTAINS[c] %@", searchText)
            let filteredFeeds = filterValidFeeds(feeds.filter(predicate))
            self.filteredFeeds = filteredFeeds

            scrollsToTop = !filteredFeeds.isEmpty
        }

        updateResultsTableView(scrollsToTop: scrollsToTop)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension SearchConversationsViewController: UITableViewDataSource, UITableViewDelegate {

    enum Section: Int {
        case Friend
        case MessageRecord
        case Feed
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 3
    }

    private func numberOfRowsInSection(section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            return 0
        }

        switch section {
        case .Friend:
            return filteredFriends?.count ?? 0
//            if let count = filteredFriends?.count where count > 0 {
//                return count + 1
//            } else {
//                return 0
//            }
        case .MessageRecord:
            return filteredUserMessages?.count ?? 0
            //return filteredMessages?.count ?? 0
//            if let count = filteredMessages?.count where count > 0 {
//                return count + 1
//            } else {
//                return 0
//            }
        case .Feed:
            return filteredFeeds?.count ?? 0
//            if let count = filteredFeeds?.count where count > 0 {
//                return count + 1
//            } else {
//                return 0
//            }
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return numberOfRowsInSection(section)
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        guard numberOfRowsInSection(section) > 0 else {
            return nil
        }

        guard let section = Section(rawValue: section) else {
            return nil
        }

        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(headerIdentifier) as? TableSectionTitleView

        switch section {
        case .Friend:
            header?.titleLabel.text = NSLocalizedString("Friends", comment: "")
        case .MessageRecord:
            header?.titleLabel.text = NSLocalizedString("Messages", comment: "")
        case .Feed:
            header?.titleLabel.text = NSLocalizedString("Joined Feeds", comment: "")
        }

        return header
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        guard numberOfRowsInSection(section) > 0 else {
            return 0
        }

        return 25
    }

    /*
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if indexPath.row == 0 {
            return 40
        } else {
            return 80
        }
    }
    */

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

//        if indexPath.row == 0 {
//
//            let cell = tableView.dequeueReusableCellWithIdentifier(searchSectionTitleCellID) as! SearchSectionTitleCell
//
//            switch section {
//            case .Friend:
//                cell.sectionTitleLabel.text = NSLocalizedString("Friends", comment: "")
//            case .MessageRecord:
//                cell.sectionTitleLabel.text = NSLocalizedString("Messages", comment: "")
//            case .Feed:
//                cell.sectionTitleLabel.text = NSLocalizedString("Joined Feeds", comment: "")
//            }
//
//            return cell
//        }

        switch section {

        case .Friend:
            let cell = tableView.dequeueReusableCellWithIdentifier(searchedUserCellID) as! SearchedUserCell
            return cell

        case .MessageRecord:
            let cell = tableView.dequeueReusableCellWithIdentifier(searchedMessageCellID) as! SearchedMessageCell
            return cell

        case .Feed:
            let cell = tableView.dequeueReusableCellWithIdentifier(searchedFeedCellID) as! SearchedFeedCell

            return cell
        }
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

//        guard indexPath.row > 0 else {
//            return
//        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

//        let itemIndex = indexPath.row - 1
        let itemIndex = indexPath.row

        switch section {

        case .Friend:
            guard let
                friend = filteredFriends?[safe: itemIndex],
                cell = cell as? SearchedUserCell else {
                    return
            }

            cell.configureWithUser(friend, keyword: keyword)

        case .MessageRecord:
            guard let
                userMessages = filteredUserMessages?[safe: itemIndex],
                cell = cell as? SearchedMessageCell else {
                    return
            }
            cell.configureWithUserMessages(userMessages, keyword: keyword)
//            guard let
//                message = filteredMessages?[safe: itemIndex],
//                cell = cell as? SearchedMessageCell else {
//                    return
//            }
//
//            cell.configureWithMessage(message, keyword: keyword)

        case .Feed:
            guard let
                feed = filteredFeeds?[safe: itemIndex],
                cell = cell as? SearchedFeedCell else {
                    return
            }

            cell.configureWithFeed(feed, keyword: keyword)
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

//        guard indexPath.row > 0 else {
//            return
//        }

        hideKeyboard()

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

//        let itemIndex = indexPath.row - 1
        let itemIndex = indexPath.row

        switch section {

        case .Friend:
            guard let friend = filteredFriends?[safe: itemIndex] else {
                return
            }

            performSegueWithIdentifier("showProfile", sender: friend)

        case .MessageRecord:
            guard let userMessages = filteredUserMessages?[safe: itemIndex] else {
                return
            }

            if userMessages.messages.count == 1 {
                let message = userMessages.messages.first!
                guard let conversation = message.conversation else {
                    return
                }

                let messages = messagesOfConversation(conversation, inRealm: realm)

                guard let indexOfSearchedMessage = messages.indexOf(message) else {
                    return
                }

                let info: [String: AnyObject] = [
                    "conversation":conversation,
                    "indexOfSearchedMessage": indexOfSearchedMessage,
                    ]
                let sender = Box<[String: AnyObject]>(info)
                performSegueWithIdentifier("showConversation", sender: sender)

            } else {
                performSegueWithIdentifier("showSearchedUserMessages", sender: Box<UserMessages>(userMessages))
            }

//            guard let
//                message = filteredMessages?[safe: itemIndex],
//                conversation = message.conversation else {
//                    return
//            }
//
//            let messages = messagesOfConversation(conversation, inRealm: realm)
//            guard let indexOfSearchedMessage = messages.indexOf(message) else {
//                return
//            }
//
//            let info: [String: AnyObject] = [
//                "conversation":conversation,
//                "indexOfSearchedMessage": indexOfSearchedMessage,
//            ]
//            let sender = Box<[String: AnyObject]>(info)
//            performSegueWithIdentifier("showConversation", sender: sender)

        case .Feed:
            guard let
                feed = filteredFeeds?[safe: itemIndex],
                conversation = feed.group?.conversation else {
                    return
            }

            let info: [String: AnyObject] = [
                "conversation":conversation,
                ]
            let sender = Box<[String: AnyObject]>(info)
            performSegueWithIdentifier("showConversation", sender: sender)
        }
    }
}


//
//  SearchConversationsViewController.swift
//  Yep
//
//  Created by NIX on 16/4/1.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift

final class SearchConversationsViewController: SegueViewController {

    var originalNavigationControllerDelegate: UINavigationControllerDelegate?
    var searchTransition: SearchTransition?

    private var searchBarCancelButtonEnabledObserver: ObjectKeypathObserver<UIButton>?
    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            searchBar.placeholder = NSLocalizedString("Search", comment: "")
            searchBar.setSearchFieldBackgroundImage(UIImage.yep_searchbarTextfieldBackground, forState: .Normal)
            searchBar.returnKeyType = .Done
        }
    }
    @IBOutlet weak var searchBarBottomLineView: HorizontalLineView! {
        didSet {
            searchBarBottomLineView.lineColor = UIColor(white: 0.68, alpha: 1.0)
        }
    }
    @IBOutlet weak var searchBarTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var resultsTableView: UITableView! {
        didSet {
            //resultsTableView.separatorColor = YepConfig.SearchTableView.separatorColor // not work here
            resultsTableView.backgroundColor = YepConfig.SearchTableView.backgroundColor

            resultsTableView.registerHeaderFooterClassOf(TableSectionTitleView)

            resultsTableView.registerNibOf(SearchSectionTitleCell)
            resultsTableView.registerNibOf(SearchedUserCell)
            resultsTableView.registerNibOf(SearchedMessageCell)
            resultsTableView.registerNibOf(SearchedFeedCell)
            resultsTableView.registerNibOf(SearchMoreResultsCell)

            resultsTableView.sectionHeaderHeight = 0
            resultsTableView.sectionFooterHeight = 0
            resultsTableView.contentInset = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)

            resultsTableView.tableFooterView = UIView()

            resultsTableView.keyboardDismissMode = .OnDrag
        }
    }

    private var searchTask: CancelableTask?

    private lazy var friends = normalFriends()
    private var filteredFriends: Results<User>?

    private var realm: Realm!

    private lazy var users: Results<User> = {
        return self.realm.objects(User)
    }()

    struct UserMessages {
        let user: User
        let messages: [Message]
    }
    private var filteredUserMessages: [UserMessages]?

    private lazy var feeds: Results<Feed> = {
        return self.realm.objects(Feed)
    }()
    private var filteredFeeds: [Feed]?

    private var countOfFilteredFriends: Int {
        return filteredFriends?.count ?? 0
    }
    private var countOfFilteredUserMessages: Int {
        return filteredUserMessages?.count ?? 0
    }
    private var countOfFilteredFeeds: Int {
        return filteredFeeds?.count ?? 0
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

    private func updateForFold(fold: Bool, withCountOfItems countOfItems: Int, inSection section: Section) {

        let indexPaths = ((1 + Section.maxNumberOfItems)...countOfItems).map({
            NSIndexPath(forRow: $0, inSection: section.rawValue)
        })

        if fold == false {
            resultsTableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        } else {
            resultsTableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        }
    }

    private var isMoreFriendsFold: Bool = true {
        didSet {
            if isMoreFriendsFold != oldValue {

                updateForFold(isMoreFriendsFold, withCountOfItems: countOfFilteredFriends, inSection: .Friend)
            }
        }
    }

    private var isMoreUserMessagesFold: Bool = true {
        didSet {
            if isMoreUserMessagesFold != oldValue {

                updateForFold(isMoreUserMessagesFold, withCountOfItems: countOfFilteredUserMessages, inSection: .MessageRecord)
            }
        }
    }

    private var isMoreFeedsFold: Bool = true {
        didSet {
            if isMoreFeedsFold != oldValue {

                updateForFold(isMoreFeedsFold, withCountOfItems: countOfFilteredFeeds, inSection: .Feed)
            }
        }
    }

    deinit {
        searchBarCancelButtonEnabledObserver = nil
        
        println("deinit SearchConversations")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Search", comment: "")

        resultsTableView.separatorColor = YepConfig.SearchTableView.separatorColor

        realm = try! Realm()

        searchBarBottomLineView.alpha = 0
    }

    private var isFirstAppear = true

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)

        if isFirstAppear {
            delay(0.3) { [weak self] in
                self?.searchBar.becomeFirstResponder()
            }
            delay(0.4) { [weak self] in
                self?.searchBar.setShowsCancelButton(true, animated: true)

                self?.searchBarCancelButtonEnabledObserver = self?.searchBar.yep_makeSureCancelButtonAlwaysEnabled()
            }
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        recoverSearchTransition()

        moveUpSearchBar()

        isFirstAppear = false
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showProfile":
            let vc = segue.destinationViewController as! ProfileViewController

            let user = sender as! User
            vc.prepare(withUser: user)

            prepareOriginalNavigationControllerDelegate()

        case "showConversation":
            let vc = segue.destinationViewController as! ConversationViewController
            let info = (sender as! Box<[String: AnyObject]>).value
            vc.conversation = info["conversation"] as! Conversation
            vc.indexOfSearchedMessage = info["indexOfSearchedMessage"] as? Int

            prepareOriginalNavigationControllerDelegate()

        case "showSearchedUserMessages":
            let vc = segue.destinationViewController as! SearchedUserMessagesViewController
            let userMessages = (sender as! Box<UserMessages>).value

            vc.messages = userMessages.messages
            vc.keyword = keyword

            prepareOriginalNavigationControllerDelegate()

        default:
            break
        }
    }

    // MARK: - Private

    private func hideKeyboard() {

        searchBar.resignFirstResponder()
    }

    private func updateResultsTableView(scrollsToTop scrollsToTop: Bool = false) {
        SafeDispatch.async { [weak self] in
            self?.resultsTableView.reloadData()

            if scrollsToTop {
                self?.resultsTableView.yep_scrollsToTop()
            }
        }
    }
}

// MARK: - UISearchBarDelegate

extension SearchConversationsViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {

        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] _ in
            self?.searchBarBottomLineView.alpha = 1
        }, completion: { finished in
        })

        return true
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {

        searchBar.text = nil
        searchBar.resignFirstResponder()

        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] _ in
            self?.searchBarBottomLineView.alpha = 0
        }, completion: { finished in
        })

        navigationController?.popViewControllerAnimated(true)
    }

    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {

        cancel(searchTask)

        searchTask = delay(0.5) { [weak self] in
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

        searchTask = delay(0.5) { [weak self] in
            self?.updateSearchResultsWithText(searchText)
        }
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {

        hideKeyboard()
    }

    private func clearSearchResults() {

        filteredFriends = nil
        filteredUserMessages = nil
        filteredFeeds = nil

        updateResultsTableView(scrollsToTop: true)
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

        isMoreFriendsFold = true
        isMoreUserMessagesFold = true
        isMoreFeedsFold = true

        var scrollsToTop = false

        // users
        do {
            let predicate = NSPredicate(format: "nickname CONTAINS[c] %@ OR username CONTAINS[c] %@", searchText, searchText)
            let filteredFriends = friends.filter(predicate)
            self.filteredFriends = filteredFriends

            scrollsToTop = !filteredFriends.isEmpty
        }

        // messages
        do {
            let filteredUserMessages: [UserMessages] = users.map({
                let messages = $0.messages.map({ $0 })
                let filteredMessages = filterValidMessages(messages)
                let searchedMessages = filteredMessages
                    .filter({ $0.textContent.localizedStandardContainsString(searchText) })
                let sortedMessages = searchedMessages.sort({ $0.createdUnixTime > $1.createdUnixTime })

                guard !sortedMessages.isEmpty else {
                    return nil
                }
                return UserMessages(user: $0, messages: sortedMessages)
            }).flatMap({ $0 })

            self.filteredUserMessages = filteredUserMessages

            scrollsToTop = !filteredUserMessages.isEmpty
        }

        // feeds
        do {
            let predicate = NSPredicate(format: "body CONTAINS[c] %@", searchText)
            let filteredFeeds = filterValidFeeds(feeds.filter(predicate))
            let sortedFilteredFeeds = filteredFeeds.sort({ $0.createdUnixTime > $1.createdUnixTime })
            self.filteredFeeds = sortedFilteredFeeds

            scrollsToTop = !sortedFilteredFeeds.isEmpty
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

        static let maxNumberOfItems: Int = 3
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 3
    }

    private func numberOfRowsInSection(section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            return 0
        }

        func numberOfRowsWithCountOfItems(countOfItems: Int, fold: Bool) -> Int {
            let count = countOfItems
            if count > 0 {
                if !fold {
                    return 1 + count + 1
                }
                if count > Section.maxNumberOfItems {
                    return 1 + Section.maxNumberOfItems + 1
                } else {
                    return 1 + count
                }
            } else {
                return 0
            }
        }

        switch section {

        case .Friend:
            return numberOfRowsWithCountOfItems(countOfFilteredFriends, fold: isMoreFriendsFold)

        case .MessageRecord:
            return numberOfRowsWithCountOfItems(countOfFilteredUserMessages, fold: isMoreUserMessagesFold)

        case .Feed:
            return numberOfRowsWithCountOfItems(countOfFilteredFeeds, fold: isMoreFeedsFold)
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

    private func haveMoreItemsInSection(section: Section) -> Bool {

        switch section {
        case .Friend:
            return countOfFilteredFriends > Section.maxNumberOfItems
        case .MessageRecord:
            return countOfFilteredUserMessages > Section.maxNumberOfItems
        case .Feed:
            return countOfFilteredFeeds > Section.maxNumberOfItems
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        guard indexPath.row > 0 else {
            return 40
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        if haveMoreItemsInSection(section) {
            if indexPath.row < numberOfRowsInSection(indexPath.section) - 1 {
                return 70
            } else {
                return 30
            }
        } else {
            return 70
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        if indexPath.row == 0 {

            let cell: SearchSectionTitleCell = tableView.dequeueReusableCell()

            switch section {
            case .Friend:
                cell.sectionTitleLabel.text = NSLocalizedString("Friends", comment: "")
            case .MessageRecord:
                cell.sectionTitleLabel.text = String.trans_titleChatRecords
            case .Feed:
                cell.sectionTitleLabel.text = NSLocalizedString("Joined Feeds", comment: "")
            }

            return cell
        }

        let itemIndex = indexPath.row - 1

        switch section {

        case .Friend:
            if itemIndex < (isMoreFriendsFold ? Section.maxNumberOfItems : countOfFilteredFriends) {
                let cell: SearchedUserCell = tableView.dequeueReusableCell()
                return cell
            } else {
                let cell: SearchMoreResultsCell = tableView.dequeueReusableCell()
                return cell
            }

        case .MessageRecord:
            if itemIndex < (isMoreUserMessagesFold ? Section.maxNumberOfItems : countOfFilteredUserMessages) {
                let cell: SearchedMessageCell = tableView.dequeueReusableCell()
                return cell
            } else {
                let cell: SearchMoreResultsCell = tableView.dequeueReusableCell()
                return cell
            }

        case .Feed:
            if itemIndex < (isMoreFeedsFold ? Section.maxNumberOfItems : countOfFilteredFeeds) {
                let cell: SearchedFeedCell = tableView.dequeueReusableCell()
                return cell
            } else {
                let cell: SearchMoreResultsCell = tableView.dequeueReusableCell()
                return cell
            }
        }
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        guard indexPath.row > 0 else {
            return
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        let itemIndex = indexPath.row - 1

        switch section {

        case .Friend:
            if itemIndex < (isMoreFriendsFold ? Section.maxNumberOfItems : countOfFilteredFriends) {
                guard let
                    friend = filteredFriends?[safe: itemIndex],
                    cell = cell as? SearchedUserCell else {
                        return
                }

                cell.configureWithUserRepresentation(friend, keyword: keyword)

            } else {
                guard let cell = cell as? SearchMoreResultsCell else {
                    return
                }
                cell.fold = isMoreFriendsFold
            }

        case .MessageRecord:

            if itemIndex < (isMoreUserMessagesFold ? Section.maxNumberOfItems : countOfFilteredUserMessages) {
                guard let
                    userMessages = filteredUserMessages?[safe: itemIndex],
                    cell = cell as? SearchedMessageCell else {
                        return
                }
                cell.configureWithUserMessages(userMessages, keyword: keyword)

            } else {
                guard let cell = cell as? SearchMoreResultsCell else {
                    return
                }
                cell.fold = isMoreUserMessagesFold
            }

        case .Feed:
            if itemIndex < (isMoreFeedsFold ? Section.maxNumberOfItems : countOfFilteredFeeds) {
                guard let
                    feed = filteredFeeds?[safe: itemIndex],
                    cell = cell as? SearchedFeedCell else {
                        return
                }

                cell.configureWithFeed(feed, keyword: keyword)

            } else {
                guard let cell = cell as? SearchMoreResultsCell else {
                    return
                }
                cell.fold = isMoreFeedsFold
            }
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        guard indexPath.row > 0 else {
            return
        }

        hideKeyboard()

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        let itemIndex = indexPath.row - 1

        switch section {

        case .Friend:
            if itemIndex < (isMoreFriendsFold ? Section.maxNumberOfItems : countOfFilteredFriends) {
                guard let friend = filteredFriends?[safe: itemIndex] else {
                    return
                }

                performSegueWithIdentifier("showProfile", sender: friend)

            } else {
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? SearchMoreResultsCell {
                    cell.fold = !isMoreFriendsFold
                }
                isMoreFriendsFold = !isMoreFriendsFold
            }

        case .MessageRecord:

            if itemIndex < (isMoreUserMessagesFold ? Section.maxNumberOfItems : countOfFilteredUserMessages) {
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

            } else {
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? SearchMoreResultsCell {
                    cell.fold = !isMoreUserMessagesFold
                }
                isMoreUserMessagesFold = !isMoreUserMessagesFold
            }

        case .Feed:
            if itemIndex < (isMoreFeedsFold ? Section.maxNumberOfItems : countOfFilteredFeeds) {
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

            } else {
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? SearchMoreResultsCell {
                    cell.fold = !isMoreFeedsFold
                }
                isMoreFeedsFold = !isMoreFeedsFold
            }
        }
    }
}


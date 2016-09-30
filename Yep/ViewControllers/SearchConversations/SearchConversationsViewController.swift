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
import KeypathObserver

final class SearchConversationsViewController: BaseSearchViewController {

    @IBOutlet weak var resultsTableView: UITableView! {
        didSet {
            //resultsTableView.separatorColor = YepConfig.SearchTableView.separatorColor // not work here
            resultsTableView.backgroundColor = YepConfig.SearchTableView.backgroundColor

            resultsTableView.registerHeaderFooterClassOf(TableSectionTitleView.self)

            resultsTableView.registerNibOf(SearchSectionTitleCell.self)
            resultsTableView.registerNibOf(SearchedUserCell.self)
            resultsTableView.registerNibOf(SearchedMessageCell.self)
            resultsTableView.registerNibOf(SearchedFeedCell.self)
            resultsTableView.registerNibOf(SearchMoreResultsCell.self)

            resultsTableView.sectionHeaderHeight = 0
            resultsTableView.sectionFooterHeight = 0
            resultsTableView.contentInset = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)

            resultsTableView.tableFooterView = UIView()

            resultsTableView.keyboardDismissMode = .onDrag
        }
    }

    fileprivate var searchTask: CancelableTask?

    fileprivate lazy var friends = normalFriends()
    fileprivate var filteredFriends: Results<User>?

    fileprivate var realm: Realm!

    fileprivate lazy var users: Results<User> = {
        return self.realm.objects(User.self)
    }()

    struct UserMessages {
        let user: User
        let messages: [Message]
    }
    fileprivate var filteredUserMessages: [UserMessages]?

    fileprivate lazy var feeds: Results<Feed> = {
        return self.realm.objects(Feed.self)
    }()
    fileprivate var filteredFeeds: [Feed]?

    fileprivate var countOfFilteredFriends: Int {
        return filteredFriends?.count ?? 0
    }
    fileprivate var countOfFilteredUserMessages: Int {
        return filteredUserMessages?.count ?? 0
    }
    fileprivate var countOfFilteredFeeds: Int {
        return filteredFeeds?.count ?? 0
    }

    fileprivate var keyword: String? {
        didSet {
            if keyword == nil {
                clearSearchResults()
            }
            if let keyword = keyword, keyword.isEmpty {
                clearSearchResults()
            }
        }
    }

    fileprivate func updateForFold(_ fold: Bool, withCountOfItems countOfItems: Int, inSection section: Section) {

        let indexPaths = ((1 + Section.maxNumberOfItems)...countOfItems).map({
            IndexPath(row: $0, section: section.rawValue)
        })

        if fold == false {
            resultsTableView.insertRows(at: indexPaths, with: .automatic)
        } else {
            resultsTableView.deleteRows(at: indexPaths, with: .automatic)
        }
    }

    fileprivate var isMoreFriendsFold: Bool = true {
        didSet {
            if isMoreFriendsFold != oldValue {

                updateForFold(isMoreFriendsFold, withCountOfItems: countOfFilteredFriends, inSection: .friend)
            }
        }
    }

    fileprivate var isMoreUserMessagesFold: Bool = true {
        didSet {
            if isMoreUserMessagesFold != oldValue {

                updateForFold(isMoreUserMessagesFold, withCountOfItems: countOfFilteredUserMessages, inSection: .messageRecord)
            }
        }
    }

    fileprivate var isMoreFeedsFold: Bool = true {
        didSet {
            if isMoreFeedsFold != oldValue {

                updateForFold(isMoreFeedsFold, withCountOfItems: countOfFilteredFeeds, inSection: .feed)
            }
        }
    }

    deinit {
        println("deinit SearchConversations")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Search", comment: "")

        searchBar.placeholder = NSLocalizedString("Search", comment: "")

        resultsTableView.separatorColor = YepConfig.SearchTableView.separatorColor

        realm = try! Realm()

        searchBarBottomLineView.alpha = 0
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showProfile":
            let vc = segue.destination as! ProfileViewController

            let user = sender as! User
            vc.prepare(withUser: user)

            prepareOriginalNavigationControllerDelegate()

        case "showConversation":
            let vc = segue.destination as! ConversationViewController
            let info = sender as! [String: Any]
            vc.conversation = info["conversation"] as! Conversation
            vc.indexOfSearchedMessage = info["indexOfSearchedMessage"] as? Int

            prepareOriginalNavigationControllerDelegate()

        case "showSearchedUserMessages":
            let vc = segue.destination as! SearchedUserMessagesViewController
            let userMessages = sender as! UserMessages
            vc.messages = userMessages.messages
            vc.keyword = keyword

            prepareOriginalNavigationControllerDelegate()

        default:
            break
        }
    }

    // MARK: - Private

    fileprivate func hideKeyboard() {

        searchBar.resignFirstResponder()
    }

    fileprivate func updateResultsTableView(scrollsToTop: Bool = false) {
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
        filteredUserMessages = nil
        filteredFeeds = nil

        updateResultsTableView(scrollsToTop: true)
    }

    fileprivate func updateSearchResultsWithText(_ searchText: String) {

        let searchText = searchText.trimming(.whitespace)

        // 不要重复搜索一样的内容
        if let keyword = self.keyword, keyword == searchText {
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
                let messages: [Message] = $0.messages.map({ $0 })
                let filteredMessages = filterValidMessages(messages)
                let searchedMessages = filteredMessages
                    .filter({ $0.textContent.localizedStandardContains(searchText) })
                let sortedMessages = searchedMessages.sorted(by: { $0.createdUnixTime > $1.createdUnixTime })

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
            let sortedFilteredFeeds = filteredFeeds.sorted(by: { $0.createdUnixTime > $1.createdUnixTime })
            self.filteredFeeds = sortedFilteredFeeds

            scrollsToTop = !sortedFilteredFeeds.isEmpty
        }

        updateResultsTableView(scrollsToTop: scrollsToTop)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension SearchConversationsViewController: UITableViewDataSource, UITableViewDelegate {

    enum Section: Int {
        case friend
        case messageRecord
        case feed

        static let maxNumberOfItems: Int = 3
    }

    func numberOfSections(in tableView: UITableView) -> Int {

        return 3
    }

    fileprivate func numberOfRowsInSection(_ section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            return 0
        }

        func numberOfRowsWithCountOfItems(_ countOfItems: Int, fold: Bool) -> Int {
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

        case .friend:
            return numberOfRowsWithCountOfItems(countOfFilteredFriends, fold: isMoreFriendsFold)

        case .messageRecord:
            return numberOfRowsWithCountOfItems(countOfFilteredUserMessages, fold: isMoreUserMessagesFold)

        case .feed:
            return numberOfRowsWithCountOfItems(countOfFilteredFeeds, fold: isMoreFeedsFold)
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

    fileprivate func haveMoreItemsInSection(_ section: Section) -> Bool {

        switch section {
        case .friend:
            return countOfFilteredFriends > Section.maxNumberOfItems
        case .messageRecord:
            return countOfFilteredUserMessages > Section.maxNumberOfItems
        case .feed:
            return countOfFilteredFeeds > Section.maxNumberOfItems
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        if indexPath.row == 0 {

            let cell: SearchSectionTitleCell = tableView.dequeueReusableCell()

            switch section {
            case .friend:
                cell.sectionTitleLabel.text = String.trans_titleFriends
            case .messageRecord:
                cell.sectionTitleLabel.text = String.trans_titleChatRecords
            case .feed:
                cell.sectionTitleLabel.text = String.trans_titleJoinedFeeds
            }

            return cell
        }

        let itemIndex = indexPath.row - 1

        switch section {

        case .friend:
            if itemIndex < (isMoreFriendsFold ? Section.maxNumberOfItems : countOfFilteredFriends) {
                let cell: SearchedUserCell = tableView.dequeueReusableCell()
                return cell
            } else {
                let cell: SearchMoreResultsCell = tableView.dequeueReusableCell()
                return cell
            }

        case .messageRecord:
            if itemIndex < (isMoreUserMessagesFold ? Section.maxNumberOfItems : countOfFilteredUserMessages) {
                let cell: SearchedMessageCell = tableView.dequeueReusableCell()
                return cell
            } else {
                let cell: SearchMoreResultsCell = tableView.dequeueReusableCell()
                return cell
            }

        case .feed:
            if itemIndex < (isMoreFeedsFold ? Section.maxNumberOfItems : countOfFilteredFeeds) {
                let cell: SearchedFeedCell = tableView.dequeueReusableCell()
                return cell
            } else {
                let cell: SearchMoreResultsCell = tableView.dequeueReusableCell()
                return cell
            }
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        guard indexPath.row > 0 else {
            return
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        let itemIndex = indexPath.row - 1

        switch section {

        case .friend:
            if itemIndex < (isMoreFriendsFold ? Section.maxNumberOfItems : countOfFilteredFriends) {
                guard let
                    friend = filteredFriends?[safe: itemIndex],
                    let cell = cell as? SearchedUserCell else {
                        return
                }

                cell.configureWithUserRepresentation(friend, keyword: keyword)

            } else {
                guard let cell = cell as? SearchMoreResultsCell else {
                    return
                }
                cell.fold = isMoreFriendsFold
            }

        case .messageRecord:

            if itemIndex < (isMoreUserMessagesFold ? Section.maxNumberOfItems : countOfFilteredUserMessages) {
                guard let
                    userMessages = filteredUserMessages?[itemIndex],
                    let cell = cell as? SearchedMessageCell else {
                        return
                }
                cell.configureWithUserMessages(userMessages, keyword: keyword)

            } else {
                guard let cell = cell as? SearchMoreResultsCell else {
                    return
                }
                cell.fold = isMoreUserMessagesFold
            }

        case .feed:
            if itemIndex < (isMoreFeedsFold ? Section.maxNumberOfItems : countOfFilteredFeeds) {
                guard let
                    feed = filteredFeeds?[safe: itemIndex],
                    let cell = cell as? SearchedFeedCell else {
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.row > 0 else {
            return
        }

        hideKeyboard()

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        let itemIndex = indexPath.row - 1

        switch section {

        case .friend:
            if itemIndex < (isMoreFriendsFold ? Section.maxNumberOfItems : countOfFilteredFriends) {
                guard let friend = filteredFriends?[safe: itemIndex] else {
                    return
                }

                performSegue(withIdentifier: "showProfile", sender: friend)

            } else {
                if let cell = tableView.cellForRow(at: indexPath) as? SearchMoreResultsCell {
                    cell.fold = !isMoreFriendsFold
                }
                isMoreFriendsFold = !isMoreFriendsFold
            }

        case .messageRecord:

            if itemIndex < (isMoreUserMessagesFold ? Section.maxNumberOfItems : countOfFilteredUserMessages) {
                guard let userMessages = filteredUserMessages?[itemIndex] else {
                    return
                }

                if userMessages.messages.count == 1 {
                    let message = userMessages.messages.first!
                    guard let conversation = message.conversation else {
                        return
                    }

                    let messages = messagesOfConversation(conversation, inRealm: realm)

                    guard let indexOfSearchedMessage = messages.index(of: message) else {
                        return
                    }

                    let info: [String: Any] = [
                        "conversation":conversation,
                        "indexOfSearchedMessage": indexOfSearchedMessage,
                    ]
                    performSegue(withIdentifier: "showConversation", sender: info)

                } else {
                    performSegue(withIdentifier: "showSearchedUserMessages", sender: userMessages)
                }

            } else {
                if let cell = tableView.cellForRow(at: indexPath) as? SearchMoreResultsCell {
                    cell.fold = !isMoreUserMessagesFold
                }
                isMoreUserMessagesFold = !isMoreUserMessagesFold
            }

        case .feed:
            if itemIndex < (isMoreFeedsFold ? Section.maxNumberOfItems : countOfFilteredFeeds) {
                guard let
                    feed = filteredFeeds?[safe: itemIndex],
                    let conversation = feed.group?.conversation else {
                        return
                }

                let info: [String: Any] = [
                    "conversation": conversation,
                ]
                performSegue(withIdentifier: "showConversation", sender: info)

            } else {
                if let cell = tableView.cellForRow(at: indexPath) as? SearchMoreResultsCell {
                    cell.fold = !isMoreFeedsFold
                }
                isMoreFeedsFold = !isMoreFeedsFold
            }
        }
    }
}


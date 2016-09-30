//
//  FeedConversationsViewController.swift
//  Yep
//
//  Created by nixzhu on 15/10/12.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift

final class FeedConversationsViewController: SegueViewController {

    @IBOutlet weak var feedConversationsTableView: UITableView! {
        didSet {
            feedConversationsTableView.registerNibOf(FeedConversationCell.self)
            feedConversationsTableView.registerNibOf(DeletedFeedConversationCell.self)
        }
    }

    fileprivate lazy var clearUnreadBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: String.trans_titleClearUnread, style: .plain, target: self, action: #selector(FeedConversationsViewController.clearUnread(_:)))
        return item
    }()

    fileprivate var realm: Realm!

    fileprivate var haveUnreadMessages = false {
        didSet {
            reloadFeedConversationsTableView()
        }
    }

    fileprivate lazy var feedConversations: Results<Conversation> = {
        return feedConversationsInRealm(self.realm)
    }()
    fileprivate var unreadFeedConversations: Results<Conversation>? {
        didSet {
            if let unreadFeedConversations = unreadFeedConversations {
                navigationItem.rightBarButtonItem = unreadFeedConversations.count > 3 ? clearUnreadBarButtonItem : nil
            } else {
                navigationItem.rightBarButtonItem = nil
            }
        }
    }
    fileprivate var feedConversationsNotificationToken: NotificationToken?

    deinit {

        NotificationCenter.default.removeObserver(self)

        feedConversationsTableView?.delegate = nil

        feedConversationsNotificationToken?.stop()

        println("deinit FeedConversations")
    }

    @objc fileprivate func clearUnread(_ sender: UIBarButtonItem) {

        realm.beginWrite()

        unreadFeedConversations?.forEach({ conversation in

            conversation.hasUnreadMessages = false

            conversation.messages.forEach({ message in
                if !message.readed {
                    message.readed = true
                }
            })
        })

        _ = try? realm.commitWrite()

        NotificationCenter.default.post(name: Config.NotificationName.changedFeedConversation, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        realm = try! Realm()

        title = String.trans_titleFeeds

        feedConversationsTableView.rowHeight = 80
        feedConversationsTableView.tableFooterView = UIView()

        feedConversationsNotificationToken = feedConversations.addNotificationBlock({ [weak self] (change: RealmCollectionChange) in
            let predicate = YepConfig.Conversation.hasUnreadMessagesPredicate
            self?.unreadFeedConversations = self?.feedConversations.filter(predicate)
        })

        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) {
                    feedConversationsTableView.panGestureRecognizer.require(toFail: recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(FeedConversationsViewController.reloadFeedConversationsTableView), name: Config.NotificationName.newMessages, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedConversationsViewController.reloadFeedConversationsTableView), name: Config.NotificationName.deletedMessages, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedConversationsViewController.reloadFeedConversationsTableView), name: Config.NotificationName.changedFeedConversation, object: nil)

        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: feedConversationsTableView)
        }
    }

    var isFirstAppear = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !isFirstAppear {
            haveUnreadMessages = countOfUnreadMessagesInRealm(realm, withConversationType: .group) > 0
        }

        isFirstAppear = false
    }

    // MARK: Actions

    func reloadFeedConversationsTableView() {

        SafeDispatch.async { [weak self] in
            self?.feedConversationsTableView.reloadData()
        }
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "showConversation" {
            let vc = segue.destination as! ConversationViewController
            let conversation = sender as! Conversation
            prepareConversationViewController(vc, withConversation: conversation)
        }
    }

    fileprivate func prepareConversationViewController(_ vc: ConversationViewController, withConversation conversation: Conversation) {

        vc.conversation = conversation
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension FeedConversationsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedConversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let conversation = feedConversations[indexPath.row]

        if let feed = conversation.withGroup?.withFeed {

            if feed.deleted {
                let cell: DeletedFeedConversationCell = tableView.dequeueReusableCell()
                return cell

            } else {
                let cell: FeedConversationCell = tableView.dequeueReusableCell()
                return cell
            }

        } else {
            let cell: FeedConversationCell = tableView.dequeueReusableCell()
            return cell
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        let conversation = feedConversations[indexPath.row]

        if let feed = conversation.withGroup?.withFeed {

            if feed.deleted {
                guard let cell = cell as? DeletedFeedConversationCell else {
                    return
                }

                cell.configureWithConversation(conversation)

            } else {
                guard let cell = cell as? FeedConversationCell else {
                    return
                }

                cell.configureWithConversation(conversation)
            }

        } else {
            guard let cell = cell as? FeedConversationCell else {
                return
            }

            cell.configureWithConversation(conversation)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        guard let conversation = feedConversations[safe: indexPath.row] else {
            return
        }

        performSegue(withIdentifier: "showConversation", sender: conversation)
    }

    // Edit (for Delete)

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        return true
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let title: String = NSLocalizedString("Unsubscribe", comment: "")

        let deleteAction = UITableViewRowAction(style: .default, title: title) { [weak self] action, indexPath in

            defer {
                tableView.setEditing(false, animated: true)
            }

            guard let conversation = self?.feedConversations[safe: indexPath.row] else {
                return
            }

            guard let feed = conversation.withGroup?.withFeed, let feedCreator = feed.creator else {
                return
            }

            let feedID = feed.feedID
            let feedCreatorID = feedCreator.userID

            let doDeleteConversation: () -> Void = {

                guard let realm = conversation.realm else {
                    return
                }

                realm.beginWrite()

                deleteConversation(conversation, inRealm: realm)

                let _ = try? realm.commitWrite()

                realm.refresh()

                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.endUpdates()

                // 延迟一些再发通知，避免影响 tableView 的删除
                _ = delay(0.5) {
                    NotificationCenter.default.post(name: Config.NotificationName.changedConversation, object: nil)
                }

                deleteSearchableItems(searchableItemType: .feed, itemIDs: [feedID])
            }

            // 若是创建者，再询问是否删除 Feed

            if feedCreatorID == YepUserDefaults.userID.value {

                YepAlert.confirmOrCancel(title: String.trans_titleDelete, message: String.trans_promptAlsoDeleteThisFeed, confirmTitle: String.trans_titleDelete, cancelTitle: String.trans_titleNotNow, inViewController: self, withConfirmAction: {

                    doDeleteConversation()

                    deleteFeedWithFeedID(feedID, failureHandler: nil, completion: {
                        println("deleted feed: \(feedID)")
                    })

                }, cancelAction: {
                    doDeleteConversation()
                })
                
            } else {
                doDeleteConversation()
            }
        }

        return [deleteAction]
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension FeedConversationsViewController: UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let indexPath = feedConversationsTableView.indexPathForRow(at: location), let cell = feedConversationsTableView.cellForRow(at: indexPath) else {
            return nil
        }

        previewingContext.sourceRect = cell.frame

        let vc = UIStoryboard.Scene.conversation
        let conversation = feedConversations[indexPath.row]
        prepareConversationViewController(vc, withConversation: conversation)

        vc.isPreviewed = true

        return vc
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        show(viewControllerToCommit, sender: self)
    }
}


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
            feedConversationsTableView.registerNibOf(FeedConversationCell)
            feedConversationsTableView.registerNibOf(DeletedFeedConversationCell)
        }
    }

    private lazy var clearUnreadBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: NSLocalizedString("FeedConversationsViewController.ClearUnread", comment: ""), style: .Plain, target: self, action: #selector(FeedConversationsViewController.clearUnread(_:)))
        return item
    }()

    private var realm: Realm!

    private var haveUnreadMessages = false {
        didSet {
            reloadFeedConversationsTableView()
        }
    }

    private lazy var feedConversations: Results<Conversation> = {
        return feedConversationsInRealm(self.realm)
    }()
    private var unreadFeedConversations: Results<Conversation>? {
        didSet {
            if let unreadFeedConversations = unreadFeedConversations {
                navigationItem.rightBarButtonItem = unreadFeedConversations.count > 3 ? clearUnreadBarButtonItem : nil
            } else {
                navigationItem.rightBarButtonItem = nil
            }
        }
    }
    private var feedConversationsNotificationToken: NotificationToken?

    deinit {

        NSNotificationCenter.defaultCenter().removeObserver(self)

        feedConversationsTableView?.delegate = nil

        feedConversationsNotificationToken?.stop()

        println("deinit FeedConversations")
    }

    @objc private func clearUnread(sender: UIBarButtonItem) {

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

        NSNotificationCenter.defaultCenter().postNotificationName(Config.Notification.changedFeedConversation, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        realm = try! Realm()

        title = NSLocalizedString("Feeds", comment: "")

        feedConversationsTableView.rowHeight = 80
        feedConversationsTableView.tableFooterView = UIView()

        feedConversationsNotificationToken = feedConversations.addNotificationBlock({ [weak self] (change: RealmCollectionChange) in
            let predicate = NSPredicate(format: "hasUnreadMessages = true")
            self?.unreadFeedConversations = self?.feedConversations.filter(predicate)
        })

        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKindOfClass(UIScreenEdgePanGestureRecognizer) {
                    feedConversationsTableView.panGestureRecognizer.requireGestureRecognizerToFail(recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FeedConversationsViewController.reloadFeedConversationsTableView), name: Config.Notification.newMessages, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FeedConversationsViewController.reloadFeedConversationsTableView), name: Config.Notification.deletedMessages, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FeedConversationsViewController.reloadFeedConversationsTableView), name: Config.Notification.changedFeedConversation, object: nil)

        if traitCollection.forceTouchCapability == .Available {
            registerForPreviewingWithDelegate(self, sourceView: feedConversationsTableView)
        }
    }

    var isFirstAppear = true
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if !isFirstAppear {
            haveUnreadMessages = countOfUnreadMessagesInRealm(realm, withConversationType: ConversationType.Group) > 0
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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showConversation" {
            let vc = segue.destinationViewController as! ConversationViewController
            let conversation = sender as! Conversation
            prepareConversationViewController(vc, withConversation: conversation)
        }
    }

    private func prepareConversationViewController(vc: ConversationViewController, withConversation conversation: Conversation) {

        vc.conversation = conversation
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension FeedConversationsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedConversations.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        guard let conversation = feedConversations[safe: indexPath.row] else {
            return UITableViewCell()
        }

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

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        guard let conversation = feedConversations[safe: indexPath.row] else {
            return
        }

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

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        guard let conversation = feedConversations[safe: indexPath.row] else {
            return
        }

        performSegueWithIdentifier("showConversation", sender: conversation)
    }

    // Edit (for Delete)

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {

        return true
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {

        guard let conversation = feedConversations[safe: indexPath.row] else {
            fatalError("Invalid index of feedConversations!")
        }

        let title: String = NSLocalizedString("Unsubscribe", comment: "")
        /*
        var title: String = NSLocalizedString("Unsubscribe", comment: "")
        if let feed = conversation.withGroup?.withFeed {
            if feed.deleted {
                title = NSLocalizedString("Delete", comment: "")
            }
            if let creator = feed.creator where creator.isMe {
                title = NSLocalizedString("Delete", comment: "")
            }
        }
        */

        let deleteAction = UITableViewRowAction(style: .Default, title: title) { [weak self] action, indexPath in

            defer {
                tableView.setEditing(false, animated: true)
            }

            guard let conversation = self?.feedConversations[safe: indexPath.row] else {
                return
            }

            guard let feed = conversation.withGroup?.withFeed, feedCreator = feed.creator else {
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
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                tableView.endUpdates()

                // 延迟一些再发通知，避免影响 tableView 的删除
                delay(0.5) {
                    NSNotificationCenter.defaultCenter().postNotificationName(Config.Notification.changedConversation, object: nil)
                }

                deleteSearchableItems(searchableItemType: .Feed, itemIDs: [feedID])
            }

            // 若是创建者，再询问是否删除 Feed

            if feedCreatorID == YepUserDefaults.userID.value {

                YepAlert.confirmOrCancel(title: NSLocalizedString("Delete", comment: ""), message: String.trans_promptAlsoDeleteThisFeed, confirmTitle: NSLocalizedString("Delete", comment: ""), cancelTitle: NSLocalizedString("Not now", comment: ""), inViewController: self, withConfirmAction: {

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

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let indexPath = feedConversationsTableView.indexPathForRowAtPoint(location), cell = feedConversationsTableView.cellForRowAtIndexPath(indexPath) else {
            return nil
        }

        previewingContext.sourceRect = cell.frame

        let vc = UIStoryboard.Scene.conversation
        let conversation = feedConversations[indexPath.row]
        prepareConversationViewController(vc, withConversation: conversation)

        vc.isPreviewed = true

        return vc
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        
        showViewController(viewControllerToCommit, sender: self)
    }
}


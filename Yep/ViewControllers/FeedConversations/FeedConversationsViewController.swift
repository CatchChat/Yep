//
//  FeedConversationsViewController.swift
//  Yep
//
//  Created by nixzhu on 15/10/12.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

class FeedConversationsViewController: SegueViewController {

    @IBOutlet weak var feedConversationsTableView: UITableView!

    var realm: Realm!

    var haveUnreadMessages = false {
        didSet {
            reloadFeedConversationsTableView()
        }
    }

    lazy var feedConversations: Results<Conversation> = {
        return feedConversationsInRealm(self.realm)
    }()

    let feedConversationCellID = "FeedConversationCell"
    let deletedFeedConversationCellID = "DeletedFeedConversationCell"

    deinit {

        NSNotificationCenter.defaultCenter().removeObserver(self)

        feedConversationsTableView?.delegate = nil

        println("deinit FeedConversations")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Feeds", comment: "")

        realm = try! Realm()

        feedConversationsTableView.registerNib(UINib(nibName: feedConversationCellID, bundle: nil), forCellReuseIdentifier: feedConversationCellID)
        feedConversationsTableView.registerNib(UINib(nibName: deletedFeedConversationCellID, bundle: nil), forCellReuseIdentifier: deletedFeedConversationCellID)

        feedConversationsTableView.rowHeight = 80
        feedConversationsTableView.tableFooterView = UIView()
        
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKindOfClass(UIScreenEdgePanGestureRecognizer) {
                    feedConversationsTableView.panGestureRecognizer.requireGestureRecognizerToFail(recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFeedConversationsTableView", name: YepConfig.Notification.newMessages, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFeedConversationsTableView", name: YepConfig.Notification.deletedMessages, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFeedConversationsTableView", name: YepConfig.Notification.changedFeedConversation, object: nil)
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
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.feedConversationsTableView.reloadData()
        }
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showConversation" {
            let vc = segue.destinationViewController as! ConversationViewController
            vc.conversation = sender as! Conversation
        }
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
                let cell = tableView.dequeueReusableCellWithIdentifier(deletedFeedConversationCellID) as! DeletedFeedConversationCell
                return cell

            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier(feedConversationCellID) as! FeedConversationCell
                return cell
            }

        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(feedConversationCellID) as! FeedConversationCell
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

        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? FeedConversationCell {
            performSegueWithIdentifier("showConversation", sender: cell.conversation)
        }
    }

    // Edit (for Delete)

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {

        return true
    }
    
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {

        guard let conversation = feedConversations[safe: indexPath.row] else {
            fatalError("Invalid index of feedConversations!")
        }

        if let feed = conversation.withGroup?.withFeed {
            if feed.deleted {
                return NSLocalizedString("Delete", comment: "")
            }
            if let creator = feed.creator where creator.isMe {
                return NSLocalizedString("Delete", comment: "")
            }
        }

        return NSLocalizedString("Unsubscribe", comment: "")
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if editingStyle == .Delete {
            
            guard let conversation = feedConversations[safe: indexPath.row] else {
                tableView.setEditing(false, animated: true)
                return
            }

            let doDeleteConversation: () -> Void = {
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    guard let realm = conversation.realm else {
                        return
                    }

                    realm.beginWrite()
                    
                    deleteConversation(conversation, inRealm: realm)

                    let _ = try? realm.commitWrite()

                    realm.refresh()

                    delay(0.1) {
                        tableView.setEditing(false, animated: true)
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

                        // 延迟一些再发通知，避免影响 tableView 的删除
                        delay(0.5) {
                            NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.changedConversation, object: nil)
                        }
                    }
                }
            }
            
            guard let feed = conversation.withGroup?.withFeed, feedCreator = feed.creator else {
                return
            }
            
            let feedID = feed.feedID
            let feedCreatorID = feedCreator.userID
            
            // 若是创建者，再询问是否删除 Feed
            
            if feedCreatorID == YepUserDefaults.userID.value {
                
                YepAlert.confirmOrCancel(title: NSLocalizedString("Delete", comment: ""), message: NSLocalizedString("Also delete this feed?", comment: ""), confirmTitle: NSLocalizedString("Delete", comment: ""), cancelTitle: NSLocalizedString("Not now", comment: ""), inViewController: self, withConfirmAction: {
                    
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
    }
}


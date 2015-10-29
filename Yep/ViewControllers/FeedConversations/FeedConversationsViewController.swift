//
//  FeedConversationsViewController.swift
//  Yep
//
//  Created by nixzhu on 15/10/12.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

class FeedConversationsViewController: UIViewController {

    @IBOutlet weak var feedConversationsTableView: UITableView!

    var realm: Realm!

    var haveUnreadMessages = false {
        didSet {
            reloadFeedConversationsTableView()
        }
    }

    lazy var feedConversations: Results<Conversation> = {
        let predicate = NSPredicate(format: "type = %d", ConversationType.Group.rawValue)
        return self.realm.objects(Conversation).filter(predicate).sorted("updatedUnixTime", ascending: false)
        }()

    let feedConversationCellID = "FeedConversationCell"

    deinit {

        println("Deinit FeedConversationsViewControler")

        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Feeds", comment: "")

//        navigationItem.backBarButtonItem?.title = NSLocalizedString("Feeds", comment: "")
        
        realm = try! Realm()

        feedConversationsTableView.registerNib(UINib(nibName: feedConversationCellID, bundle: nil), forCellReuseIdentifier: feedConversationCellID)
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
        dispatch_async(dispatch_get_main_queue()) {
            self.feedConversationsTableView.reloadData()
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
        let cell = tableView.dequeueReusableCellWithIdentifier(feedConversationCellID) as! FeedConversationCell
        if let conversation = feedConversations[safe: indexPath.row] {
            cell.configureWithConversation(conversation)
        }
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? FeedConversationCell {
            performSegueWithIdentifier("showConversation", sender: cell.conversation)
        }
    }

    // Edit (for Delete)

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {

        return true
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if editingStyle == .Delete {

            guard let conversation = feedConversations[safe: indexPath.row] else {
                tableView.setEditing(false, animated: true)
                return
            }

            tryDeleteOrClearHistoryOfConversation(conversation, inViewController: self, whenAfterClearedHistory: { [weak self] in

                tableView.setEditing(false, animated: true)

                // update cell

                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ConversationCell {
                    if let conversation = self?.feedConversations[safe: indexPath.row] {
                        let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5
                        cell.configureWithConversation(conversation, avatarRadius: radius, tableView: tableView, indexPath: indexPath)
                    }
                }

                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.changedConversation, object: nil)
                }

            }, afterDeleted: {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.changedConversation, object: nil)
                }

            }, orCanceled: {
                tableView.setEditing(false, animated: true)
            })
        }
    }
}


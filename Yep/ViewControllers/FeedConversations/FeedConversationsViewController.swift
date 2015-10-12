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
    var realmNotificationToken: NotificationToken?

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

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Feeds"

        realm = try! Realm()

        feedConversationsTableView.registerNib(UINib(nibName: feedConversationCellID, bundle: nil), forCellReuseIdentifier: feedConversationCellID)
        feedConversationsTableView.rowHeight = 80
        feedConversationsTableView.tableFooterView = UIView()

        realmNotificationToken = realm.addNotificationBlock { [weak self] notification, realm in
            if let strongSelf = self {
                strongSelf.haveUnreadMessages = countOfUnreadMessagesInRealm(realm) > 0
            }
        }
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
}


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
}


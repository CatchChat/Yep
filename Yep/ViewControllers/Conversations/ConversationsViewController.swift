//
//  ConversationsViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

class ConversationsViewController: UIViewController {

    @IBOutlet weak var conversationsTableView: UITableView!

    let cellIdentifier = "ConversationCell"

    var realm: Realm!

    lazy var conversations: Results<Conversation> = {
        return self.realm.objects(Conversation).sorted("updatedAt", ascending: false)
        }()


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        realm = Realm()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadConversationsTableView", name: YepNewMessagesReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadConversationsTableView", name: ConversationViewController.Notification.MessageSent, object: nil)

        YepUserDefaults.nickname.bindListener("ConversationsViewController.Nickname") { _ in
            self.reloadConversationsTableView()
        }

        YepUserDefaults.avatarURLString.bindListener("ConversationsViewController.Avatar") { _ in
            self.reloadConversationsTableView()
        }

        view.backgroundColor = UIColor.whiteColor()

        conversationsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        conversationsTableView.rowHeight = 80
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // 这里才开始向用户提示推送
        APService.registerForRemoteNotificationTypes(
            UIUserNotificationType.Badge.rawValue |
            UIUserNotificationType.Sound.rawValue |
            UIUserNotificationType.Alert.rawValue, categories: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showConversation" {
            let vc = segue.destinationViewController as! ConversationViewController
            vc.conversation = sender as! Conversation
        }
    }

    // MARK: Actions

    func reloadConversationsTableView() {
        println("reloadConversationsTableView")
        conversationsTableView.reloadData()
    }
}


extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ConversationCell

        let conversation = conversations[indexPath.row]

        let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5

        cell.configureWithConversation(conversation, avatarRadius: radius)

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ConversationCell {
            performSegueWithIdentifier("showConversation", sender: cell.conversation)
        }
    }
}


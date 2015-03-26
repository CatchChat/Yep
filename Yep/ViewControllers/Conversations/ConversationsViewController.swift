//
//  ConversationsViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Realm
import JPushSDK

class ConversationsViewController: UIViewController {

    @IBOutlet weak var conversationsTableView: UITableView!

    let cellIdentifier = "ConversationCell"

    lazy var conversations = Conversation.allObjects().sortedResultsUsingProperty("updatedAt", ascending: false)

    var updateUIToken: RLMNotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.whiteColor()

        conversationsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        conversationsTableView.rowHeight = 80

        updateUIToken = RLMRealm.defaultRealm().addNotificationBlock { (note, realm) -> Void in
            self.conversationsTableView.reloadData()
        }
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
}


extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(conversations.count)
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ConversationCell

        let conversation = conversations.objectAtIndex(UInt(indexPath.row)) as! Conversation

        let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5

        cell.configureWithConversation(conversation, avatarRadius: radius)

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let conversation = conversations.objectAtIndex(UInt(indexPath.row)) as! Conversation
        performSegueWithIdentifier("showConversation", sender: conversation)
    }
}
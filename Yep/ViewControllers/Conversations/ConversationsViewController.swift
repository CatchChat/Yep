//
//  ConversationsViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ConversationsViewController: UIViewController {

    @IBOutlet weak var conversationsTableView: UITableView!

    let cellIdentifier = "ConversationCell"

    lazy var conversations = Conversation.allObjects()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.whiteColor()

        conversationsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        conversationsTableView.rowHeight = 80
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
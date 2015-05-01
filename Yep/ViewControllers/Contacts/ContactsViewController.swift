//
//  ContactsViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Realm

class ContactsViewController: UIViewController {

    @IBOutlet weak var contactsTableView: UITableView!

    let cellIdentifier = "ContactsCell"

    lazy var friends = normalUsers()

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contactsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        contactsTableView.rowHeight = 80

        YepUserDefaults.nickname.bindListener("ContactsViewController.Nickname") { _ in
            self.reloadContactsTableView()
        }

        YepUserDefaults.avatarURLString.bindListener("ContactsViewController.Avatar") { _ in
            self.reloadContactsTableView()
        }
    }

    func reloadContactsTableView() {
        contactsTableView.reloadData()
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showConversation" {
            let vc = segue.destinationViewController as! ConversationViewController
            vc.conversation = sender as! Conversation
        }
    }
}

extension ContactsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(friends.count)
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell

        let friend = friends.objectAtIndex(UInt(indexPath.row)) as! User

        let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5

        AvatarCache.sharedInstance.roundAvatarOfUser(friend, withRadius: radius) { roundImage in
            dispatch_async(dispatch_get_main_queue()) {
                cell.avatarImageView.image = roundImage
            }
        }

        cell.nameLabel.text = friend.nickname
        cell.joinedDateLabel.text = friend.createdAt.timeAgo
        cell.lastTimeSeenLabel.text = friend.createdAt.timeAgo

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        // 去往聊天界面
        let friend = friends.objectAtIndex(UInt(indexPath.row)) as! User
        if let conversation = friend.conversation {
            performSegueWithIdentifier("showConversation", sender: conversation)

        } else {
            let newConversation = Conversation()

            newConversation.type = ConversationType.OneToOne.rawValue
            newConversation.withFriend = friend

            let realm = RLMRealm.defaultRealm()

            realm.beginWriteTransaction()
            realm.addObject(newConversation)
            realm.commitWriteTransaction()

            performSegueWithIdentifier("showConversation", sender: newConversation)
        }
    }
}
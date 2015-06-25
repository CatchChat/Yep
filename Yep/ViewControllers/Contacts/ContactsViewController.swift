//
//  ContactsViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

class ContactsViewController: BaseViewController {

    @IBOutlet weak var contactsTableView: UITableView!

    let cellIdentifier = "ContactsCell"

    lazy var friends = normalUsers()

    struct Listener {
        static let Nickname = "ContactsViewController.Nickname"
        static let Avatar = "ContactsViewController.Avatar"
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)

        YepUserDefaults.avatarURLString.removeListenerWithName(Listener.Avatar)
        YepUserDefaults.nickname.removeListenerWithName(Listener.Nickname)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "syncFriendships", name: FriendsInContactsViewController.Notification.NewFriends, object: nil)

        contactsTableView.separatorColor = UIColor.yepCellSeparatorColor()
        contactsTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        contactsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        contactsTableView.rowHeight = 80
        contactsTableView.tableFooterView = UIView()

        YepUserDefaults.nickname.bindListener(Listener.Nickname) { [unowned self] _ in
            self.updateContactsTableView()
        }

        YepUserDefaults.avatarURLString.bindListener(Listener.Avatar) { [unowned self] _ in
            self.updateContactsTableView()
        }
    }

    // MARK: Actions

    func updateContactsTableView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.contactsTableView.reloadData()
        }
    }

    func syncFriendships() {
        syncFriendshipsAndDoFurtherAction {
            dispatch_async(dispatch_get_main_queue()) {
                self.updateContactsTableView()
            }
        }
    }

    @IBAction func presentAddFriends(sender: UIBarButtonItem) {
        performSegueWithIdentifier("presentAddFriends", sender: nil)
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showProfile" {
            let vc = segue.destinationViewController as! ProfileViewController

            if let user = sender as? User {
                if user.userID != YepUserDefaults.userID.value {
                    vc.profileUser = ProfileUser.UserType(user)
                }
            }

            vc.hidesBottomBarWhenPushed = true
            
            vc.setBackButtonWithTitle()
        }
    }
}

extension ContactsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(friends.count)
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell

        let friend = friends[indexPath.row]

        let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5

        AvatarCache.sharedInstance.roundAvatarOfUser(friend, withRadius: radius) { [unowned self] roundImage in
            dispatch_async(dispatch_get_main_queue()) {
                cell.avatarImageView.image = roundImage
            }
        }

        cell.nameLabel.text = friend.nickname
        cell.joinedDateLabel.text = friend.introduction
        cell.lastTimeSeenLabel.text = NSDate(timeIntervalSince1970: friend.createdUnixTime).timeAgo

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        // 去往 Profile
        let friend = friends[indexPath.row]
        performSegueWithIdentifier("showProfile", sender: friend)
   }
}
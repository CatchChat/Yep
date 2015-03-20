//
//  ContactsViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ContactsViewController: UIViewController {

    @IBOutlet weak var contactsTableView: UITableView!

    let cellIdentifier = "ContactsCell"

    lazy var friends = User.allObjects()

    override func viewDidLoad() {
        super.viewDidLoad()

        contactsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        contactsTableView.rowHeight = 80
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
        cell.joinedDateLabel.text = "\(friend.createdAt)"
        cell.lastTimeSeenLabel.text = "\(friend.createdAt)"

        return cell
    }
}
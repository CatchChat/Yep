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

    lazy var dataSource = [
        [
            "name": "Lucy",
            "imageName": "scarlett",
            "chatContent": "I feel everything.",
            "timeAgo": "A million years ago",
        ],
        [
            "name": "Jony",
            "imageName": "jony",
            "chatContent": "I designed iPhone.",
            "timeAgo": "10 years ago",
        ],
        [
            "name": "Robert",
            "imageName": "robert",
            "chatContent": "I'm Iron Man.",
            "timeAgo": "A few years ago",
        ],
        [
            "name": "NIX",
            "imageName": "nixzhu",
            "chatContent": "I love Iron Man!",
            "timeAgo": "5 minutes ago",
        ],
        [
            "name": "Kevin",
            "imageName": "kevin",
            "chatContent": "I'm CEO.\nBitch!",
            "timeAgo": "Now",
        ],
        [
            "name": "Faceless",
            "imageName": "faceless",
            "chatContent": "Valar Morghulis, valar dohaeris.",
            "timeAgo": "Some day",
        ],
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.whiteColor()

        conversationsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        conversationsTableView.rowHeight = 80

        // for test
        unreadMessages { result in
            println("unreadMessages result: \(result)")
        }

        syncFriendshipsAndDoFurtherAction {
            for obj in User.allObjects() {
                println(obj.description)
            }
        }

        groups { result in
            println("groups: \(result)")
        }

    }
}


extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 15
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ConversationCell

        let dic = dataSource[indexPath.row % dataSource.count]

        let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5
        cell.avatarImageView.image = AvatarCache.sharedInstance.roundImageNamed(dic["imageName"]!, ofRadius: radius)
        cell.nameLabel.text = dic["name"]
        cell.chatLabel.text = dic["chatContent"]
        cell.timeAgoLabel.text = dic["timeAgo"]

        return cell
    }
}
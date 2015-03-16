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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.whiteColor()

        conversationsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        conversationsTableView.rowHeight = 80
    }
}

extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 15
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ConversationCell

        if indexPath.row % 5 == 0 {
            cell.avatarImageView.image = UIImage(named: "scarlett")
            cell.nameLabel.text = "Lucy"
            cell.chatLabel.text = "I feel everything."
            cell.timeAgoLabel.text = "A million years ago"
        } else if indexPath.row % 5 == 1 {
            cell.avatarImageView.image = UIImage(named: "jony")
            cell.nameLabel.text = "Jony"
            cell.chatLabel.text = "I designed iPhone."
            cell.timeAgoLabel.text = "10 years ago"
        } else if indexPath.row % 5 == 2 {
            cell.avatarImageView.image = UIImage(named: "robert")
            cell.nameLabel.text = "Robert"
            cell.chatLabel.text = "I'm Iron Man."
            cell.timeAgoLabel.text = "A few years ago"
        } else if indexPath.row % 5 == 3 {
            cell.avatarImageView.image = UIImage(named: "nixzhu")
            cell.nameLabel.text = "Nix"
            cell.chatLabel.text = "I love Iron Man!"
            cell.timeAgoLabel.text = "5 minutes ago"
        } else {
            cell.avatarImageView.image = UIImage(named: "kevin")
            cell.nameLabel.text = "Kevin"
            cell.chatLabel.text = "I'm CEO.\nBitch!"
            cell.timeAgoLabel.text = "Now"
        }

        return cell
    }
}
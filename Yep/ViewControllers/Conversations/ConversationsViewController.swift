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

    lazy var dataSource: [[String: AnyObject]] = {

        var _dataSource: [[String: AnyObject]] = [
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
                "name": "Nix",
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
        ]

        for i in 0..<_dataSource.count {
            var dic = _dataSource[i]

            if let image = UIImage(named: dic["imageName"]! as! String) {
                UIGraphicsBeginImageContext(image.size)

                let context = UIGraphicsGetCurrentContext()

                var transform = CGAffineTransformConcat(CGAffineTransformIdentity, CGAffineTransformMakeScale(1.0, -1.0))
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0.0, image.size.height))
                CGContextConcatCTM(context, transform)

                let drawRect = CGRect(origin: CGPointZero, size: image.size)

                CGContextAddEllipseInRect(context, drawRect.largestCenteredSquare())
                CGContextClip(context)

                CGContextDrawImage(context, drawRect, image.CGImage)

                let finalImage = UIGraphicsGetImageFromCurrentImageContext()

                UIGraphicsEndImageContext()

                dic["roundImage"] = finalImage

                _dataSource[i] = dic
            }
        }

        return _dataSource
    }()

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

        let dic = dataSource[indexPath.row % dataSource.count]

        cell.avatarImageView.image = dic["roundImage"] as? UIImage
        cell.nameLabel.text = dic["name"] as? String
        cell.chatLabel.text = dic["chatContent"] as? String
        cell.timeAgoLabel.text = dic["timeAgo"] as? String

        return cell
    }
}
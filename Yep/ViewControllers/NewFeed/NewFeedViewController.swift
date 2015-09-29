//
//  NewFeedViewController.swift
//  Yep
//
//  Created by nixzhu on 15/9/29.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class NewFeedViewController: UIViewController {

    @IBOutlet weak var messageTextView: UITextView!

    @IBOutlet weak var mediaCollectionView: UICollectionView!


    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("New Feed", comment: "")

        let postButton = UIBarButtonItem(title: NSLocalizedString("Post", comment: ""), style: .Plain, target: self, action: "post:")

        navigationItem.rightBarButtonItem = postButton

        messageTextView.text = "What's up?"

        messageTextView.backgroundColor = UIColor.lightGrayColor()
        mediaCollectionView.backgroundColor = UIColor.blueColor()
    }

    // MARK: Actions

    func post(sender: UIBarButtonItem) {
        println("post")
    }
}


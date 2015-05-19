//
//  AddFriendsViewController.swift
//  Yep
//
//  Created by NIX on 15/5/19.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class AddFriendsViewController: UIViewController {

    @IBOutlet weak var addFriendsTableView: UITableView!

    let addFriendSearchCellIdentifier = "AddFriendSearchCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Add Friends", comment: "")


        addFriendsTableView.registerNib(UINib(nibName: addFriendSearchCellIdentifier, bundle: nil), forCellReuseIdentifier: addFriendSearchCellIdentifier)
    }

    // MARK: Actions
    
    @IBAction func done(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
        // TODO: done add friend
    }
}

extension AddFriendsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(addFriendSearchCellIdentifier) as! AddFriendSearchCell
        return cell
    }
}
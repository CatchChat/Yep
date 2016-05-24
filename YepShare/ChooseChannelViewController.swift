//
//  ChooseChannelViewController.swift
//  Yep
//
//  Created by NIX on 16/5/24.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class ChooseChannelViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Choose Channel"
    }

    // MARK: - Actions

    @IBAction func cancel(sender: UIBarButtonItem) {

        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func done(sender: UIBarButtonItem) {

        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("ChannelCell", forIndexPath: indexPath)
        cell.textLabel?.text = "Title \(indexPath.row)"
        return cell
    }
}


//
//  AboutViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/28.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var aboutTableView: UITableView!
    @IBOutlet weak var aboutTableViewHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("About", comment: "")
    }
}

extension AboutViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
}
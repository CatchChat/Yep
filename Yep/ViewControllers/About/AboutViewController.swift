//
//  AboutViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/28.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var appLogoImageView: UIImageView!
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var appVersionLabel: UILabel!
    
    @IBOutlet weak var aboutTableView: UITableView!
    @IBOutlet weak var aboutTableViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var copyrightLabel: UILabel!

    let aboutCellID = "AboutCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("About", comment: "")

        aboutTableView.registerNib(UINib(nibName: aboutCellID, bundle: nil), forCellReuseIdentifier: aboutCellID)

        let rowHeight: CGFloat = 60
        aboutTableView.rowHeight = rowHeight

        aboutTableViewHeightConstraint.constant = rowHeight * 3
    }
}

extension AboutViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(aboutCellID) as! AboutCell
        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
}

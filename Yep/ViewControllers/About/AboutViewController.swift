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

    let rowHeight: CGFloat = 60

    let aboutAnnotations: [String] = [
        NSLocalizedString("Pods help Yep", comment: ""),
        NSLocalizedString("Rate Yep on App Store", comment: ""),
        NSLocalizedString("Terms of Service", comment: ""),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("About", comment: "")

        aboutTableView.registerNib(UINib(nibName: aboutCellID, bundle: nil), forCellReuseIdentifier: aboutCellID)

        aboutTableViewHeightConstraint.constant = rowHeight * CGFloat(aboutAnnotations.count) + 1
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension AboutViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return aboutAnnotations.count + 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        switch indexPath.row {
        case 0:
            return UITableViewCell()
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier(aboutCellID) as! AboutCell
            let annotation = aboutAnnotations[indexPath.row - 1]
            cell.annotationLabel.text = annotation
            return cell
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 1
        default:
            return rowHeight
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        switch indexPath.row {
        case 3:
            UIApplication.sharedApplication().openURL(NSURL(string: YepConfig.termsURLString)!)
        default:
            break
        }
    }
}


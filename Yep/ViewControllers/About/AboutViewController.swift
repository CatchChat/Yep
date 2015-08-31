//
//  AboutViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/28.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class AboutViewController: UIViewController {

    @IBOutlet weak var appLogoImageView: UIImageView!
    @IBOutlet weak var appLogoImageViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var appNameLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var appVersionLabel: UILabel!
    
    @IBOutlet weak var aboutTableView: UITableView!
    @IBOutlet weak var aboutTableViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var copyrightLabel: UILabel!

    let aboutCellID = "AboutCell"

    let rowHeight: CGFloat = Ruler.match(.iPhoneHeights(50, 60, 60, 60))

    let aboutAnnotations: [String] = [
        NSLocalizedString("Pods help Yep", comment: ""),
        NSLocalizedString("Rate Yep on App Store", comment: ""),
        NSLocalizedString("Terms of Service", comment: ""),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("About", comment: "")

        appLogoImageViewTopConstraint.constant = Ruler.match(.iPhoneHeights(0, 20, 40, 60))
        appNameLabelTopConstraint.constant = Ruler.match(.iPhoneHeights(10, 20, 20, 20))

        appNameLabel.textColor = UIColor.yepTintColor()

        if let
            releaseVersionNumber = NSBundle.releaseVersionNumber,
            buildVersionNumber = NSBundle.buildVersionNumber {
                appVersionLabel.text = NSLocalizedString("Version", comment: "") + " " + releaseVersionNumber + " (\(buildVersionNumber))"
        }

        aboutTableView.registerNib(UINib(nibName: aboutCellID, bundle: nil), forCellReuseIdentifier: aboutCellID)

        aboutTableViewHeightConstraint.constant = rowHeight * CGFloat(aboutAnnotations.count) + 1
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension AboutViewController: UITableViewDataSource, UITableViewDelegate {

    enum Row: Int {
        case Pods = 1
        case Rate
        case Terms
    }

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
        case Row.Pods.rawValue:
            performSegueWithIdentifier("showPodsHelpYep", sender: nil)
        case Row.Rate.rawValue:
            UIApplication.sharedApplication().openURL(NSURL(string: YepConfig.appURLString)!)
        case Row.Terms.rawValue:
            UIApplication.sharedApplication().openURL(NSURL(string: YepConfig.termsURLString)!)
        default:
            break
        }
    }
}


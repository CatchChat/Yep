//
//  AboutViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/28.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepConfig
import Ruler

final class AboutViewController: SegueViewController {

    @IBOutlet private weak var appLogoImageView: UIImageView!
    @IBOutlet private weak var appLogoImageViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var appNameLabel: UILabel!
    @IBOutlet private weak var appNameLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var appVersionLabel: UILabel!
    
    @IBOutlet private weak var aboutTableView: UITableView!
    @IBOutlet private weak var aboutTableViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet private weak var copyrightLabel: UILabel!

    private let aboutCellID = "AboutCell"

    private let rowHeight: CGFloat = Ruler.iPhoneVertical(50, 60, 60, 60).value

    private let aboutAnnotations: [String] = [
        NSLocalizedString("Pods helps Yep", comment: ""),
        NSLocalizedString("Rate Yep on App Store", comment: ""),
        NSLocalizedString("Terms of Service", comment: ""),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("About", comment: "")

        appLogoImageViewTopConstraint.constant = Ruler.iPhoneVertical(0, 20, 40, 60).value
        appNameLabelTopConstraint.constant = Ruler.iPhoneVertical(10, 20, 20, 20).value

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

    private enum Row: Int {
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

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        switch indexPath.row {
        case Row.Pods.rawValue:
            performSegueWithIdentifier("showPodsHelpYep", sender: nil)
        case Row.Rate.rawValue:
            UIApplication.sharedApplication().openURL(NSURL(string: YepConfig.appURLString)!)
        case Row.Terms.rawValue:
            if let URL = NSURL(string: YepConfig.termsURLString) {
                yep_openURL(URL)
            }
        default:
            break
        }
    }
}


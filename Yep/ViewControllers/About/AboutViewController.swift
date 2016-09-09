//
//  AboutViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/28.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler
import MonkeyKing

final class AboutViewController: SegueViewController {

    @IBOutlet private weak var appLogoImageView: UIImageView!
    @IBOutlet private weak var appLogoImageViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var appNameLabel: UILabel!
    @IBOutlet private weak var appNameLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var appVersionLabel: UILabel!
    
    @IBOutlet private weak var aboutTableView: UITableView! {
        didSet {
            aboutTableView.registerNibOf(AboutCell)
        }
    }
    @IBOutlet private weak var aboutTableViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet private weak var copyrightLabel: UILabel!

    private let rowHeight: CGFloat = Ruler.iPhoneVertical(45, 50, 55, 60).value

    private let aboutAnnotations: [String] = [
        String.trans_aboutOpenSourceOfYep,
        NSLocalizedString("Review Yep on the App Store", comment: ""),
        String.trans_aboutRecommendYep,
        NSLocalizedString("Terms of Service", comment: ""),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleAbout

        appLogoImageViewTopConstraint.constant = Ruler.iPhoneVertical(0, 20, 40, 60).value
        appNameLabelTopConstraint.constant = Ruler.iPhoneVertical(10, 20, 20, 20).value

        let motionEffect = UIMotionEffect.yep_twoAxesShift(Ruler.iPhoneHorizontal(30, 40, 50).value)
        appLogoImageView.addMotionEffect(motionEffect)
        appNameLabel.addMotionEffect(motionEffect)
        appVersionLabel.addMotionEffect(motionEffect)

        appNameLabel.textColor = UIColor.yepTintColor()

        if let
            releaseVersionNumber = NSBundle.releaseVersionNumber,
            buildVersionNumber = NSBundle.buildVersionNumber {
                appVersionLabel.text = NSLocalizedString("Version", comment: "") + " " + releaseVersionNumber + " (\(buildVersionNumber))"
        }

        aboutTableViewHeightConstraint.constant = rowHeight * CGFloat(aboutAnnotations.count) + 1
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension AboutViewController: UITableViewDataSource, UITableViewDelegate {

    private enum Row: Int {
        case Pods = 1
        case Review
        case Share
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
            let cell: AboutCell = tableView.dequeueReusableCell()
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

        case Row.Review.rawValue:
            UIApplication.sharedApplication().yep_reviewOnTheAppStore()

        case Row.Share.rawValue:
            let yepURL = NSURL(string: "https://soyep.com")!
            let info = MonkeyKing.Info(
                title: "Yep",
                description: String.trans_aboutYepDescription,
                thumbnail: UIImage.yep_yepIconSolo,
                media: .URL(yepURL)
            )
            self.yep_share(info: info, defaultActivityItem: yepURL, description: String.trans_aboutYepDescription)

        case Row.Terms.rawValue:
            if let URL = NSURL(string: YepConfig.termsURLString) {
                yep_openURL(URL)
            }

        default:
            break
        }
    }
}


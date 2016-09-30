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

    @IBOutlet fileprivate weak var appLogoImageView: UIImageView!
    @IBOutlet fileprivate weak var appLogoImageViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet fileprivate weak var appNameLabel: UILabel!
    @IBOutlet fileprivate weak var appNameLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var appVersionLabel: UILabel!
    
    @IBOutlet fileprivate weak var aboutTableView: UITableView! {
        didSet {
            aboutTableView.registerNibOf(AboutCell.self)
        }
    }
    @IBOutlet fileprivate weak var aboutTableViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet fileprivate weak var copyrightLabel: UILabel!

    fileprivate let rowHeight: CGFloat = Ruler.iPhoneVertical(45, 50, 55, 60).value

    fileprivate let aboutAnnotations: [String] = [
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
            releaseVersionNumber = Bundle.releaseVersionNumber,
            let buildVersionNumber = Bundle.buildVersionNumber {
                appVersionLabel.text = NSLocalizedString("Version", comment: "") + " " + releaseVersionNumber + " (\(buildVersionNumber))"
        }

        aboutTableViewHeightConstraint.constant = rowHeight * CGFloat(aboutAnnotations.count) + 1
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension AboutViewController: UITableViewDataSource, UITableViewDelegate {

    fileprivate enum Row: Int {
        case pods = 1
        case review
        case share
        case terms
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return aboutAnnotations.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

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

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 1
        default:
            return rowHeight
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        switch indexPath.row {

        case Row.pods.rawValue:
            performSegue(withIdentifier: "showPodsHelpYep", sender: nil)

        case Row.review.rawValue:
            UIApplication.shared.yep_reviewOnTheAppStore()

        case Row.share.rawValue:
            let yepURL = URL(string: "https://soyep.com")!
            let info = MonkeyKing.Info(
                title: "Yep",
                description: String.trans_aboutYepDescription,
                thumbnail: UIImage.yep_yepIconSolo,
                media: .url(yepURL)
            )
            self.yep_share(info: info, defaultActivityItem: yepURL, description: String.trans_aboutYepDescription)

        case Row.terms.rawValue:
            if let URL = URL(string: YepConfig.termsURLString) {
                yep_openURL(URL)
            }

        default:
            break
        }
    }
}


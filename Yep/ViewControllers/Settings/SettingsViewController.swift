//
//  SettingsViewController.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SettingsViewController: BaseViewController {

    @IBOutlet weak var settingsTableView: UITableView!

    let settingsUserCellIdentifier = "SettingsUserCell"
    let settingsMoreCellIdentifier = "SettingsMoreCell"

    var introduction: String {
        get {
            return YepUserDefaults.introduction.value ?? NSLocalizedString("No Introduction yet.", comment: "")
        }
    }

    let moreAnnotations: [String] = [
        NSLocalizedString("Notifications", comment: ""),
        NSLocalizedString("Feedback", comment: ""),
        NSLocalizedString("About", comment: ""),
    ]

    let introAttributes = [NSFontAttributeName: YepConfig.Settings.introFont]

    struct Listener {
        static let Introduction = "SettingsViewController.Introduction"
    }

    deinit {
        YepUserDefaults.introduction.removeListenerWithName(Listener.Introduction)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        animatedOnNavigationBar = false

        title = NSLocalizedString("Settings", comment: "")

        settingsTableView.registerNib(UINib(nibName: settingsUserCellIdentifier, bundle: nil), forCellReuseIdentifier: settingsUserCellIdentifier)
        settingsTableView.registerNib(UINib(nibName: settingsMoreCellIdentifier, bundle: nil), forCellReuseIdentifier: settingsMoreCellIdentifier)

        YepUserDefaults.introduction.bindAndFireListener(Listener.Introduction) { [weak self] introduction in
            self?.settingsTableView.reloadData()
        }
    }

}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {

    enum Section: Int {
        case User = 0
        case More
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.User.rawValue:
            return 1
        case Section.More.rawValue:
            return moreAnnotations.count
        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {

        case Section.User.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(settingsUserCellIdentifier) as! SettingsUserCell
            return cell

        case Section.More.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(settingsMoreCellIdentifier) as! SettingsMoreCell
            cell.annotationLabel.text = moreAnnotations[indexPath.row]
            return cell

        default:
            return UITableViewCell()
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {

        case Section.User.rawValue:

            let tableViewWidth = CGRectGetWidth(settingsTableView.bounds)
            let introLabelMaxWidth = tableViewWidth - YepConfig.Settings.introInset

            let rect = introduction.boundingRectWithSize(CGSize(width: introLabelMaxWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: introAttributes, context: nil)

            let height = max(20 + 8 + 22 + 8 + ceil(rect.height) + 20, 20 + YepConfig.Settings.userCellAvatarSize + 20)

            return height

        case Section.More.rawValue:
            return 60

        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        switch indexPath.section {

        case Section.User.rawValue:
            performSegueWithIdentifier("showEditProfile", sender: nil)

        default:
            break
        }
    }
}


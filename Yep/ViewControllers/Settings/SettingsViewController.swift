//
//  SettingsViewController.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class SettingsViewController: BaseViewController {

    @IBOutlet private weak var settingsTableView: UITableView! {
        didSet {
            settingsTableView.registerNibOf(SettingsUserCell)
            settingsTableView.registerNibOf(SettingsMoreCell)
            settingsTableView.registerClassOf(TitleSwitchCell)
        }
    }

    private var introduction: String {
        get {
            return YepUserDefaults.introduction.value ?? String.trans_promptNoSelfIntroduction
        }
    }

    struct Annotation {
        let name: String
        let segue: String
    }

    private let moreAnnotations: [Annotation] = [
        Annotation(
            name: String.trans_titleNotificationsAndPrivacy,
            segue: "showNotifications"
        ),
        Annotation(
            name: String.trans_titleFeedback,
            segue: "showFeedback"
        ),
        Annotation(
            name: String.trans_titleAbout,
            segue: "showAbout"
        ),
    ]

    private let introAttributes = [NSFontAttributeName: YepConfig.Settings.introFont]

    private struct Listener {
        static let Introduction = "SettingsViewController.Introduction"
    }

    deinit {
        YepUserDefaults.introduction.removeListenerWithName(Listener.Introduction)

        settingsTableView?.delegate = nil

        println("deinit Settings")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Settings", comment: "")

        YepUserDefaults.introduction.bindAndFireListener(Listener.Introduction) { [weak self] introduction in
            SafeDispatch.async {
                self?.settingsTableView.reloadData()
            }
        }
        
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKindOfClass(UIScreenEdgePanGestureRecognizer) {
                    settingsTableView.panGestureRecognizer.requireGestureRecognizerToFail(recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {

    private enum Section: Int {
        case User
        case UI
        case More

        static let count = 3
    }

    private enum UIRow: Int {
        case TabBarTitleEnabled
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Section.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError("Invalide section!")
        }

        switch section {
        case .User:
            return 1
        case .UI:
            return 1
        case .More:
            return moreAnnotations.count
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalide section!")
        }

        switch section {

        case .User:
            let cell: SettingsUserCell = tableView.dequeueReusableCell()
            return cell

        case .UI:
            guard let row = UIRow(rawValue: indexPath.row) else {
                fatalError("Invalide row!")
            }

            switch row {
            case .TabBarTitleEnabled:
                let cell: TitleSwitchCell = tableView.dequeueReusableCell()
                cell.titleLabel.text = NSLocalizedString("Show Tab Bar Title", comment: "")
                cell.toggleSwitch.on = YepUserDefaults.tabBarItemTextEnabled.value ?? !(YepUserDefaults.appLaunchCount.value > YepUserDefaults.appLaunchCountThresholdForTabBarItemTextEnabled)
                cell.toggleSwitchStateChangedAction = { on in
                    YepUserDefaults.tabBarItemTextEnabled.value = on
                }
                return cell
            }

        case .More:
            let cell: SettingsMoreCell = tableView.dequeueReusableCell()
            let annotation = moreAnnotations[indexPath.row]
            cell.annotationLabel.text = annotation.name
            return cell
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalide section!")
        }

        switch section {

        case .User:

            let tableViewWidth = CGRectGetWidth(settingsTableView.bounds)
            let introLabelMaxWidth = tableViewWidth - YepConfig.Settings.introInset

            let rect = introduction.boundingRectWithSize(CGSize(width: introLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: introAttributes, context: nil)

            let height = max(20 + 8 + 22 + 8 + ceil(rect.height) + 20, 20 + YepConfig.Settings.userCellAvatarSize + 20)

            return height

        case .UI:
            return 60

        case .More:
            return 60
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalide section!")
        }

        switch section {

        case .User:
            performSegueWithIdentifier("showEditProfile", sender: nil)

        case .UI:
            break

        case .More:
            let annotation = moreAnnotations[indexPath.row]
            let segue = annotation.segue
            performSegueWithIdentifier(segue, sender: nil)
        }
    }
}


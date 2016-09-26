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

    @IBOutlet fileprivate weak var settingsTableView: UITableView! {
        didSet {
            settingsTableView.registerNibOf(SettingsUserCell.self)
            settingsTableView.registerNibOf(SettingsMoreCell.self)
            settingsTableView.registerClassOf(TitleSwitchCell.self)
        }
    }

    fileprivate var introduction: String {
        get {
            return YepUserDefaults.introduction.value ?? String.trans_promptNoSelfIntroduction
        }
    }

    struct Annotation {
        let name: String
        let segue: String
    }

    fileprivate let moreAnnotations: [Annotation] = [
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

    fileprivate let introAttributes = [NSFontAttributeName: YepConfig.Settings.introFont]

    fileprivate struct Listener {
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
                if recognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) {
                    settingsTableView.panGestureRecognizer.require(toFail: recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {

    fileprivate enum Section: Int {
        case user
        case ui
        case more

        static let count = 3
    }

    fileprivate enum UIRow: Int {
        case tabBarTitleEnabled
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError("Invalide section!")
        }

        switch section {
        case .user:
            return 1
        case .ui:
            return 1
        case .more:
            return moreAnnotations.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            fatalError("Invalide section!")
        }

        switch section {

        case .user:
            let cell: SettingsUserCell = tableView.dequeueReusableCell()
            return cell

        case .ui:
            guard let row = UIRow(rawValue: (indexPath as NSIndexPath).row) else {
                fatalError("Invalide row!")
            }

            switch row {
            case .tabBarTitleEnabled:
                let cell: TitleSwitchCell = tableView.dequeueReusableCell()
                cell.titleLabel.text = NSLocalizedString("Show Tab Bar Title", comment: "")
                cell.toggleSwitch.isOn = YepUserDefaults.tabBarItemTextEnabled.value ?? !(YepUserDefaults.appLaunchCount.value > YepUserDefaults.appLaunchCountThresholdForTabBarItemTextEnabled)
                cell.toggleSwitchStateChangedAction = { on in
                    YepUserDefaults.tabBarItemTextEnabled.value = on
                }
                return cell
            }

        case .more:
            let cell: SettingsMoreCell = tableView.dequeueReusableCell()
            let annotation = moreAnnotations[(indexPath as NSIndexPath).row]
            cell.annotationLabel.text = annotation.name
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            fatalError("Invalide section!")
        }

        switch section {

        case .user:

            let tableViewWidth = settingsTableView.bounds.width
            let introLabelMaxWidth = tableViewWidth - YepConfig.Settings.introInset

            let rect = introduction.boundingRect(with: CGSize(width: introLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: introAttributes, context: nil)

            let height = max(20 + 8 + 22 + 8 + ceil(rect.height) + 20, 20 + YepConfig.Settings.userCellAvatarSize + 20)

            return height

        case .ui:
            return 60

        case .more:
            return 60
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            fatalError("Invalide section!")
        }

        switch section {

        case .user:
            performSegue(withIdentifier: "showEditProfile", sender: nil)

        case .ui:
            break

        case .more:
            let annotation = moreAnnotations[(indexPath as NSIndexPath).row]
            let segue = annotation.segue
            performSegue(withIdentifier: segue, sender: nil)
        }
    }
}


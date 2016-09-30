//
//  NotificationsViewController.swift
//  Yep
//
//  Created by NIX on 15/8/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import RealmSwift

struct DoNotDisturbPeriod {
    var isOn: Bool = false

    var fromHour: Int = 22
    var fromMinute: Int = 0

    var toHour: Int = 7
    var toMinute: Int = 30

    var hourOffset: Int {
        let localTimeZone = TimeZone.autoupdatingCurrent
        let totalSecondsOffset = localTimeZone.secondsFromGMT()

        let hourOffset = totalSecondsOffset / (60 * 60)

        return hourOffset
    }

    var minuteOffset: Int {
        let localTimeZone = TimeZone.autoupdatingCurrent
        let totalSecondsOffset = localTimeZone.secondsFromGMT()

        let hourOffset = totalSecondsOffset / (60 * 60)
        let minuteOffset = (totalSecondsOffset - hourOffset * (60 * 60)) / 60

        return minuteOffset
    }

    func serverStringWithHour(_ hour: Int, minute: Int) -> String {
        if minute - minuteOffset >= 0 {
            return String(format: "%02d:%02d", (hour - hourOffset + 24) % 24, (minute - minuteOffset) % 60)
        } else {
            return String(format: "%02d:%02d", (hour - hourOffset - 1 + 24) % 24, ((minute + 60) - minuteOffset) % 60)
        }
    }

    var serverFromString: String {
        return serverStringWithHour(fromHour, minute: fromMinute)
    }

    var serverToString: String {
        return serverStringWithHour(toHour, minute: toMinute)
    }

    var localFromString: String {
        return String(format: "%02d:%02d", fromHour, fromMinute)
    }

    var localToString: String {
        return String(format: "%02d:%02d", toHour, toMinute)
    }
}

final class NotificationsViewController: SegueViewController {

    @IBOutlet fileprivate weak var tableView: UITableView! {
        didSet {
            tableView.registerNibOf(DoNotDisturbSwitchCell.self)
            tableView.registerNibOf(DoNotDisturbPeriodCell.self)
            tableView.registerNibOf(SettingsMoreCell.self)

            tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }
    }

    fileprivate var doNotDisturbPeriod = DoNotDisturbPeriod() {
        didSet {
            SafeDispatch.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleNotificationsAndPrivacy

        if let me = me(), let userDoNotDisturb = me.doNotDisturb {

            doNotDisturbPeriod.isOn = userDoNotDisturb.isOn

            doNotDisturbPeriod.fromHour = userDoNotDisturb.fromHour
            doNotDisturbPeriod.fromMinute = userDoNotDisturb.fromMinute

            doNotDisturbPeriod.toHour = userDoNotDisturb.toHour
            doNotDisturbPeriod.toMinute = userDoNotDisturb.toMinute
        }
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "showDoNotDisturbPeriod" {
            let vc = segue.destination as! DoNotDisturbPeriodViewController

            vc.doNotDisturbPeriod = doNotDisturbPeriod

            vc.dirtyAction = { [weak self] doNotDisturbPeriod in
                self?.doNotDisturbPeriod = doNotDisturbPeriod
            }
        }
    }

    // MARK: Actions

    fileprivate func enableDoNotDisturb(failed: @escaping () -> Void) {

        guard let realm = try? Realm() else {
            return
        }

        guard let me = meInRealm(realm) else {
            return
        }

        // create
        if me.doNotDisturb == nil {
            let _userDoNotDisturb = UserDoNotDisturb()

            let _ = try? realm.write {
                me.doNotDisturb = _userDoNotDisturb
            }
        }

        guard let userDoNotDisturb = me.doNotDisturb else {
            return
        }

        let info: JSONDictionary = [
            "mute_started_at_string": userDoNotDisturb.serverFromString,
            "mute_ended_at_string": userDoNotDisturb.serverToString,
        ]

        updateMyselfWithInfo(info, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

            YepAlert.alertSorry(message: String.trans_promptEnableDoNotDisturbFailed, inViewController: self)

            failed()

        }, completion: { success in

            SafeDispatch.async {

                guard let realm = try? Realm() else {
                    return
                }

                if let me = meInRealm(realm) {
                    let _ = try? realm.write {
                        me.doNotDisturb?.isOn = true
                    }
                }
            }
        })
    }

    fileprivate func disableDoNotDisturb(failed: @escaping () -> Void) {

        guard let me = me() else {
            return
        }

        if let _ = me.doNotDisturb {

            let info: JSONDictionary = [
                "mute_started_at_string": "",
                "mute_ended_at_string": "",
            ]

            updateMyselfWithInfo(info, failureHandler: { [weak self] (reason, errorMessage) in
                defaultFailureHandler(reason, errorMessage)

                YepAlert.alertSorry(message: String.trans_promptDisableDoNotDisturbFailed, inViewController: self)

                failed()

            }, completion: { success in

                SafeDispatch.async { [weak self] in

                    // clean UI
                    self?.doNotDisturbPeriod = DoNotDisturbPeriod()

                    guard let realm = try? Realm() else {
                        return
                    }

                    if let me = meInRealm(realm), let userDoNotDisturb = me.doNotDisturb {
                        let _ = try? realm.write {
                            realm.delete(userDoNotDisturb)
                        }
                    }
                }
            })
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {

    enum Section: Int {
        case doNotDisturbPeriod
        case blackList
        case creatorsOfBlockedFeeds
    }

    fileprivate enum DoNotDisturbPeriodRow: Int {
        case `switch`
        case period
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError("Invalid Section!")
        }

        switch section {
        case .doNotDisturbPeriod:
            return doNotDisturbPeriod.isOn ? 2 : 1
        case .blackList:
            return 1
        case .creatorsOfBlockedFeeds:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section!")
        }

        switch section {

        case .doNotDisturbPeriod:

            switch indexPath.row {

            case DoNotDisturbPeriodRow.switch.rawValue:

                let cell: DoNotDisturbSwitchCell = tableView.dequeueReusableCell()

                cell.promptLabel.text = String.trans_titleDoNotDisturb
                cell.toggleSwitch.isOn = doNotDisturbPeriod.isOn

                cell.toggleAction = { [weak self] isOn in

                    self?.doNotDisturbPeriod.isOn = isOn

                    self?.tableView.reloadSections(IndexSet(integer: Section.doNotDisturbPeriod.rawValue), with: .automatic)

                    let indexPath = IndexPath(row: DoNotDisturbPeriodRow.period.rawValue, section: Section.doNotDisturbPeriod.rawValue)

                    if isOn {
                        self?.enableDoNotDisturb(failed: {
                            SafeDispatch.async { [weak self] in
                                self?.doNotDisturbPeriod.isOn = false
                                self?.tableView.deleteRows(at: [indexPath], with: .automatic)
                            }
                        })

                    } else {
                        self?.disableDoNotDisturb(failed: {
                            SafeDispatch.async { [weak self] in
                                self?.doNotDisturbPeriod.isOn = true
                                self?.tableView.insertRows(at: [indexPath], with: .automatic)
                            }
                        })
                    }

                }

                return cell

            case DoNotDisturbPeriodRow.period.rawValue:

                let cell: DoNotDisturbPeriodCell = tableView.dequeueReusableCell()

                cell.fromPromptLabel.text = String.trans_timeFrom
                cell.toPromptLabel.text = NSLocalizedString("To", comment: "")

                cell.fromLabel.text = doNotDisturbPeriod.localFromString
                cell.toLabel.text = doNotDisturbPeriod.localToString

                return cell

            default:
                break
            }

        case .blackList:

            let cell: SettingsMoreCell = tableView.dequeueReusableCell()
            cell.annotationLabel.text = String.trans_titleBlockedUsers
            return cell

        case .creatorsOfBlockedFeeds:

            let cell: SettingsMoreCell = tableView.dequeueReusableCell()
            cell.annotationLabel.text = String.trans_promptCreatorsOfBlockedFeeds
            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section!")
        }

        switch section {

        case .doNotDisturbPeriod:
            switch indexPath.row {

            case DoNotDisturbPeriodRow.switch.rawValue:
                return 60

            case DoNotDisturbPeriodRow.period.rawValue:
                return 60

            default:
                break
            }

        case .blackList:
            return 60

        case .creatorsOfBlockedFeeds:
            return 60
        }

        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section!")
        }

        switch section {

        case .doNotDisturbPeriod:
            if indexPath.row == DoNotDisturbPeriodRow.period.rawValue {
                performSegue(withIdentifier: "showDoNotDisturbPeriod", sender: nil)
            }

        case .blackList:
            performSegue(withIdentifier: "showBlackList", sender: nil)

        case .creatorsOfBlockedFeeds:
            performSegue(withIdentifier: "showCreatorsOfBlockedFeeds", sender: nil)
        }
    }
}


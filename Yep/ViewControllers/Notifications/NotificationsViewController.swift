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
        let localTimeZone = NSTimeZone.localTimeZone()
        let totalSecondsOffset = localTimeZone.secondsFromGMT

        let hourOffset = totalSecondsOffset / (60 * 60)

        return hourOffset
    }

    var minuteOffset: Int {
        let localTimeZone = NSTimeZone.localTimeZone()
        let totalSecondsOffset = localTimeZone.secondsFromGMT

        let hourOffset = totalSecondsOffset / (60 * 60)
        let minuteOffset = (totalSecondsOffset - hourOffset * (60 * 60)) / 60

        return minuteOffset
    }

    func serverStringWithHour(hour: Int, minute: Int) -> String {
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

    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.registerNibOf(DoNotDisturbSwitchCell)
            tableView.registerNibOf(DoNotDisturbPeriodCell)
            tableView.registerNibOf(SettingsMoreCell)

            tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }
    }

    private var doNotDisturbPeriod = DoNotDisturbPeriod() {
        didSet {
            SafeDispatch.async {
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Notifications & Privacy", comment: "")

        if let me = me(), let userDoNotDisturb = me.doNotDisturb {

            doNotDisturbPeriod.isOn = userDoNotDisturb.isOn

            doNotDisturbPeriod.fromHour = userDoNotDisturb.fromHour
            doNotDisturbPeriod.fromMinute = userDoNotDisturb.fromMinute

            doNotDisturbPeriod.toHour = userDoNotDisturb.toHour
            doNotDisturbPeriod.toMinute = userDoNotDisturb.toMinute
        }
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showDoNotDisturbPeriod" {
            let vc = segue.destinationViewController as! DoNotDisturbPeriodViewController

            vc.doNotDisturbPeriod = doNotDisturbPeriod

            vc.dirtyAction = { [weak self] doNotDisturbPeriod in
                self?.doNotDisturbPeriod = doNotDisturbPeriod
            }
        }
    }

    // MARK: Actions

    private func enableDoNotDisturb(failed failed: () -> Void) {

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
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepAlert.alertSorry(message: NSLocalizedString("Enable Do Not Disturb Failed!", comment: ""), inViewController: self)

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

    private func disableDoNotDisturb(failed failed: () -> Void) {

        guard let me = me() else {
            return
        }

        if let _ = me.doNotDisturb {

            let info: JSONDictionary = [
                "mute_started_at_string": "",
                "mute_ended_at_string": "",
            ]

            updateMyselfWithInfo(info, failureHandler: { [weak self] (reason, errorMessage) in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: NSLocalizedString("Disable Do Not Disturb Failed!", comment: ""), inViewController: self)

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
        case DoNotDisturbPeriod
        case BlackList
        case CreatorsOfBlockedFeeds
    }

    private enum DoNotDisturbPeriodRow: Int {
        case Switch
        case Period
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError("Invalid Section!")
        }

        switch section {
        case .DoNotDisturbPeriod:
            return doNotDisturbPeriod.isOn ? 2 : 1
        case .BlackList:
            return 1
        case .CreatorsOfBlockedFeeds:
            return 1
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section!")
        }

        switch section {

        case .DoNotDisturbPeriod:

            switch indexPath.row {

            case DoNotDisturbPeriodRow.Switch.rawValue:

                let cell: DoNotDisturbSwitchCell = tableView.dequeueReusableCell()

                cell.promptLabel.text = NSLocalizedString("Do Not Disturb", comment: "")
                cell.toggleSwitch.on = doNotDisturbPeriod.isOn

                cell.toggleAction = { [weak self] isOn in

                    self?.doNotDisturbPeriod.isOn = isOn

                    let indexPath = NSIndexPath(forRow: DoNotDisturbPeriodRow.Period.rawValue, inSection: 0)

                    if isOn {
                        guard self?.tableView.numberOfRowsInSection(Section.DoNotDisturbPeriod.rawValue) == 1 else {
                            return
                        }

                        self?.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

                        self?.enableDoNotDisturb(failed: {
                            SafeDispatch.async {
                                self?.doNotDisturbPeriod.isOn = false
                                self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                            }
                        })

                    } else {
                        guard self?.tableView.numberOfRowsInSection(Section.DoNotDisturbPeriod.rawValue) == 2 else {
                            return
                        }

                        self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

                        self?.disableDoNotDisturb(failed: {
                            SafeDispatch.async {
                                self?.doNotDisturbPeriod.isOn = true
                                self?.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                            }
                        })
                    }
                }

                return cell

            case DoNotDisturbPeriodRow.Period.rawValue:

                let cell: DoNotDisturbPeriodCell = tableView.dequeueReusableCell()

                cell.fromPromptLabel.text = NSLocalizedString("From", comment: "")
                cell.toPromptLabel.text = NSLocalizedString("To", comment: "")

                cell.fromLabel.text = doNotDisturbPeriod.localFromString
                cell.toLabel.text = doNotDisturbPeriod.localToString

                return cell

            default:
                break
            }

        case .BlackList:

            let cell: SettingsMoreCell = tableView.dequeueReusableCell()
            cell.annotationLabel.text = String.trans_titleBlockedUsers
            return cell

        case .CreatorsOfBlockedFeeds:

            let cell: SettingsMoreCell = tableView.dequeueReusableCell()
            cell.annotationLabel.text = String.trans_promptCreatorsOfBlockedFeeds
            return cell
        }

        return UITableViewCell()
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section!")
        }

        switch section {

        case .DoNotDisturbPeriod:
            switch indexPath.row {

            case DoNotDisturbPeriodRow.Switch.rawValue:
                return 60

            case DoNotDisturbPeriodRow.Period.rawValue:
                return 60

            default:
                break
            }

        case .BlackList:
            return 60

        case .CreatorsOfBlockedFeeds:
            return 60
        }

        return 0
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section!")
        }

        switch section {

        case .DoNotDisturbPeriod:
            if indexPath.row == DoNotDisturbPeriodRow.Period.rawValue {
                performSegueWithIdentifier("showDoNotDisturbPeriod", sender: nil)
            }

        case .BlackList:
            performSegueWithIdentifier("showBlackList", sender: nil)

        case .CreatorsOfBlockedFeeds:
            performSegueWithIdentifier("showCreatorsOfBlockedFeeds", sender: nil)
        }
    }
}


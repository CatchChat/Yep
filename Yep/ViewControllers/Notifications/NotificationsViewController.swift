//
//  NotificationsViewController.swift
//  Yep
//
//  Created by NIX on 15/8/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
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

class NotificationsViewController: SegueViewController {

    @IBOutlet private weak var tableView: UITableView!

    private var doNotDisturbPeriod = DoNotDisturbPeriod() {
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
    }

    private let DoNotDisturbSwitchCellID = "DoNotDisturbSwitchCell"
    private let DoNotDisturbPeriodCellID = "DoNotDisturbPeriodCell"

    private let settingsMoreCellID = "SettingsMoreCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Notifications & Privacy", comment: "")

        tableView.registerNib(UINib(nibName: DoNotDisturbSwitchCellID, bundle: nil), forCellReuseIdentifier: DoNotDisturbSwitchCellID)
        tableView.registerNib(UINib(nibName: DoNotDisturbPeriodCellID, bundle: nil), forCellReuseIdentifier: DoNotDisturbPeriodCellID)

        tableView.registerNib(UINib(nibName: settingsMoreCellID, bundle: nil), forCellReuseIdentifier: settingsMoreCellID)

        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)

        let realm = try! Realm()

        if let
            myUserID = YepUserDefaults.userID.value,
            me = userWithUserID(myUserID, inRealm: realm) {

                if let userDoNotDisturb = me.doNotDisturb {

                    doNotDisturbPeriod.isOn = userDoNotDisturb.isOn

                    doNotDisturbPeriod.fromHour = userDoNotDisturb.fromHour
                    doNotDisturbPeriod.fromMinute = userDoNotDisturb.fromMinute

                    doNotDisturbPeriod.toHour = userDoNotDisturb.toHour
                    doNotDisturbPeriod.toMinute = userDoNotDisturb.toMinute
                }
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

        if let
            myUserID = YepUserDefaults.userID.value,
            me = userWithUserID(myUserID, inRealm: realm) {

                var userDoNotDisturb = me.doNotDisturb

                if userDoNotDisturb == nil {
                    let _userDoNotDisturb = UserDoNotDisturb()

                    let _ = try? realm.write {
                        me.doNotDisturb = _userDoNotDisturb
                    }

                    userDoNotDisturb = _userDoNotDisturb
                }

                if let userDoNotDisturb = me.doNotDisturb {

                    let info: JSONDictionary = [
                        "mute_started_at_string": userDoNotDisturb.serverFromString,
                        "mute_ended_at_string": userDoNotDisturb.serverToString,
                    ]

                    updateMyselfWithInfo(info, failureHandler: { [weak self] (reason, errorMessage) in
                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        YepAlert.alertSorry(message: NSLocalizedString("Enable Do Not Disturb failed!", comment: ""), inViewController: self)

                        failed()

                    }, completion: { success in

                        dispatch_async(dispatch_get_main_queue()) {

                            guard let realm = try? Realm() else {
                                return
                            }

                            if let
                                myUserID = YepUserDefaults.userID.value,
                                me = userWithUserID(myUserID, inRealm: realm) {

                                    let _ = try? realm.write {
                                        me.doNotDisturb?.isOn = true
                                    }
                            }
                        }
                    })
                }
        }
    }

    private func disableDoNotDisturb(failed failed: () -> Void) {

        guard let realm = try? Realm() else {
            return
        }

        if let
            myUserID = YepUserDefaults.userID.value,
            me = userWithUserID(myUserID, inRealm: realm) {

                if let _ = me.doNotDisturb {

                    let info: JSONDictionary = [
                        "mute_started_at_string": "",
                        "mute_ended_at_string": "",
                    ]

                    updateMyselfWithInfo(info, failureHandler: { [weak self] (reason, errorMessage) in
                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        YepAlert.alertSorry(message: NSLocalizedString("Disable Do Not Disturb failed!", comment: ""), inViewController: self)

                        failed()

                    }, completion: { success in

                        dispatch_async(dispatch_get_main_queue()) { [weak self] in

                            // clean UI
                            self?.doNotDisturbPeriod = DoNotDisturbPeriod()

                            guard let realm = try? Realm() else {
                                return
                            }

                            if let
                                myUserID = YepUserDefaults.userID.value,
                                me = userWithUserID(myUserID, inRealm: realm) {

                                    if let userDoNotDisturb = me.doNotDisturb {
                                        let _ = try? realm.write {
                                            realm.delete(userDoNotDisturb)
                                        }
                                    }
                            }
                        }
                    })
                }
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {

    private enum DoNotDisturbPeriodRow: Int {
        case Switch
        case Period
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch section {
        case 0:
            return doNotDisturbPeriod.isOn ? 2 : 1
        case 1:
            return 1
        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        switch indexPath.section {

        case 0:

            switch indexPath.row {

            case DoNotDisturbPeriodRow.Switch.rawValue:
                let cell = tableView.dequeueReusableCellWithIdentifier(DoNotDisturbSwitchCellID) as! DoNotDisturbSwitchCell
                cell.promptLabel.text = NSLocalizedString("Do Not Disturb", comment: "")
                cell.toggleSwitch.on = doNotDisturbPeriod.isOn

                cell.toggleAction = { [weak self] isOn in

                    self?.doNotDisturbPeriod.isOn = isOn

                    let indexPath = NSIndexPath(forRow: DoNotDisturbPeriodRow.Period.rawValue, inSection: 0)

                    if isOn {
                        self?.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

                        self?.enableDoNotDisturb(failed: {
                            dispatch_async(dispatch_get_main_queue()) {
                                self?.doNotDisturbPeriod.isOn = false
                                self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                            }
                        })

                    } else {
                        self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .None)

                        self?.disableDoNotDisturb(failed: {
                            dispatch_async(dispatch_get_main_queue()) {
                                self?.doNotDisturbPeriod.isOn = true
                                self?.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                            }
                        })
                    }
                }

                return cell

            case DoNotDisturbPeriodRow.Period.rawValue:
                let cell = tableView.dequeueReusableCellWithIdentifier(DoNotDisturbPeriodCellID) as! DoNotDisturbPeriodCell
                cell.fromPromptLabel.text = NSLocalizedString("From", comment: "")
                cell.toPromptLabel.text = NSLocalizedString("To", comment: "")

                cell.fromLabel.text = doNotDisturbPeriod.localFromString
                cell.toLabel.text = doNotDisturbPeriod.localToString

                return cell

            default:
                break
            }

        case 1:

            let cell = tableView.dequeueReusableCellWithIdentifier(settingsMoreCellID) as! SettingsMoreCell
            cell.annotationLabel.text = NSLocalizedString("Blocked Users", comment: "")
            return cell

        default:
            break
        }

        return UITableViewCell()
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        switch indexPath.section {
        case 0:
            switch indexPath.row {

            case DoNotDisturbPeriodRow.Switch.rawValue:
                return 60

            case DoNotDisturbPeriodRow.Period.rawValue:
                return 60

            default:
                break
            }
        case 1:
            return 60
        default:
            break
        }

        return 0
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        switch indexPath.section {
        case 0:
            if indexPath.row == DoNotDisturbPeriodRow.Period.rawValue {
                performSegueWithIdentifier("showDoNotDisturbPeriod", sender: nil)
            }
        case 1:
            performSegueWithIdentifier("showBlackList", sender: nil)
        default:
            break
        }
    }
}


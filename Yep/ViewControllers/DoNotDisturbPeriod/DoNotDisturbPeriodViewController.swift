//
//  DoNotDisturbPeriodViewController.swift
//  Yep
//
//  Created by NIX on 15/8/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

class DoNotDisturbPeriodViewController: UIViewController {

    var doNotDisturbPeriod = DoNotDisturbPeriod()

    var dirtyAction: (DoNotDisturbPeriod -> Void)?

    @IBOutlet private weak var fromButton: UIButton!
    @IBOutlet private weak var toButton: UIButton!
    @IBOutlet private weak var pickerView: UIPickerView!

    private enum ActiveTime {
        case From
        case To
    }

    private let max = Int(INT16_MAX)

    private var activeTime: ActiveTime = .From {
        willSet {
            switch newValue {

            case .From:
                fromButton.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)
                toButton.backgroundColor = UIColor.whiteColor()

                pickerView.selectRow(max / (2 * 24) * 24 + doNotDisturbPeriod.fromHour, inComponent: 0, animated: true)
                pickerView.selectRow(max / (2 * 60) * 60 + doNotDisturbPeriod.fromMinute, inComponent: 1, animated: true)

            case .To:
                fromButton.backgroundColor = UIColor.whiteColor()
                toButton.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)

                pickerView.selectRow(max / (2 * 24) * 24 + doNotDisturbPeriod.toHour, inComponent: 0, animated: true)
                pickerView.selectRow(max / (2 * 60) * 60 + doNotDisturbPeriod.toMinute, inComponent: 1, animated: true)
            }
        }
    }

    private var isDirty = false {
        didSet {
            updateDoNotDisturb(success: { [weak self] in
                if let strongSelf = self {
                    strongSelf.dirtyAction?(strongSelf.doNotDisturbPeriod)
                }
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Mute", comment: "")

        activeTime = .From

        updateFromButton()
        updateToButton()
    }

    // MARK: - Actions

    private func updateDoNotDisturb(success success: () -> Void) {

        let info: JSONDictionary = [
            "mute_started_at_string": doNotDisturbPeriod.serverFromString,
            "mute_ended_at_string": doNotDisturbPeriod.serverToString,
        ]

        updateMyselfWithInfo(info, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepAlert.alertSorry(message: NSLocalizedString("Set Do Not Disturb failed!", comment: ""), inViewController: self)

        }, completion: { _ in

            dispatch_async(dispatch_get_main_queue()) {

                success()

                guard let realm = try? Realm() else {
                    return
                }

                if let
                    myUserID = YepUserDefaults.userID.value,
                    me = userWithUserID(myUserID, inRealm: realm) {

                        var userDoNotDisturb = me.doNotDisturb

                        if userDoNotDisturb == nil {
                            let _userDoNotDisturb = UserDoNotDisturb()
                            _userDoNotDisturb.isOn = true

                            let _ = try? realm.write {
                                me.doNotDisturb = _userDoNotDisturb
                            }

                            userDoNotDisturb = _userDoNotDisturb
                        }

                        if let userDoNotDisturb = me.doNotDisturb {
                            let _ = try? realm.write {
                                userDoNotDisturb.fromHour = self.doNotDisturbPeriod.fromHour
                                userDoNotDisturb.fromMinute = self.doNotDisturbPeriod.fromMinute

                                userDoNotDisturb.toHour = self.doNotDisturbPeriod.toHour
                                userDoNotDisturb.toMinute = self.doNotDisturbPeriod.toMinute
                            }
                        }
                }
            }
        })
    }

    private func updateFromButton() {
        fromButton.setTitle(NSLocalizedString("From", comment: "") + " " + doNotDisturbPeriod.localFromString, forState: .Normal)
    }

    private func updateToButton() {
        toButton.setTitle(NSLocalizedString("To", comment: "") + " " + doNotDisturbPeriod.localToString, forState: .Normal)
    }

    @IBAction private func activeFrom() {
        activeTime = .From
    }

    @IBAction private func activeTo() {
        activeTime = .To
    }
}

// MARK: - UIPickerViewDataSource, UIPickerViewDelegate

extension DoNotDisturbPeriodViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return max
    }

    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 60
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        if component == 0 {
            return String(format: "%02d", row % 24)

        } else if component == 1 {
            return String(format: "%02d", row % 60)
        }

        return ""
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        switch activeTime {

        case .From:

            if component == 0 {
                doNotDisturbPeriod.fromHour = row % 24
            } else if component == 1 {
                doNotDisturbPeriod.fromMinute = row % 60
            }

            updateFromButton()

        case .To:
            if component == 0 {
                doNotDisturbPeriod.toHour = row % 24
            } else if component == 1 {
                doNotDisturbPeriod.toMinute = row % 60
            }

            updateToButton()
        }

        isDirty = true
    }
}


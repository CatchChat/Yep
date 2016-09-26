//
//  DoNotDisturbPeriodViewController.swift
//  Yep
//
//  Created by NIX on 15/8/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import YepKit
import YepNetworking

final class DoNotDisturbPeriodViewController: UIViewController {

    var doNotDisturbPeriod = DoNotDisturbPeriod()

    var dirtyAction: ((DoNotDisturbPeriod) -> Void)?

    @IBOutlet fileprivate weak var fromButton: UIButton!
    @IBOutlet fileprivate weak var toButton: UIButton!
    @IBOutlet fileprivate weak var pickerView: UIPickerView!

    fileprivate enum ActiveTime {
        case from
        case to
    }

    fileprivate let max = Int(INT16_MAX)

    fileprivate var activeTime: ActiveTime = .from {
        willSet {
            switch newValue {

            case .from:
                fromButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
                toButton.backgroundColor = UIColor.white

                pickerView.selectRow(max / (2 * 24) * 24 + doNotDisturbPeriod.fromHour, inComponent: 0, animated: true)
                pickerView.selectRow(max / (2 * 60) * 60 + doNotDisturbPeriod.fromMinute, inComponent: 1, animated: true)

            case .to:
                fromButton.backgroundColor = UIColor.white
                toButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)

                pickerView.selectRow(max / (2 * 24) * 24 + doNotDisturbPeriod.toHour, inComponent: 0, animated: true)
                pickerView.selectRow(max / (2 * 60) * 60 + doNotDisturbPeriod.toMinute, inComponent: 1, animated: true)
            }
        }
    }

    fileprivate var isDirty = false {
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

        title = String.trans_titleMute

        activeTime = .from

        updateFromButton()
        updateToButton()
    }

    // MARK: - Actions

    fileprivate func updateDoNotDisturb(success: @escaping () -> Void) {

        let info: JSONDictionary = [
            "mute_started_at_string": doNotDisturbPeriod.serverFromString,
            "mute_ended_at_string": doNotDisturbPeriod.serverToString,
        ]

        updateMyselfWithInfo(info, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

            YepAlert.alertSorry(message: NSLocalizedString("Set Do Not Disturb Failed!", comment: ""), inViewController: self)

        }, completion: { _ in

            SafeDispatch.async {

                defer {
                    success()
                }

                guard let realm = try? Realm() else {
                    return
                }

                if let me = meInRealm(realm) {

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

    fileprivate func updateFromButton() {
        fromButton.setTitle(String.trans_timeFrom + " " + doNotDisturbPeriod.localFromString, for: UIControlState())
    }

    fileprivate func updateToButton() {
        toButton.setTitle(NSLocalizedString("To", comment: "") + " " + doNotDisturbPeriod.localToString, for: UIControlState())
    }

    @IBAction fileprivate func activeFrom() {
        activeTime = .from
    }

    @IBAction fileprivate func activeTo() {
        activeTime = .to
    }
}

// MARK: - UIPickerViewDataSource, UIPickerViewDelegate

extension DoNotDisturbPeriodViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return max
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 60
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        if component == 0 {
            return String(format: "%02d", row % 24)

        } else if component == 1 {
            return String(format: "%02d", row % 60)
        }

        return ""
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        switch activeTime {

        case .from:

            if component == 0 {
                doNotDisturbPeriod.fromHour = row % 24
            } else if component == 1 {
                doNotDisturbPeriod.fromMinute = row % 60
            }

            updateFromButton()

        case .to:
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


//
//  DoNotDisturbPeriodViewController.swift
//  Yep
//
//  Created by NIX on 15/8/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class DoNotDisturbPeriodViewController: UIViewController {

    var doNotDisturbPeriod = DoNotDisturbPeriod()

    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var toButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!

    enum ActiveTime {
        case From
        case To
    }

    let max = Int(INT16_MAX)

    var activeTime: ActiveTime = .From {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Mute", comment: "")

        activeTime = .From

        updateFromButton()
        updateToButton()
    }


    // MARK: - Actions

    func updateFromButton() {
        fromButton.setTitle(NSLocalizedString("From", comment: "") + " " + doNotDisturbPeriod.fromString, forState: .Normal)
    }

    func updateToButton() {
        toButton.setTitle(NSLocalizedString("To", comment: "") + " " + doNotDisturbPeriod.toString, forState: .Normal)
    }

    @IBAction func activeFrom() {
        activeTime = .From
    }

    @IBAction func activeTo() {
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

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {

        if component == 0 {
            return "\(row % 24)"

        } else if component == 1 {
            return "\(row % 60)"
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
    }
}


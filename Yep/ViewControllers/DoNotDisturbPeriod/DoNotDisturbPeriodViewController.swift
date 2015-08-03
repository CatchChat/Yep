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

    var activeTime: ActiveTime = .From {
        willSet {
            switch newValue {

            case .From:
                fromButton.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)
                toButton.backgroundColor = UIColor.whiteColor()

                pickerView.selectRow(doNotDisturbPeriod.fromHour, inComponent: 0, animated: true)
                pickerView.selectRow(doNotDisturbPeriod.fromMinute, inComponent: 1, animated: true)
                

            case .To:
                fromButton.backgroundColor = UIColor.whiteColor()
                toButton.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)

                pickerView.selectRow(doNotDisturbPeriod.toHour, inComponent: 0, animated: true)
                pickerView.selectRow(doNotDisturbPeriod.toMinute, inComponent: 1, animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Mute", comment: "")

        activeTime = .From
    }


    // MARK: - Actions

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
        if component == 0 {
            return 24
        } else if component == 1 {
            return 60
        }

        return 0
    }

    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 60
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return "\(row)"
    }


}
//
//  DoNotDisturbPeriodViewController.swift
//  Yep
//
//  Created by NIX on 15/8/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class DoNotDisturbPeriodViewController: UIViewController {

    @IBOutlet weak var fromButton: UIButton!

    @IBOutlet weak var toButton: UIButton!

    @IBOutlet weak var pickerView: UIPickerView!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Mute", comment: "")

        fromButton.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)
        toButton.backgroundColor = UIColor.whiteColor()
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
        return "\(row + 1)"
    }


}
//
//  BaseInputMobileViewController.swift
//  Yep
//
//  Created by NIX on 16/9/1.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class BaseInputMobileViewController: BaseViewController, PhoneNumberRepresentation {

    @IBOutlet weak var areaCodeTextField: BorderTextField!
    @IBOutlet weak var areaCodeTextFieldWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var mobileNumberTextField: BorderTextField!
    @IBOutlet private weak var mobileNumberTextFieldTopConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        mobileNumberTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value
    }

    func tappedKeyboardReturn() {
        assert(false, "Must override tappedKeyboardReturn")
    }
}


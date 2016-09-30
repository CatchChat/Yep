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
    @IBOutlet fileprivate weak var mobileNumberTextFieldTopConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        mobileNumberTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value
    }

    func tappedKeyboardReturn() {
        assert(false, "Must override tappedKeyboardReturn")
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {

        if textField == areaCodeTextField {
            adjustAreaCodeTextFieldWidth()
        }

        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {

        if textField == areaCodeTextField {
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] _ in
                self?.areaCodeTextFieldWidthConstraint.constant = 60
                self?.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        guard let areaCode = areaCodeTextField.text, !areaCode.isEmpty else { return true }
        guard let number = mobileNumberTextField.text, !number.isEmpty else { return true }
        
        tappedKeyboardReturn()
        
        return true
    }
}


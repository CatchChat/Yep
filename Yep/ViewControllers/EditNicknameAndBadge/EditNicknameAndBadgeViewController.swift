//
//  EditNicknameAndBadgeViewController.swift
//  Yep
//
//  Created by NIX on 15/7/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class EditNicknameAndBadgeViewController: UITableViewController {

    @IBOutlet weak var nicknameTextField: UITextField!

    @IBOutlet weak var centerLeft1GapConstraint: NSLayoutConstraint!
    @IBOutlet weak var centerRight1GapConstraint: NSLayoutConstraint!
    @IBOutlet weak var left1Left2GapConstraint: NSLayoutConstraint!
    @IBOutlet weak var right1Right2GapConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Nickname", comment: "")

        nicknameTextField.text = YepUserDefaults.nickname.value
        nicknameTextField.delegate = self

        let gap = UIDevice.matchWidthFrom(10, 25, 32)
        centerLeft1GapConstraint.constant = gap
        centerRight1GapConstraint.constant = gap
        left1Left2GapConstraint.constant = gap
        right1Right2GapConstraint.constant = gap
    }
}

extension EditNicknameAndBadgeViewController: UITextFieldDelegate {

    func textFieldShouldReturn(textField: UITextField) -> Bool {

        if textField == nicknameTextField {

            textField.resignFirstResponder()

            let newNickname = textField.text

            if newNickname != YepUserDefaults.nickname.value {

                YepHUD.showActivityIndicator()

                updateMyselfWithInfo(["nickname": newNickname], failureHandler: { (reason, errorMessage) in
                    defaultFailureHandler(reason, errorMessage)

                    YepHUD.hideActivityIndicator()

                }, completion: { success in
                    dispatch_async(dispatch_get_main_queue()) {
                        YepUserDefaults.nickname.value = newNickname
                    }

                    YepHUD.hideActivityIndicator()
                })
            }
        }

        return true
    }
}
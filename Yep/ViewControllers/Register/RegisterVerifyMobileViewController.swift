//
//  RegisterVerifyMobileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class RegisterVerifyMobileViewController: UIViewController {

    var mobile: String!
    var areaCode: String!

    
    @IBOutlet weak var verifyMobileNumberPromptLabel: UILabel!

    @IBOutlet weak var verifyCodeTextField: UnderLineTextField!

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        verifyCodeTextField.delegate = self
        verifyCodeTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        nextButton.enabled = false
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        verifyCodeTextField.becomeFirstResponder()
    }

    // MARK: Actions

    func textFieldDidChange(textField: UITextField) {
        nextButton.enabled = !textField.text.isEmpty
    }

    @IBAction func back(sender: UIButton) {
        navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func next(sender: UIButton) {
        verifyRegisterMobile()
    }

    private func verifyRegisterMobile() {

        view.endEditing(true)

        let verifyCode = verifyCodeTextField.text
        verifyMobile(mobile, withAreaCode: areaCode, verifyCode: verifyCode, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

            if let errorMessage = errorMessage {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.nextButton.enabled = false

                    YepAlert.alertSorry(message: errorMessage, inViewController: self, withDismissAction: { () -> Void in
                        verifyCodeTextField.becomeFirstResponder()
                    })
                })
            }

        }, completion: { loginUser in

            println("\(loginUser)")

            dispatch_async(dispatch_get_main_queue(), { () -> Void in

                self.saveTokenAndUserInfoOfLoginUser(loginUser)

                self.performSegueWithIdentifier("showRegisterPickAvatar", sender: nil)
            })
        })
    }

    private func saveTokenAndUserInfoOfLoginUser(loginUser: LoginUser) {
        YepUserDefaults.setV1AccessToken(loginUser.accessToken)
        YepUserDefaults.setUserID(loginUser.userID)
        YepUserDefaults.setNickname(loginUser.nickname)
        if let avatarURLString = loginUser.avatarURLString {
            YepUserDefaults.setAvatarURLString(avatarURLString)
        }
    }

}

extension RegisterVerifyMobileViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if !textField.text.isEmpty {
            verifyRegisterMobile()
        }

        return true
    }
}
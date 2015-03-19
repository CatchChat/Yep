//
//  LoginVerifyMobileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class LoginVerifyMobileViewController: UIViewController {

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
        login()
    }

    private func login() {

        view.endEditing(true)
        
        let verifyCode = verifyCodeTextField.text

        loginByMobile(mobile, withAreaCode: areaCode, verifyCode: verifyCode, failureHandler: { (resource, reason, data) in
            defaultFailureHandler(forResource: resource, withFailureReason: reason, data)

            if let errorMessage = errorMessageInData(data) {
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

                if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                    appDelegate.startMainStory()
                }
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

extension LoginVerifyMobileViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if !textField.text.isEmpty {
            login()
        }
        
        return true
    }
}
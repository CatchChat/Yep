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

        loginByMobile(mobile, withAreaCode: areaCode, verifyCode: verifyCode, failureHandler: { (reason, errorMessage) in
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

                saveTokenAndUserInfoOfLoginUser(loginUser)

                if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                    appDelegate.startMainStory()
                }
            })
        })
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
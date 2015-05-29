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


    lazy var callMeTimer: NSTimer = {
        let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "tryCallMe:", userInfo: nil, repeats: true)
        return timer
        }()
    var haveAppropriateInput = false {
        willSet {
            nextButton.enabled = newValue

            if newValue {
                nextButton.setTitle(NSLocalizedString("Done", comment: ""), forState: .Normal)
            }
        }
    }
    var callMeInSeconds = YepConfig.callMeInSeconds()


    override func viewDidLoad() {
        super.viewDidLoad()

        backButton.setTitle(NSLocalizedString("Back", comment: ""), forState: .Normal)
        nextButton.setTitle(NSLocalizedString("Done", comment: ""), forState: .Normal)

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

        callMeTimer.fire()
    }

    // MARK: Actions

    func tryCallMe(timer: NSTimer) {
        if !haveAppropriateInput {
            if callMeInSeconds > 1 {
                let callMeInSecondsString = NSLocalizedString("Call Me", comment: "") + " (\(callMeInSeconds))"
                nextButton.setTitle(callMeInSecondsString, forState: .Normal)

            } else {
                nextButton.setTitle(NSLocalizedString("Call Me", comment: ""), forState: .Normal)
                nextButton.enabled = true
            }
        }

        if (callMeInSeconds > 1) {
            callMeInSeconds--
        }
    }

    func callMe() {
        nextButton.setTitle(NSLocalizedString("Calling", comment: ""), forState: .Normal)

        sendVerifyCodeOfMobile(mobile, withAreaCode: areaCode, useMethod: .Call, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

            if let errorMessage = errorMessage {
                dispatch_async(dispatch_get_main_queue()) {
                    YepAlert.alertSorry(message: errorMessage, inViewController: self)
                }
            }

        }, completion: { success in
            println("resendVoiceVerifyCode \(success)")
        })
    }

    func textFieldDidChange(textField: UITextField) {
        haveAppropriateInput = (count(textField.text) == YepConfig.verifyCodeLength())
    }

    @IBAction func back(sender: UIButton) {
        navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func next(sender: UIButton) {
        login()
    }

    private func login() {

        if haveAppropriateInput {
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

        } else {
            callMe()
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
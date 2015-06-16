//
//  RegisterPickMobileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class RegisterPickMobileViewController: UIViewController {

    @IBOutlet weak var pickMobileNumberPromptLabel: UILabel!
    @IBOutlet weak var pickMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var areaCodeTextField: BorderTextField!
    @IBOutlet weak var mobileNumberTextField: BorderTextField!
    @IBOutlet weak var mobileNumberTextFieldTopConstraint: NSLayoutConstraint!

    lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .Plain, target: self, action: "next:")
        return button
        }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Sign up", comment: ""))

        navigationItem.rightBarButtonItem = nextButton

        pickMobileNumberPromptLabel.text = NSLocalizedString("What's your number?", comment: "")

        areaCodeTextField.delegate = self
        areaCodeTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)

        mobileNumberTextField.delegate = self
        mobileNumberTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)

        pickMobileNumberPromptLabelTopConstraint.constant = UIDevice.matchMarginFrom(50, 60, 60, 60)
        mobileNumberTextFieldTopConstraint.constant = UIDevice.matchMarginFrom(40, 50, 50, 50)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        nextButton.enabled = false
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        mobileNumberTextField.becomeFirstResponder()
    }

    // MARK: Actions

    func textFieldDidChange(textField: UITextField) {
        
        nextButton.enabled = !areaCodeTextField.text.isEmpty && !mobileNumberTextField.text.isEmpty
    }

    func next(sender: UIBarButtonItem) {
        tryShowRegisterVerifyMobile()
    }

    private func tryShowRegisterVerifyMobile() {
        
        view.endEditing(true)
        
        let mobile = mobileNumberTextField.text
        let areaCode = areaCodeTextField.text

        YepHUD.showActivityIndicator()
        
        validateMobile(mobile, withAreaCode: areaCode, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)
            
            YepHUD.hideActivityIndicator()

        }, completion: { (available, message) in
            if available, let nickname = YepUserDefaults.nickname.value {
                println("ValidateMobile: available")

                registerMobile(mobile, withAreaCode: areaCode, nickname: nickname, failureHandler: { (reason, errorMessage) in
                    defaultFailureHandler(reason, errorMessage)

                    YepHUD.hideActivityIndicator()

                    if let errorMessage = errorMessage {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            YepAlert.alertSorry(message: errorMessage, inViewController: self, withDismissAction: { () -> Void in
                                mobileNumberTextField.becomeFirstResponder()
                            })
                        })
                    }

                }, completion: { created in

                    YepHUD.hideActivityIndicator()

                    if created {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.performSegueWithIdentifier("showRegisterVerifyMobile", sender: ["mobile" : mobile, "areaCode": areaCode])
                        })

                    } else {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.nextButton.enabled = false

                            YepAlert.alertSorry(message: "registerMobile failed", inViewController: self, withDismissAction: { () -> Void in
                                mobileNumberTextField.becomeFirstResponder()
                            })
                        })
                    }
                })

            } else {
                println("ValidateMobile: \(message)")

                YepHUD.hideActivityIndicator()

                dispatch_async(dispatch_get_main_queue()) {

                    self.nextButton.enabled = false

                    YepAlert.alertSorry(message: message, inViewController: self, withDismissAction: { () -> Void in
                        mobileNumberTextField.becomeFirstResponder()
                    })
                }
            }
        })

    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showRegisterVerifyMobile" {

            if let info = sender as? [String: String] {
                let vc = segue.destinationViewController as! RegisterVerifyMobileViewController

                vc.mobile = info["mobile"]
                vc.areaCode = info["areaCode"]
            }
        }
    }

}

extension RegisterPickMobileViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if !textField.text.isEmpty {
            tryShowRegisterVerifyMobile()
        }

        return true
    }
}
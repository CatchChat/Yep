//
//  RegisterPickMobileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class RegisterPickMobileViewController: SegueViewController {

    @IBOutlet private weak var pickMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var pickMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var areaCodeTextField: BorderTextField!
    @IBOutlet private weak var areaCodeTextFieldWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var mobileNumberTextField: BorderTextField!
    @IBOutlet private weak var mobileNumberTextFieldTopConstraint: NSLayoutConstraint!

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .Plain, target: self, action: "next:")
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Sign up", comment: ""))

        navigationItem.rightBarButtonItem = nextButton

        pickMobileNumberPromptLabel.text = NSLocalizedString("What's your number?", comment: "")

        areaCodeTextField.text = NSTimeZone.areaCode
        areaCodeTextField.backgroundColor = UIColor.whiteColor()

        areaCodeTextField.delegate = self
        areaCodeTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)

        //mobileNumberTextField.placeholder = ""
        mobileNumberTextField.backgroundColor = UIColor.whiteColor()
        mobileNumberTextField.textColor = UIColor.yepInputTextColor()
        mobileNumberTextField.delegate = self
        mobileNumberTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)

        pickMobileNumberPromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
        mobileNumberTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value

        nextButton.enabled = false
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        mobileNumberTextField.becomeFirstResponder()
    }

    // MARK: Actions

    private func adjustAreaCodeTextFieldWidth() {

        guard let text = areaCodeTextField.text else {
            return
        }

        let size = text.sizeWithAttributes(areaCodeTextField.editing ? areaCodeTextField.typingAttributes : areaCodeTextField.defaultTextAttributes)

        let width = 32 + (size.width + 22) + 20

        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
            self.areaCodeTextFieldWidthConstraint.constant = max(width, 100)
            self.view.layoutIfNeeded()
        }, completion: { finished in
        })
    }

    @objc private func textFieldDidChange(textField: UITextField) {

        guard let areaCode = areaCodeTextField.text, mobileNumber = mobileNumberTextField.text else {
            return
        }
        
        nextButton.enabled = !areaCode.isEmpty && !mobileNumber.isEmpty

        if textField == areaCodeTextField {
            adjustAreaCodeTextFieldWidth()
        }
    }

    @objc private func next(sender: UIBarButtonItem) {
        tryShowRegisterVerifyMobile()
    }

    private func tryShowRegisterVerifyMobile() {
        
        view.endEditing(true)
        
        guard let mobile = mobileNumberTextField.text, areaCode = areaCodeTextField.text else {
            return
        }

        YepHUD.showActivityIndicator()
        
        validateMobile(mobile, withAreaCode: areaCode, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)
            
            YepHUD.hideActivityIndicator()

        }, completion: { (available, message) in
            if available, let nickname = YepUserDefaults.nickname.value {
                println("ValidateMobile: available")

                registerMobile(mobile, withAreaCode: areaCode, nickname: nickname, failureHandler: { (reason, errorMessage) in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    YepHUD.hideActivityIndicator()

                    if let errorMessage = errorMessage {
                        YepAlert.alertSorry(message: errorMessage, inViewController: self, withDismissAction: { [weak self] in
                            self?.mobileNumberTextField.becomeFirstResponder()
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

                            YepAlert.alertSorry(message: "registerMobile failed", inViewController: self, withDismissAction: { [weak self] in
                                self?.mobileNumberTextField.becomeFirstResponder()
                            })
                        })
                    }
                })

            } else {
                println("ValidateMobile: \(message)")

                YepHUD.hideActivityIndicator()

                dispatch_async(dispatch_get_main_queue()) {

                    self.nextButton.enabled = false

                    YepAlert.alertSorry(message: message, inViewController: self, withDismissAction: { [weak self] in
                        self?.mobileNumberTextField.becomeFirstResponder()
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

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField == areaCodeTextField {
            adjustAreaCodeTextFieldWidth()
        }

        return true
    }

    func textFieldDidEndEditing(textField: UITextField) {
        if textField == areaCodeTextField {
            UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                self.areaCodeTextFieldWidthConstraint.constant = 60
                self.view.layoutIfNeeded()
            }, completion: { finished in
            })
        }
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {

        guard let mobile = mobileNumberTextField.text, areaCode = areaCodeTextField.text else {
            return false
        }

        if !areaCode.isEmpty && !mobile.isEmpty {
            tryShowRegisterVerifyMobile()
        }

        return true
    }
}


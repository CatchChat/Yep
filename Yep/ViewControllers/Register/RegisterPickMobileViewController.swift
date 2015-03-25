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

    @IBOutlet weak var areaCodeTextField: UnderLineTextField!
    @IBOutlet weak var mobileNumberTextField: UnderLineTextField!

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!


    override func viewDidLoad() {
        super.viewDidLoad()

        areaCodeTextField.delegate = self
        areaCodeTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)

        mobileNumberTextField.delegate = self
        mobileNumberTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)
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

    @IBAction func back(sender: UIButton) {
        navigationController?.popViewControllerAnimated(true)
    }


    @IBAction func next(sender: UIButton) {
        tryShowRegisterVerifyMobile()
    }

    private func tryShowRegisterVerifyMobile() {
        
        view.endEditing(true)
        
        let mobile = mobileNumberTextField.text
        let areaCode = areaCodeTextField.text

        validateMobile(mobile, withAreaCode: areaCode, failureHandler: nil) { (available, message) in
            if available {
                println("ValidateMobile: available")

                registerMobile(mobile, withAreaCode: areaCode, nickname: YepUserDefaults.nickname()!, failureHandler: { (reason, errorMessage) in
                    defaultFailureHandler(reason, errorMessage)

                    if let errorMessage = errorMessage {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            YepAlert.alertSorry(message: errorMessage, inViewController: self, withDismissAction: { () -> Void in
                                mobileNumberTextField.becomeFirstResponder()
                            })
                        })
                    }

                }, completion: { created in
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

                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.nextButton.enabled = false

                    YepAlert.alertSorry(message: message, inViewController: self, withDismissAction: { () -> Void in
                        mobileNumberTextField.becomeFirstResponder()
                    })
                })
            }
        }

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
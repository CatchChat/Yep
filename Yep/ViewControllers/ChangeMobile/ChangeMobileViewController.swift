//
//  ChangeMobileViewController.swift
//  Yep
//
//  Created by NIX on 16/5/4.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import Ruler

final class ChangeMobileViewController: UIViewController {

    @IBOutlet private weak var changeMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var changeMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var currentMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var currentMobileNumberLabel: UILabel!

    @IBOutlet private weak var areaCodeTextField: BorderTextField!
    @IBOutlet private weak var areaCodeTextFieldWidthConstraint: NSLayoutConstraint!

    @IBOutlet private weak var mobileNumberTextField: BorderTextField!
    @IBOutlet private weak var mobileNumberTextFieldTopConstraint: NSLayoutConstraint!

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .Plain, target: self, action: #selector(ChangeMobileViewController.next(_:)))
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Change Mobile", comment: ""))

        navigationItem.rightBarButtonItem = nextButton

        changeMobileNumberPromptLabel.text = NSLocalizedString("What's your new number?", comment: "")

        currentMobileNumberPromptLabel.text = NSLocalizedString("Current number:", comment: "")
        currentMobileNumberLabel.text = YepUserDefaults.fullPhoneNumber

        areaCodeTextField.text = NSTimeZone.areaCode
        areaCodeTextField.backgroundColor = UIColor.whiteColor()

        areaCodeTextField.delegate = self
        areaCodeTextField.addTarget(self, action: #selector(ChangeMobileViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)

        mobileNumberTextField.placeholder = ""
        mobileNumberTextField.backgroundColor = UIColor.whiteColor()
        mobileNumberTextField.textColor = UIColor.yepInputTextColor()
        mobileNumberTextField.delegate = self
        mobileNumberTextField.addTarget(self, action: #selector(ChangeMobileViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)

        changeMobileNumberPromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
        mobileNumberTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        nextButton.enabled = false
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        mobileNumberTextField.becomeFirstResponder()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        view.endEditing(true)
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

        guard let areaCode = areaCodeTextField.text, mobile = mobileNumberTextField.text else {
            return
        }

        nextButton.enabled = !areaCode.isEmpty && !mobile.isEmpty

        if textField == areaCodeTextField {
            adjustAreaCodeTextFieldWidth()
        }
    }

    @objc private func next(sender: UIBarButtonItem) {
        tryShowVerifyChangedMobile()
    }

    private func tryShowVerifyChangedMobile() {

        view.endEditing(true)

        guard let areaCode = areaCodeTextField.text, mobile = mobileNumberTextField.text else {
            return
        }

        YepHUD.showActivityIndicator()

        sendVerifyCodeOfNewMobile(mobile, withAreaCode: areaCode, useMethod: .SMS, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepHUD.hideActivityIndicator()

            let errorMessage = errorMessage ?? NSLocalizedString("Failed to send verification code!", comment: "")
            YepAlert.alertSorry(message: errorMessage, inViewController: self, withDismissAction: { () -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    self?.mobileNumberTextField.becomeFirstResponder()
                }
            })

        }, completion: { [weak self] in

            YepHUD.hideActivityIndicator()

            dispatch_async(dispatch_get_main_queue()) {
                self?.showVerifyChangedMobile()
            }
        })
    }

    private func showVerifyChangedMobile() {

        guard let areaCode = areaCodeTextField.text, mobile = mobileNumberTextField.text else {
            return
        }

        performSegueWithIdentifier("showVerifyChangedMobile", sender: ["mobile" : mobile, "areaCode": areaCode])
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showVerifyChangedMobile" {

            if let info = sender as? [String: String] {
                let vc = segue.destinationViewController as! VerifyChangedMobileViewController

                vc.mobile = info["mobile"]
                vc.areaCode = info["areaCode"]
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension ChangeMobileViewController: UITextFieldDelegate {

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

        guard let areaCode = areaCodeTextField.text, mobile = mobileNumberTextField.text else {
            return true
        }

        if !areaCode.isEmpty && !mobile.isEmpty {
            tryShowVerifyChangedMobile()
        }
        
        return true
    }
}


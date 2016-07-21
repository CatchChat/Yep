//
//  LoginVerifyMobileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepNetworking
import YepKit
import Ruler
import RxSwift
import RxCocoa

final class LoginVerifyMobileViewController: UIViewController {

    var mobile: String!
    var areaCode: String!

    private lazy var disposeBag = DisposeBag()

    @IBOutlet private weak var verifyMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var verifyMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var phoneNumberLabel: UILabel!

    @IBOutlet private weak var verifyCodeTextField: BorderTextField!
    @IBOutlet private weak var verifyCodeTextFieldTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var callMePromptLabel: UILabel!
    @IBOutlet private weak var callMeButton: UIButton!
    @IBOutlet private weak var callMeButtonTopConstraint: NSLayoutConstraint!

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = NSLocalizedString("Next", comment: "")
        button.rx_tap
            .subscribeNext({ [weak self] in self?.login() })
            .addDisposableTo(self.disposeBag)
        return button
    }()

    private lazy var callMeTimer: NSTimer = {
        let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(LoginVerifyMobileViewController.tryCallMe(_:)), userInfo: nil, repeats: true)
        return timer
    }()

    private var haveAppropriateInput = false {
        willSet {
            nextButton.enabled = newValue

            if newValue {
                login()
            }
        }
    }

    private var callMeInSeconds = YepConfig.callMeInSeconds()

    deinit {
        callMeTimer.invalidate()

        println("deinit LoginVerifyMobile")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Login", comment: ""))

        navigationItem.rightBarButtonItem = nextButton

        NSNotificationCenter.defaultCenter()
            .rx_notification(AppDelegate.Notification.applicationDidBecomeActive)
            .subscribeNext({ [weak self] _ in self?.verifyCodeTextField.becomeFirstResponder() })
            .addDisposableTo(disposeBag)

        verifyMobileNumberPromptLabel.text = NSLocalizedString("Input verification code sent to", comment: "")

        phoneNumberLabel.text = "+" + areaCode + " " + mobile

        verifyCodeTextField.placeholder = " "
        verifyCodeTextField.backgroundColor = UIColor.whiteColor()
        verifyCodeTextField.textColor = UIColor.yepInputTextColor()
        verifyCodeTextField.addTarget(self, action: #selector(LoginVerifyMobileViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)

        callMePromptLabel.text = NSLocalizedString("Didn't get it?", comment: "")
        callMeButton.setTitle(NSLocalizedString("Call me", comment: ""), forState: .Normal)

        verifyMobileNumberPromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
        verifyCodeTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value
        callMeButtonTopConstraint.constant = Ruler.iPhoneVertical(10, 20, 40, 40).value
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        nextButton.enabled = false
        callMeButton.enabled = false
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        verifyCodeTextField.becomeFirstResponder()

        callMeTimer.fire()
    }

    // MARK: Actions

    @objc private func tryCallMe(timer: NSTimer) {
        if !haveAppropriateInput {
            if callMeInSeconds > 1 {
                let callMeInSecondsString = NSLocalizedString("Call me", comment: "") + " (\(callMeInSeconds))"

                UIView.performWithoutAnimation {
                    self.callMeButton.setTitle(callMeInSecondsString, forState: .Normal)
                    self.callMeButton.layoutIfNeeded()
                }

            } else {
                UIView.performWithoutAnimation {
                    self.callMeButton.setTitle(NSLocalizedString("Call me", comment: ""), forState: .Normal)
                    self.callMeButton.layoutIfNeeded()
                }

                callMeButton.enabled = true
            }
        }

        if (callMeInSeconds > 1) {
            callMeInSeconds -= 1
        }
    }

    @IBAction private func callMe(sender: UIButton) {
        
        callMeTimer.invalidate()

        UIView.performWithoutAnimation {
            self.callMeButton.setTitle(NSLocalizedString("Calling", comment: ""), forState: .Normal)
            self.callMeButton.layoutIfNeeded()
        }

        delay(5) {
            UIView.performWithoutAnimation {
                self.callMeButton.setTitle(NSLocalizedString("Call me", comment: ""), forState: .Normal)
                self.callMeButton.layoutIfNeeded()
            }
        }

        sendVerifyCodeOfMobile(mobile, withAreaCode: areaCode, useMethod: .Call, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            if let errorMessage = errorMessage {

                YepAlert.alertSorry(message: errorMessage, inViewController: self)

                SafeDispatch.async {
                    UIView.performWithoutAnimation {
                        self?.callMeButton.setTitle(NSLocalizedString("Call me", comment: ""), forState: .Normal)
                        self?.callMeButton.layoutIfNeeded()
                    }
                }
            }

        }, completion: { success in
            println("resendVoiceVerifyCode \(success)")
        })
    }

    @objc private func textFieldDidChange(textField: UITextField) {
        guard let text = textField.text else {
            return
        }

        haveAppropriateInput = (text.characters.count == YepConfig.verifyCodeLength())
    }

    private func login() {

        view.endEditing(true)

        guard let verifyCode = verifyCodeTextField.text else {
            return
        }

        YepHUD.showActivityIndicator()

        loginByMobile(mobile, withAreaCode: areaCode, verifyCode: verifyCode, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepHUD.hideActivityIndicator()

            if let errorMessage = errorMessage {
                SafeDispatch.async {
                    self?.nextButton.enabled = false
                }

                YepAlert.alertSorry(message: errorMessage, inViewController: self, withDismissAction: {
                    SafeDispatch.async {
                        self?.verifyCodeTextField.becomeFirstResponder()
                    }
                })
            }

        }, completion: { loginUser in

            println("loginUser: \(loginUser)")

            YepHUD.hideActivityIndicator()

            SafeDispatch.async {

                saveTokenAndUserInfoOfLoginUser(loginUser)
                
                syncMyInfoAndDoFurtherAction {
                }

                if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                    appDelegate.startMainStory()
                }
            }
        })
    }
}


//
//  VerifyChangedMobileViewController.swift
//  Yep
//
//  Created by NIX on 16/5/4.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import Ruler
import RxSwift
import RxCocoa

final class VerifyChangedMobileViewController: UIViewController {

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
        button.title = NSLocalizedString("Submit", comment: "")
        button.rx_tap
            .subscribeNext({ [weak self] in self?.confirmNewMobile() })
            .addDisposableTo(self.disposeBag)
        return button
    }()

    private lazy var callMeTimer: NSTimer = {
        let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(VerifyChangedMobileViewController.tryCallMe(_:)), userInfo: nil, repeats: true)
        return timer
    }()

    private var haveAppropriateInput = false {
        didSet {
            nextButton.enabled = haveAppropriateInput

            if (oldValue != haveAppropriateInput) && haveAppropriateInput {
                confirmNewMobile()
            }
        }
    }

    private var callMeInSeconds = YepConfig.callMeInSeconds()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: String.trans_titleChangeMobile)

        navigationItem.rightBarButtonItem = nextButton

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VerifyChangedMobileViewController.activeAgain(_:)), name: AppDelegate.Notification.applicationDidBecomeActive, object: nil)

        verifyMobileNumberPromptLabel.text = NSLocalizedString("Input verification code sent to", comment: "")
        phoneNumberLabel.text = "+" + areaCode + " " + mobile

        verifyCodeTextField.placeholder = " "
        verifyCodeTextField.backgroundColor = UIColor.whiteColor()
        verifyCodeTextField.textColor = UIColor.yepInputTextColor()
        verifyCodeTextField.rx_text
            .map({ $0.characters.count == YepConfig.verifyCodeLength() })
            .subscribeNext({ [weak self] in self?.haveAppropriateInput = $0 })
            .addDisposableTo(disposeBag)

        callMePromptLabel.text = NSLocalizedString("Didn't get it?", comment: "")
        callMeButton.setTitle(String.trans_buttonCallMe, forState: .Normal)

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

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        view.endEditing(true)
    }

    // MARK: Actions

    @objc private func activeAgain(notification: NSNotification) {
        verifyCodeTextField.becomeFirstResponder()
    }

    @objc private func tryCallMe(timer: NSTimer) {
        if !haveAppropriateInput {
            if callMeInSeconds > 1 {
                let callMeInSecondsString = String.trans_buttonCallMe + " (\(callMeInSeconds))"

                UIView.performWithoutAnimation { [weak self] in
                    self?.callMeButton.setTitle(callMeInSecondsString, forState: .Normal)
                    self?.callMeButton.layoutIfNeeded()
                }

            } else {
                UIView.performWithoutAnimation { [weak self] in
                    self?.callMeButton.setTitle(String.trans_buttonCallMe, forState: .Normal)
                    self?.callMeButton.layoutIfNeeded()
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

        UIView.performWithoutAnimation { [weak self] in
            self?.callMeButton.setTitle(String.trans_buttonCalling, forState: .Normal)
            self?.callMeButton.layoutIfNeeded()
            self?.callMeButton.enabled = false
        }

        delay(10) {
            UIView.performWithoutAnimation { [weak self] in
                self?.callMeButton.setTitle(String.trans_buttonCallMe, forState: .Normal)
                self?.callMeButton.layoutIfNeeded()
                self?.callMeButton.enabled = true
            }
        }

        sendVerifyCodeOfNewMobile(mobile, withAreaCode: areaCode, useMethod: .Call, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            let errorMessage = errorMessage ?? "Error: call for verify code"

            YepAlert.alertSorry(message: errorMessage, inViewController: self)

            SafeDispatch.async {
                UIView.performWithoutAnimation { [weak self] in
                    self?.callMeButton.setTitle(String.trans_buttonCallMe, forState: .Normal)
                    self?.callMeButton.layoutIfNeeded()
                }
            }

        }, completion: { success in
            println("sendVerifyCodeOfNewMobile .Call \(success)")
        })
    }

    private func confirmNewMobile() {

        view.endEditing(true)

        guard let verifyCode = verifyCodeTextField.text else {
            return
        }

        YepHUD.showActivityIndicator()

        comfirmNewMobile(mobile, withAreaCode: areaCode, verifyCode: verifyCode, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepHUD.hideActivityIndicator()

            SafeDispatch.async {  [weak self] in
                self?.nextButton.enabled = false
            }

            let errorMessage = errorMessage ?? ""

            YepAlert.alertSorry(message: errorMessage, inViewController: self, withDismissAction: {
                SafeDispatch.async { [weak self] in
                    self?.verifyCodeTextField.text = nil
                    self?.verifyCodeTextField.becomeFirstResponder()
                }
            })

        }, completion: {

            YepHUD.hideActivityIndicator()

            SafeDispatch.async { [weak self] in
                if let strongSelf = self {
                    YepUserDefaults.areaCode.value = strongSelf.areaCode
                    YepUserDefaults.mobile.value = strongSelf.mobile
                }
            }

            YepAlert.alert(title: NSLocalizedString("Success", comment: ""), message: NSLocalizedString("You have successfully updated your mobile for Yep! For now on, using the new number to login.", comment: ""), dismissTitle: NSLocalizedString("OK", comment: ""), inViewController: self, withDismissAction: { [weak self] in

                self?.performSegueWithIdentifier("unwindToEditProfile", sender: nil)
            })
        })
    }
}


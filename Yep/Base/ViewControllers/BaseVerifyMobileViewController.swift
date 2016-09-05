//
//  BaseVerifyMobileViewController.swift
//  Yep
//
//  Created by NIX on 16/8/16.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import Ruler
import RxSwift
import RxCocoa

class BaseVerifyMobileViewController: SegueViewController {

    var mobilePhone: MobilePhone! {
        return sharedStore().state.mobilePhone
    }

    private lazy var disposeBag = DisposeBag()

    @IBOutlet private weak var verifyMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var verifyMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var phoneNumberLabel: UILabel!

    @IBOutlet weak var verifyCodeTextField: BorderTextField!
    @IBOutlet private weak var verifyCodeTextFieldTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var callMePromptLabel: UILabel!
    @IBOutlet private weak var callMeButton: UIButton!
    @IBOutlet private weak var callMeButtonTopConstraint: NSLayoutConstraint!

    lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = String.trans_buttonNextStep
        button.rx_tap
            .subscribeNext({ [weak self] in self?.next() })
            .addDisposableTo(self.disposeBag)
        return button
    }()

    private var callMeInSeconds = YepConfig.callMeInSeconds()

    private lazy var callMeTimer: NSTimer = {
        let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(BaseVerifyMobileViewController.tryCallMe(_:)), userInfo: nil, repeats: true)
        return timer
    }()

    private var haveAppropriateInput = false {
        didSet {
            nextButton.enabled = haveAppropriateInput

            if (oldValue != haveAppropriateInput) && haveAppropriateInput {
                next()
            }
        }
    }

    deinit {
        callMeTimer.invalidate()

        NSNotificationCenter.defaultCenter().removeObserver(self)

        println("deinit BaseVerifyMobile")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.rightBarButtonItem = nextButton

        NSNotificationCenter.defaultCenter()
            .rx_notification(AppDelegate.Notification.applicationDidBecomeActive)
            .subscribeNext({ [weak self] _ in self?.verifyCodeTextField.becomeFirstResponder() })
            .addDisposableTo(disposeBag)

        verifyMobileNumberPromptLabel.text = String.trans_promptInputVerificationCode

        phoneNumberLabel.text = mobilePhone?.fullNumber

        verifyCodeTextField.placeholder = " "
        verifyCodeTextField.backgroundColor = UIColor.whiteColor()
        verifyCodeTextField.textColor = UIColor.yepInputTextColor()
        verifyCodeTextField.rx_text
            .map({ $0.characters.count == YepConfig.verifyCodeLength() })
            .subscribeNext({ [weak self] in self?.haveAppropriateInput = $0 })
            .addDisposableTo(disposeBag)

        callMePromptLabel.text = String.trans_promptDidNotGetIt
        callMeButton.setTitle(String.trans_buttonCallMe, forState: .Normal)

        verifyMobileNumberPromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
        verifyCodeTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value
        callMeButtonTopConstraint.constant = Ruler.iPhoneVertical(10, 20, 40, 40).value
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        nextButton.enabled = false
        callMeButton.enabled = false

        verifyCodeTextField.text = nil
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

    @objc private func tryCallMe(timer: NSTimer) {

        if !haveAppropriateInput {
            if callMeInSeconds > 1 {
                let callMeInSecondsString = String.trans_buttonCallMe + " (\(callMeInSeconds))"

                UIView.performWithoutAnimation { [weak self] in
                    self?.callMeButton.setTitle(callMeInSecondsString, forState: .Normal)
                    self?.callMeButton.layoutIfNeeded()
                }

            } else {
                UIView.performWithoutAnimation {  [weak self] in
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

        requestCallMe()
    }

    func requestCallMeFailed(errorMessage: String?) {

        let message = errorMessage ?? "Call me failed!"
        YepAlert.alertSorry(message: message, inViewController: self)

        SafeDispatch.async {
            UIView.performWithoutAnimation { [weak self] in
                self?.callMeButton.setTitle(String.trans_buttonCallMe, forState: .Normal)
                self?.callMeButton.layoutIfNeeded()
                self?.callMeButton.enabled = true
            }
        }
    }

    func requestCallMe() {

        assert(false, "Must override requestCallMe")
    }

    func next() {

        assert(false, "Must override next")
    }
}


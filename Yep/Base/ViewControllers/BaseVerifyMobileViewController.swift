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

    fileprivate lazy var disposeBag = DisposeBag()

    @IBOutlet fileprivate weak var verifyMobileNumberPromptLabel: UILabel!
    @IBOutlet fileprivate weak var verifyMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet fileprivate weak var phoneNumberLabel: UILabel!

    @IBOutlet weak var verifyCodeTextField: BorderTextField!
    @IBOutlet fileprivate weak var verifyCodeTextFieldTopConstraint: NSLayoutConstraint!

    @IBOutlet fileprivate weak var callMePromptLabel: UILabel!
    @IBOutlet fileprivate weak var callMeButton: UIButton!
    @IBOutlet fileprivate weak var callMeButtonTopConstraint: NSLayoutConstraint!

    lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = String.trans_buttonNextStep
        button.rx.tap
            .subscribe(onNext: { [weak self] in self?.next() })
            .addDisposableTo(self.disposeBag)
        return button
    }()

    fileprivate var callMeInSeconds = YepConfig.callMeInSeconds()

    fileprivate lazy var callMeTimer: Timer = {
        let timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(BaseVerifyMobileViewController.tryCallMe(_:)), userInfo: nil, repeats: true)
        return timer
    }()

    fileprivate var haveAppropriateInput = false {
        didSet {
            nextButton.isEnabled = haveAppropriateInput

            if (oldValue != haveAppropriateInput) && haveAppropriateInput {
                next()
            }
        }
    }

    deinit {
        callMeTimer.invalidate()

        NotificationCenter.default.removeObserver(self)

        println("deinit BaseVerifyMobile")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.rightBarButtonItem = nextButton

        NotificationCenter.default
            .rx.notification(YepConfig.NotificationName.applicationDidBecomeActive)
            .subscribe(onNext: { [weak self] _ in self?.verifyCodeTextField.becomeFirstResponder() })
            .addDisposableTo(disposeBag)

        verifyMobileNumberPromptLabel.text = String.trans_promptInputVerificationCode

        phoneNumberLabel.text = mobilePhone?.fullNumber

        verifyCodeTextField.placeholder = " "
        verifyCodeTextField.backgroundColor = UIColor.white
        verifyCodeTextField.textColor = UIColor.yepInputTextColor()
        verifyCodeTextField.rx.textInput.text
            .map({ $0.characters.count == YepConfig.verifyCodeLength() })
            .subscribe(onNext: { [weak self] in self?.haveAppropriateInput = $0 })
            .addDisposableTo(disposeBag)

        callMePromptLabel.text = String.trans_promptDidNotGetIt
        callMeButton.setTitle(String.trans_buttonCallMe, for: UIControlState())

        verifyMobileNumberPromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
        verifyCodeTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value
        callMeButtonTopConstraint.constant = Ruler.iPhoneVertical(10, 20, 40, 40).value
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        nextButton.isEnabled = false
        callMeButton.isEnabled = false

        verifyCodeTextField.text = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        verifyCodeTextField.becomeFirstResponder()
        
        callMeTimer.fire()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        view.endEditing(true)
    }

    // MARK: Actions

    @objc fileprivate func tryCallMe(_ timer: Timer) {

        if !haveAppropriateInput {
            if callMeInSeconds > 1 {
                let callMeInSecondsString = String.trans_buttonCallMe + " (\(callMeInSeconds))"

                UIView.performWithoutAnimation { [weak self] in
                    self?.callMeButton.setTitle(callMeInSecondsString, for: UIControlState())
                    self?.callMeButton.layoutIfNeeded()
                }

            } else {
                UIView.performWithoutAnimation {  [weak self] in
                    self?.callMeButton.setTitle(String.trans_buttonCallMe, for: UIControlState())
                    self?.callMeButton.layoutIfNeeded()
                }

                callMeButton.isEnabled = true
            }
        }

        if (callMeInSeconds > 1) {
            callMeInSeconds -= 1
        }
    }

    @IBAction fileprivate func callMe(_ sender: UIButton) {

        callMeTimer.invalidate()

        UIView.performWithoutAnimation { [weak self] in
            self?.callMeButton.setTitle(String.trans_buttonCalling, for: UIControlState())
            self?.callMeButton.layoutIfNeeded()
            self?.callMeButton.isEnabled = false
        }

        _ = delay(10) {
            UIView.performWithoutAnimation { [weak self] in
                self?.callMeButton.setTitle(String.trans_buttonCallMe, for: .normal)
                self?.callMeButton.layoutIfNeeded()
                self?.callMeButton.isEnabled = true
            }
        }

        requestCallMe()
    }

    func requestCallMeFailed(_ errorMessage: String?) {

        let message = errorMessage ?? "Call me failed!"
        YepAlert.alertSorry(message: message, inViewController: self)

        SafeDispatch.async {
            UIView.performWithoutAnimation { [weak self] in
                self?.callMeButton.setTitle(String.trans_buttonCallMe, for: .normal)
                self?.callMeButton.layoutIfNeeded()
                self?.callMeButton.isEnabled = true
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


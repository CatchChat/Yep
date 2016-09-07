//
//  LoginByMobileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import Ruler
import RxSwift
import RxCocoa

final class LoginByMobileViewController: BaseInputMobileViewController {

    private lazy var disposeBag = DisposeBag()

    @IBOutlet private weak var pickMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var pickMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = String.trans_buttonNextStep
        button.rx_tap
            .subscribeNext({ [weak self] in self?.tryShowLoginVerifyMobile() })
            .addDisposableTo(self.disposeBag)
        return button
    }()

    deinit {
        println("deinit LoginByMobile")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: String.trans_titleLogin)
   
        navigationItem.rightBarButtonItem = nextButton

        pickMobileNumberPromptLabel.text = NSLocalizedString("What's your number?", comment: "")

        areaCodeTextField.text = NSTimeZone.areaCode
        areaCodeTextField.backgroundColor = UIColor.whiteColor()
        areaCodeTextField.delegate = self
        areaCodeTextField.rx_text
            .subscribeNext({ [weak self] _ in self?.adjustAreaCodeTextFieldWidth() })
            .addDisposableTo(disposeBag)

        mobileNumberTextField.placeholder = ""
        mobileNumberTextField.backgroundColor = UIColor.whiteColor()
        mobileNumberTextField.textColor = UIColor.yepInputTextColor()
        mobileNumberTextField.delegate = self

        Observable.combineLatest(areaCodeTextField.rx_text, mobileNumberTextField.rx_text) { !$0.isEmpty && !$1.isEmpty }
            .bindTo(nextButton.rx_enabled)
            .addDisposableTo(disposeBag)

        pickMobileNumberPromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
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

    override func tappedKeyboardReturn() {
        tryShowLoginVerifyMobile()
    }
    
    func tryShowLoginVerifyMobile() {
        
        view.endEditing(true)

        guard let areaCode = areaCodeTextField.text, number = mobileNumberTextField.text else {
            return
        }
        let mobilePhone = MobilePhone(areaCode: areaCode, number: number)
        sharedStore().dispatch(MobilePhoneUpdateAction(mobilePhone: mobilePhone))

        YepHUD.showActivityIndicator()
        
        requestSendVerifyCodeOfMobilePhone(mobilePhone, useMethod: .SMS, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepHUD.hideActivityIndicator()

            if case .NoSuccessStatusCode(_, let errorCode) = reason where errorCode == .NotYetRegistered {

                YepAlert.confirmOrCancel(title: String.trans_titleNotice, message: String(format: NSLocalizedString("This number (%@) not yet registered! Would you like to register it now?", comment: ""), mobilePhone.fullNumber), confirmTitle: String.trans_titleOK, cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: { [weak self] in

                    self?.performSegueWithIdentifier("showRegisterPickName", sender: nil)

                }, cancelAction: {
                })

            } else {
                if let errorMessage = errorMessage {
                    YepAlert.alertSorry(message: errorMessage, inViewController: self, withDismissAction: {
                        SafeDispatch.async { [weak self] in
                            self?.mobileNumberTextField.becomeFirstResponder()
                        }
                    })
                }
            }

        }, completion: { success in

            YepHUD.hideActivityIndicator()

            if success {
                SafeDispatch.async { [weak self] in
                    self?.showLoginVerifyMobile()
                }

            } else {
                YepAlert.alertSorry(message: String.trans_promptRequestSendVerificationCodeFailed, inViewController: self, withDismissAction: { [weak self] in
                    self?.mobileNumberTextField.becomeFirstResponder()
                })
            }
        })
    }

    private func showLoginVerifyMobile() {

        guard let areaCode = areaCodeTextField.text, number = mobileNumberTextField.text else {
            return
        }
        let mobilePhone = MobilePhone(areaCode: areaCode, number: number)
        sharedStore().dispatch(MobilePhoneUpdateAction(mobilePhone: mobilePhone))

        self.performSegueWithIdentifier("showLoginVerifyMobile", sender: nil)
    }
}


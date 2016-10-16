//
//  LoginByMobileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Ruler
import RxSwift
import RxCocoa

final class LoginByMobileViewController: BaseInputMobileViewController {

    fileprivate lazy var disposeBag = DisposeBag()

    @IBOutlet fileprivate weak var pickMobileNumberPromptLabel: UILabel!
    @IBOutlet fileprivate weak var pickMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    fileprivate lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = String.trans_buttonNextStep
        button.rx.tap
            .subscribe(onNext: { [weak self] in self?.tryShowLoginVerifyMobile() })
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

        areaCodeTextField.text = TimeZone.areaCode
        areaCodeTextField.backgroundColor = UIColor.white
        areaCodeTextField.delegate = self
        areaCodeTextField.rx.textInput.text
            .subscribe(onNext: { [weak self] _ in self?.adjustAreaCodeTextFieldWidth() })
            .addDisposableTo(disposeBag)

        mobileNumberTextField.placeholder = ""
        mobileNumberTextField.backgroundColor = UIColor.white
        mobileNumberTextField.textColor = UIColor.yepInputTextColor()
        mobileNumberTextField.delegate = self

        Observable.combineLatest(areaCodeTextField.rx.textInput.text, mobileNumberTextField.rx.textInput.text) { !$0.isEmpty && !$1.isEmpty }
            .bindTo(nextButton.rx.enabled)
            .addDisposableTo(disposeBag)

        pickMobileNumberPromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        nextButton.isEnabled = false

        mobileNumberTextField.becomeFirstResponder()
    }

    // MARK: Actions

    override func tappedKeyboardReturn() {
        tryShowLoginVerifyMobile()
    }
    
    func tryShowLoginVerifyMobile() {
        
        view.endEditing(true)

        guard let areaCode = areaCodeTextField.text, let number = mobileNumberTextField.text else {
            return
        }
        let mobilePhone = MobilePhone(areaCode: areaCode, number: number)
        sharedStore().dispatch(MobilePhoneUpdateAction(mobilePhone: mobilePhone))

        YepHUD.showActivityIndicator()
        
        requestSendVerifyCodeOfMobilePhone(mobilePhone, useMethod: .sms, failureHandler: { reason, errorMessage in

            YepHUD.hideActivityIndicator()

            if case .noSuccessStatusCode(_, let errorCode) = reason, errorCode == .notYetRegistered {

                YepAlert.confirmOrCancel(title: String.trans_titleNotice, message: String(format: NSLocalizedString("This number (%@) not yet registered! Would you like to register it now?", comment: ""), mobilePhone.fullNumber), confirmTitle: String.trans_titleOK, cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: { [weak self] in

                    self?.performSegue(withIdentifier: "showRegisterPickName", sender: nil)

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

    fileprivate func showLoginVerifyMobile() {

        guard let areaCode = areaCodeTextField.text, let number = mobileNumberTextField.text else {
            return
        }
        let mobilePhone = MobilePhone(areaCode: areaCode, number: number)
        sharedStore().dispatch(MobilePhoneUpdateAction(mobilePhone: mobilePhone))

        self.performSegue(withIdentifier: "showLoginVerifyMobile", sender: nil)
    }
}


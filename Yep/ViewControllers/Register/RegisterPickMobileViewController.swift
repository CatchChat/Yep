//
//  RegisterPickMobileViewController.swift
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

final class RegisterPickMobileViewController: BaseInputMobileViewController {

    private lazy var disposeBag = DisposeBag()
    
    @IBOutlet private weak var pickMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var pickMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = String.trans_buttonNextStep
        button.rx_tap
            .subscribeNext({ [weak self] in self?.tryShowRegisterVerifyMobile() })
            .addDisposableTo(self.disposeBag)
        return button
    }()

    deinit {
        println("deinit RegisterPickMobile")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Sign Up", comment: ""))

        navigationItem.rightBarButtonItem = nextButton

        pickMobileNumberPromptLabel.text = NSLocalizedString("What's your number?", comment: "")

        let mobilePhone = sharedStore().state.mobilePhone

        areaCodeTextField.text = mobilePhone?.areaCode ?? NSTimeZone.areaCode
        areaCodeTextField.backgroundColor = UIColor.whiteColor()
        areaCodeTextField.delegate = self
        areaCodeTextField.rx_text
            .subscribeNext({ [weak self] _ in self?.adjustAreaCodeTextFieldWidth() })
            .addDisposableTo(disposeBag)

        //mobileNumberTextField.placeholder = ""
        mobileNumberTextField.text = mobilePhone?.number
        mobileNumberTextField.backgroundColor = UIColor.whiteColor()
        mobileNumberTextField.textColor = UIColor.yepInputTextColor()
        mobileNumberTextField.delegate = self

        Observable.combineLatest(areaCodeTextField.rx_text, mobileNumberTextField.rx_text) { !$0.isEmpty && !$1.isEmpty }
            .bindTo(nextButton.rx_enabled)
            .addDisposableTo(disposeBag)

        pickMobileNumberPromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value

        if mobilePhone?.number == nil {
            nextButton.enabled = false
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        mobileNumberTextField.becomeFirstResponder()
    }

    // MARK: Actions

    override func tappedKeyboardReturn() {
        tryShowRegisterVerifyMobile()
    }

    func tryShowRegisterVerifyMobile() {
        
        view.endEditing(true)
        
        guard let number = mobileNumberTextField.text, areaCode = areaCodeTextField.text else {
            return
        }
        let mobilePhone = MobilePhone(areaCode: areaCode, number: number)
        sharedStore().dispatch(MobilePhoneUpdateAction(mobilePhone: mobilePhone))

        YepHUD.showActivityIndicator()
        
        validateMobilePhone(mobilePhone, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)
            
            YepHUD.hideActivityIndicator()

        }, completion: { (available, message) in

            if available, let nickname = YepUserDefaults.nickname.value {
                println("ValidateMobile: available")

                registerMobilePhone(mobilePhone, nickname: nickname, failureHandler: { (reason, errorMessage) in
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
                        SafeDispatch.async { [weak self] in
                            self?.performSegueWithIdentifier("showRegisterVerifyMobile", sender: nil)
                        }

                    } else {
                        SafeDispatch.async { [weak self] in
                            self?.nextButton.enabled = false

                            YepAlert.alertSorry(message: "registerMobile failed", inViewController: self, withDismissAction: { [weak self] in
                                self?.mobileNumberTextField.becomeFirstResponder()
                            })
                        }
                    }
                })

            } else {
                println("ValidateMobile: \(message)")

                YepHUD.hideActivityIndicator()

                SafeDispatch.async { [weak self] in
                    self?.nextButton.enabled = false

                    YepAlert.alertSorry(message: message, inViewController: self, withDismissAction: { [weak self] in
                        self?.mobileNumberTextField.becomeFirstResponder()
                    })
                }
            }
        })
    }
}


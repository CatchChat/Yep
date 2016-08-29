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

final class RegisterPickMobileViewController: SegueViewController {

    private lazy var disposeBag = DisposeBag()
    
    @IBOutlet private weak var pickMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var pickMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var areaCodeTextField: BorderTextField!
    @IBOutlet weak var areaCodeTextFieldWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var mobileNumberTextField: BorderTextField!
    @IBOutlet private weak var mobileNumberTextFieldTopConstraint: NSLayoutConstraint!

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = NSLocalizedString("Next", comment: "")
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

        let mobilePhone = mainStore.state.mobilePhone

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
        mobileNumberTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value

        if mobilePhone?.number == nil {
            nextButton.enabled = false
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        mobileNumberTextField.becomeFirstResponder()
    }

    // MARK: Actions

    func tryShowRegisterVerifyMobile() {
        
        view.endEditing(true)
        
        guard let number = mobileNumberTextField.text, areaCode = areaCodeTextField.text else {
            return
        }
        let mobilePhone = MobilePhone(areaCode: areaCode, number: number)
        mainStore.dispatch(MobilePhoneUpdateAction(mobilePhone: mobilePhone))

        YepHUD.showActivityIndicator()
        
        validateMobile(mobilePhone.number, withAreaCode: areaCode, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)
            
            YepHUD.hideActivityIndicator()

        }, completion: { (available, message) in
            if available, let nickname = YepUserDefaults.nickname.value {
                println("ValidateMobile: available")

                registerMobile(mobilePhone.number, withAreaCode: areaCode, nickname: nickname, failureHandler: { (reason, errorMessage) in
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
                            self.performSegueWithIdentifier("showRegisterVerifyMobile", sender: nil)
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

                SafeDispatch.async {

                    self.nextButton.enabled = false

                    YepAlert.alertSorry(message: message, inViewController: self, withDismissAction: { [weak self] in
                        self?.mobileNumberTextField.becomeFirstResponder()
                    })
                }
            }
        })
    }
}


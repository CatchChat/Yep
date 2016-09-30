//
//  LoginVerifyMobileViewController.swift
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

final class LoginVerifyMobileViewController: BaseVerifyMobileViewController {

    deinit {
        println("deinit LoginVerifyMobile")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = NavigationTitleLabel(title: String.trans_titleLogin)
    }

    // MARK: Actions

    override func requestCallMe() {

        requestSendVerifyCodeOfMobilePhone(mobilePhone, useMethod: .call, failureHandler: { [weak self ]reason, errorMessage in

            self?.requestCallMeFailed(errorMessage)

        }, completion: { success in
            println("resendVoiceVerifyCode \(success)")
        })
    }

    override func next() {

        tryLogin()
    }

    fileprivate func tryLogin() {

        view.endEditing(true)

        guard let verifyCode = verifyCodeTextField.text else {
            return
        }

        YepHUD.showActivityIndicator()

        loginByMobilePhone(mobilePhone, withVerifyCode: verifyCode, failureHandler: { (reason, errorMessage) in

            YepHUD.hideActivityIndicator()

            SafeDispatch.async { [weak self] in
                self?.nextButton.isEnabled = false
            }

            let message = errorMessage ?? "Login failed!"
            YepAlert.alertSorry(message: message, inViewController: self, withDismissAction: {
                SafeDispatch.async { [weak self] in
                    self?.verifyCodeTextField.text = nil
                    self?.verifyCodeTextField.becomeFirstResponder()
                }
            })

        }, completion: { loginUser in

            println("loginUser: \(loginUser)")

            YepHUD.hideActivityIndicator()

            sharedStore().dispatch(MobilePhoneUpdateAction(mobilePhone: nil))

            SafeDispatch.async {

                saveTokenAndUserInfoOfLoginUser(loginUser)
                
                syncMyInfoAndDoFurtherAction {
                }

                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    appDelegate.startMainStory()
                }
            }
        })
    }
}


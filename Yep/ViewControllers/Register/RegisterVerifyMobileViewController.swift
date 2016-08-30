//
//  RegisterVerifyMobileViewController.swift
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

final class RegisterVerifyMobileViewController: BaseVerifyMobileViewController {

    deinit {
        println("deinit RegisterVerifyMobile")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Sign Up", comment: ""))
    }

    // MARK: Actions

    override func requestCallMe() {

        requestSendVerifyCodeOfMobilePhone(mobilePhone, useMethod: .Call, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            self?.requestCallMeFailed(errorMessage)

        }, completion: { success in
            println("resendVoiceVerifyCode \(success)")
        })
    }

    override func next() {

        tryVerifyRegisterMobile()
    }

    private func tryVerifyRegisterMobile() {

        view.endEditing(true)

        guard let verifyCode = verifyCodeTextField.text else {
            return
        }

        YepHUD.showActivityIndicator()

        verifyMobilePhone(mobilePhone, verifyCode: verifyCode, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepHUD.hideActivityIndicator()

            SafeDispatch.async { [weak self] in
                self?.nextButton.enabled = false
            }

            let message = errorMessage ?? "Register verify mobile failed!"
            YepAlert.alertSorry(message: message, inViewController: self, withDismissAction: { [weak self] in
                self?.verifyCodeTextField.text = nil
                self?.verifyCodeTextField.becomeFirstResponder()
            })

        }, completion: { loginUser in

            println("loginUser: \(loginUser)")

            YepHUD.hideActivityIndicator()

            SafeDispatch.async { [weak self] in

                saveTokenAndUserInfoOfLoginUser(loginUser)

                self?.performSegueWithIdentifier("showRegisterPickAvatar", sender: nil)
            }
        })
    }
}


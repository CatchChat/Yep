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

final class VerifyChangedMobileViewController: BaseVerifyMobileViewController {

    deinit {
        println("deinit VerifyChangedMobile")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = NavigationTitleLabel(title: String.trans_titleChangeMobile)

        nextButton.title = NSLocalizedString("Submit", comment: "")
    }

    override func requestCallMe() {

        requestSendVerifyCodeOfNewMobilePhone(mobilePhone, useMethod: .Call, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            self?.requestCallMeFailed(errorMessage)

        }, completion: { success in
            println("sendVerifyCodeOfNewMobile .Call \(success)")
        })
    }

    override func next() {

        tryConfirmNewMobile()
    }

    private func tryConfirmNewMobile() {

        view.endEditing(true)

        guard let verifyCode = verifyCodeTextField.text else {
            return
        }

        YepHUD.showActivityIndicator()

        confirmNewMobilePhone(mobilePhone, withVerifyCode: verifyCode, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepHUD.hideActivityIndicator()

            SafeDispatch.async { [weak self] in
                self?.nextButton.enabled = false
            }

            let message = errorMessage ?? "Confirm new mobile failed!"
            YepAlert.alertSorry(message: message, inViewController: self, withDismissAction: {
                SafeDispatch.async { [weak self] in
                    self?.verifyCodeTextField.text = nil
                    self?.verifyCodeTextField.becomeFirstResponder()
                }
            })

        }, completion: {
            YepHUD.hideActivityIndicator()

            SafeDispatch.async { [weak self] in
                if let strongSelf = self {
                    YepUserDefaults.areaCode.value = strongSelf.mobilePhone.areaCode
                    YepUserDefaults.mobile.value = strongSelf.mobilePhone.number
                }

                sharedStore().dispatch(MobilePhoneUpdateAction(mobilePhone: nil))
            }

            YepAlert.alert(title: NSLocalizedString("Success", comment: ""), message: NSLocalizedString("You have successfully updated your mobile for Yep! For now on, using the new number to login.", comment: ""), dismissTitle: String.trans_titleOK, inViewController: self, withDismissAction: { [weak self] in

                self?.performSegueWithIdentifier("unwindToEditProfile", sender: nil)
            })
        })
    }
}


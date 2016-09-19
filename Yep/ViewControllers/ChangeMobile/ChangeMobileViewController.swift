//
//  ChangeMobileViewController.swift
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

final class ChangeMobileViewController: BaseInputMobileViewController {

    fileprivate lazy var disposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var changeMobileNumberPromptLabel: UILabel!
    @IBOutlet fileprivate weak var changeMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet fileprivate weak var currentMobileNumberPromptLabel: UILabel!
    @IBOutlet fileprivate weak var currentMobileNumberLabel: UILabel!

    fileprivate lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = String.trans_buttonNextStep
        button.rx_tap
            .subscribeNext({ [weak self] in self?.tryShowVerifyChangedMobile() })
            .addDisposableTo(self.disposeBag)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: String.trans_titleChangeMobile)

        navigationItem.rightBarButtonItem = nextButton

        changeMobileNumberPromptLabel.text = NSLocalizedString("What's your new number?", comment: "")

        currentMobileNumberPromptLabel.text = String.trans_promptCurrentNumber
        currentMobileNumberLabel.text = YepUserDefaults.fullPhoneNumber

        areaCodeTextField.text = TimeZone.areaCode
        areaCodeTextField.backgroundColor = UIColor.white

        areaCodeTextField.delegate = self
        areaCodeTextField.rx_text
            .subscribeNext({ [weak self] _ in self?.adjustAreaCodeTextFieldWidth() })
            .addDisposableTo(disposeBag)

        mobileNumberTextField.placeholder = ""
        mobileNumberTextField.backgroundColor = UIColor.white
        mobileNumberTextField.textColor = UIColor.yepInputTextColor()
        mobileNumberTextField.delegate = self

        Observable.combineLatest(areaCodeTextField.rx_text, mobileNumberTextField.rx_text) { !$0.isEmpty && !$1.isEmpty }
            .bindTo(nextButton.rx_enabled)
            .addDisposableTo(disposeBag)

        changeMobileNumberPromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        nextButton.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        mobileNumberTextField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        view.endEditing(true)
    }

    // MARK: Actions

    override func tappedKeyboardReturn() {
        tryShowVerifyChangedMobile()
    }

    func tryShowVerifyChangedMobile() {

        view.endEditing(true)

        guard let areaCode = areaCodeTextField.text, let number = mobileNumberTextField.text else {
            return
        }
        let mobilePhone = MobilePhone(areaCode: areaCode, number: number)
        sharedStore().dispatch(MobilePhoneUpdateAction(mobilePhone: mobilePhone))

        YepHUD.showActivityIndicator()

        requestSendVerifyCodeOfNewMobilePhone(mobilePhone, useMethod: .SMS, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepHUD.hideActivityIndicator()

            let message = errorMessage ?? String.trans_promptRequestSendVerificationCodeFailed
            YepAlert.alertSorry(message: message, inViewController: self, withDismissAction: {
                SafeDispatch.async { [weak self] in
                    self?.mobileNumberTextField.becomeFirstResponder()
                }
            })

        }, completion: {

            YepHUD.hideActivityIndicator()

            SafeDispatch.async { [weak self] in
                self?.showVerifyChangedMobile()
            }
        })
    }

    fileprivate func showVerifyChangedMobile() {

        guard let areaCode = areaCodeTextField.text, let number = mobileNumberTextField.text else {
            return
        }
        let mobilePhone = MobilePhone(areaCode: areaCode, number: number)
        sharedStore().dispatch(MobilePhoneUpdateAction(mobilePhone: mobilePhone))

        performSegue(withIdentifier: "showVerifyChangedMobile", sender: nil)
    }
}


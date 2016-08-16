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

final class ChangeMobileViewController: UIViewController {

    private lazy var disposeBag = DisposeBag()
    
    @IBOutlet private weak var changeMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var changeMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var currentMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var currentMobileNumberLabel: UILabel!

    @IBOutlet weak var areaCodeTextField: BorderTextField!
    @IBOutlet weak var areaCodeTextFieldWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var mobileNumberTextField: BorderTextField!
    @IBOutlet private weak var mobileNumberTextFieldTopConstraint: NSLayoutConstraint!

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = NSLocalizedString("Next", comment: "")
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

        changeMobileNumberPromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
        mobileNumberTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        nextButton.enabled = false
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        mobileNumberTextField.becomeFirstResponder()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        view.endEditing(true)
    }

    // MARK: Actions

    func tryShowVerifyChangedMobile() {

        view.endEditing(true)

        guard let areaCode = areaCodeTextField.text, mobile = mobileNumberTextField.text else {
            return
        }

        YepHUD.showActivityIndicator()

        sendVerifyCodeOfNewMobile(mobile, withAreaCode: areaCode, useMethod: .SMS, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepHUD.hideActivityIndicator()

            let errorMessage = errorMessage ?? NSLocalizedString("Failed to send verification code!", comment: "")
            YepAlert.alertSorry(message: errorMessage, inViewController: self, withDismissAction: { () -> Void in
                SafeDispatch.async {
                    self?.mobileNumberTextField.becomeFirstResponder()
                }
            })

        }, completion: { [weak self] in

            YepHUD.hideActivityIndicator()

            SafeDispatch.async {
                self?.showVerifyChangedMobile()
            }
        })
    }

    private func showVerifyChangedMobile() {

        guard let areaCode = areaCodeTextField.text, mobile = mobileNumberTextField.text else {
            return
        }

        performSegueWithIdentifier("showVerifyChangedMobile", sender: ["mobile" : mobile, "areaCode": areaCode])
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showVerifyChangedMobile" {

            if let info = sender as? [String: String] {
                let vc = segue.destinationViewController as! VerifyChangedMobileViewController

                vc.mobile = info["mobile"]
                vc.areaCode = info["areaCode"]
            }
        }
    }
}


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

final class LoginByMobileViewController: BaseViewController {

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
            .subscribeNext({ [weak self] in self?.tryShowLoginVerifyMobile() })
            .addDisposableTo(self.disposeBag)
        return button
    }()

    deinit {
        println("deinit LoginByMobile")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        animatedOnNavigationBar = false

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Login", comment: ""))
   
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

    // MARK: Actions

    func tryShowLoginVerifyMobile() {
        
        view.endEditing(true)

        guard let areaCode = areaCodeTextField.text, mobile = mobileNumberTextField.text else {
            return
        }

        YepHUD.showActivityIndicator()
        
        sendVerifyCodeOfMobile(mobile, withAreaCode: areaCode, useMethod: .SMS, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepHUD.hideActivityIndicator()

            if case .NoSuccessStatusCode(_, let errorCode) = reason where errorCode == .NotYetRegistered {

                YepAlert.confirmOrCancel(title: NSLocalizedString("Notice", comment: ""), message: String(format: NSLocalizedString("This number (%@) not yet registered! Would you like to register it now?", comment: ""), "+\(areaCode) \(mobile)"), confirmTitle: NSLocalizedString("OK", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: { [weak self] in

                    self?.performSegueWithIdentifier("showRegisterPickName", sender: ["mobile" : mobile, "areaCode": areaCode])

                }, cancelAction: {
                })

            } else {
                if let errorMessage = errorMessage {
                    YepAlert.alertSorry(message: errorMessage, inViewController: self, withDismissAction: { () -> Void in
                        SafeDispatch.async {
                            self?.mobileNumberTextField.becomeFirstResponder()
                        }
                    })
                }
            }

        }, completion: { [weak self] success in

            YepHUD.hideActivityIndicator()

            if success {
                SafeDispatch.async {
                    self?.showLoginVerifyMobile()
                }

            } else {
                YepAlert.alertSorry(message: NSLocalizedString("Failed to send verification code!", comment: ""), inViewController: self, withDismissAction: { [weak self] in
                    self?.mobileNumberTextField.becomeFirstResponder()
                })
            }
        })
    }

    private func showLoginVerifyMobile() {
        guard let areaCode = areaCodeTextField.text, mobile = mobileNumberTextField.text else {
            return
        }

        self.performSegueWithIdentifier("showLoginVerifyMobile", sender: ["mobile" : mobile, "areaCode": areaCode])
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showLoginVerifyMobile":

            if let info = sender as? [String: String] {
                let vc = segue.destinationViewController as! LoginVerifyMobileViewController

                vc.mobile = info["mobile"]
                vc.areaCode = info["areaCode"]
            }

        case "showRegisterPickName":

            if let info = sender as? [String: String] {
                let vc = segue.destinationViewController as! RegisterPickNameViewController

                vc.mobile = info["mobile"]
                vc.areaCode = info["areaCode"]
            }

        default:
            break
        }
    }

}


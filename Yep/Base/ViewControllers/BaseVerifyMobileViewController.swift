//
//  BaseVerifyMobileViewController.swift
//  Yep
//
//  Created by NIX on 16/8/16.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Ruler
import RxSwift
import RxCocoa

class BaseVerifyMobileViewController: UIViewController {

    var mobile: String!
    var areaCode: String!

    private lazy var disposeBag = DisposeBag()

    @IBOutlet private weak var verifyMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var verifyMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var phoneNumberLabel: UILabel!

    @IBOutlet private weak var verifyCodeTextField: BorderTextField!
    @IBOutlet private weak var verifyCodeTextFieldTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var callMePromptLabel: UILabel!
    @IBOutlet private weak var callMeButton: UIButton!
    @IBOutlet private weak var callMeButtonTopConstraint: NSLayoutConstraint!

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = NSLocalizedString("Next", comment: "")
        button.rx_tap
            .subscribeNext({ [weak self] in self?.next() })
            .addDisposableTo(self.disposeBag)
        return button
    }()

    private var callMeInSeconds = YepConfig.callMeInSeconds()

    private lazy var callMeTimer: NSTimer = {
        let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(BaseVerifyMobileViewController.tryCallMe(_:)), userInfo: nil, repeats: true)
        return timer
    }()

    private var haveAppropriateInput = false {
        didSet {
            nextButton.enabled = haveAppropriateInput

            if (oldValue != haveAppropriateInput) && haveAppropriateInput {
                next()
            }
        }
    }

    // MARK: Actions

    @objc private func tryCallMe(timer: NSTimer) {

        if !haveAppropriateInput {
            if callMeInSeconds > 1 {
                let callMeInSecondsString = String.trans_buttonCallMe + " (\(callMeInSeconds))"

                UIView.performWithoutAnimation { [weak self] in
                    self?.callMeButton.setTitle(callMeInSecondsString, forState: .Normal)
                    self?.callMeButton.layoutIfNeeded()
                }

            } else {
                UIView.performWithoutAnimation {  [weak self] in
                    self?.callMeButton.setTitle(String.trans_buttonCallMe, forState: .Normal)
                    self?.callMeButton.layoutIfNeeded()
                }

                callMeButton.enabled = true
            }
        }

        if (callMeInSeconds > 1) {
            callMeInSeconds -= 1
        }
    }

    private func next() {
    }
}


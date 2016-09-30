//
//  FeedbackViewController.swift
//  Yep
//
//  Created by NIX on 15/7/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import KeyboardMan
import DeviceUtil

final class FeedbackViewController: UIViewController {

    @IBOutlet fileprivate weak var promptLabel: UILabel! {
        didSet {
            promptLabel.text = NSLocalizedString("We read every feedback", comment: "")
            promptLabel.textColor = UIColor.darkGray
        }
    }

    @IBOutlet fileprivate weak var feedbackTextView: UITextView! {
        didSet {
            feedbackTextView.text = ""
            feedbackTextView.delegate = self
            feedbackTextView.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        }
    }

    @IBOutlet fileprivate weak var feedbackTextViewTopLineView: HorizontalLineView! {
        didSet {
            feedbackTextViewTopLineView.lineColor = UIColor.lightGray
        }
    }

    @IBOutlet fileprivate weak var feedbackTextViewBottomLineView: HorizontalLineView! {
        didSet {
            feedbackTextViewBottomLineView.lineColor = UIColor.lightGray
        }
    }

    @IBOutlet fileprivate weak var feedbackTextViewBottomConstraint: NSLayoutConstraint! {
        didSet {
            feedbackTextViewBottomConstraint.constant = YepConfig.Feedback.bottomMargin
        }
    }

    fileprivate var isDirty = false {
        willSet {
            navigationItem.rightBarButtonItem?.isEnabled = newValue
        }
    }

    fileprivate let keyboardMan = KeyboardMan()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleFeedback

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(FeedbackViewController.done(_:)))
        navigationItem.rightBarButtonItem = doneBarButtonItem
        navigationItem.rightBarButtonItem?.isEnabled = false

        keyboardMan.animateWhenKeyboardAppear = { [weak self] _, keyboardHeight, _ in
            self?.feedbackTextViewBottomConstraint.constant = keyboardHeight + YepConfig.Feedback.bottomMargin
            self?.view.layoutIfNeeded()
        }

        keyboardMan.animateWhenKeyboardDisappear = { [weak self] keyboardHeight in
            self?.feedbackTextViewBottomConstraint.constant = YepConfig.Feedback.bottomMargin
            self?.view.layoutIfNeeded()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(FeedbackViewController.tap(_:)))
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        feedbackTextView.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        feedbackTextView.resignFirstResponder()
    }

    // MARK: Actions

    @objc fileprivate func tap(_ sender: UITapGestureRecognizer) {
        feedbackTextView.resignFirstResponder()
    }

    @objc fileprivate func done(_ sender: AnyObject) {

        feedbackTextView.resignFirstResponder()

        let deviceInfo = (DeviceUtil.hardwareDescription() ?? "nixDevice") + ", " + ProcessInfo().operatingSystemVersionString
        let feedback = Feedback(content: feedbackTextView.text, deviceInfo: deviceInfo)

        sendFeedback(feedback, failureHandler: { [weak self] (reason, errorMessage) in
            let message = errorMessage ?? "Faild to send feedback!"
            YepAlert.alertSorry(message: message, inViewController: self)

        }, completion: { [weak self] in
            YepAlert.alert(title: NSLocalizedString("Success", comment: ""), message: NSLocalizedString("Thanks! Your feedback has been recorded!", comment: ""), dismissTitle: String.trans_titleOK, inViewController: self, withDismissAction: {

                SafeDispatch.async { [weak self] in
                    _ = self?.navigationController?.popViewController(animated: true)
                }
            })
        })
    }
}

// MARK: - UITextViewDelegate

extension FeedbackViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        isDirty = !textView.text.isEmpty
    }
}


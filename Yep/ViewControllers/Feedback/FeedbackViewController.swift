//
//  FeedbackViewController.swift
//  Yep
//
//  Created by NIX on 15/7/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import KeyboardMan
import DeviceGuru

class FeedbackViewController: UIViewController {

    @IBOutlet weak var promptLabel: UILabel! {
        didSet {
            promptLabel.text = NSLocalizedString("We read every feedback", comment: "")
            promptLabel.textColor = UIColor.darkGrayColor()
        }
    }

    @IBOutlet weak var feedbackTextView: UITextView! {
        didSet {
            feedbackTextView.text = ""
            feedbackTextView.delegate = self
            feedbackTextView.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        }
    }

    @IBOutlet weak var feedbackTextViewBottomConstraint: NSLayoutConstraint! {
        didSet {
            feedbackTextViewBottomConstraint.constant = YepConfig.Feedback.bottomMargin
        }
    }

    var isDirty = false {
        willSet {
            navigationItem.rightBarButtonItem?.enabled = newValue
        }
    }

    let keyboardMan = KeyboardMan()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Feedback", comment: "")

        let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "done")
        navigationItem.rightBarButtonItem = doneBarButtonItem
        navigationItem.rightBarButtonItem?.enabled = false

        keyboardMan.animateWhenKeyboardAppear = { [weak self] _, keyboardHeight, _ in
            self?.feedbackTextViewBottomConstraint.constant = keyboardHeight + YepConfig.Feedback.bottomMargin
            self?.view.layoutIfNeeded()
        }

        keyboardMan.animateWhenKeyboardDisappear = { [weak self] keyboardHeight in
            self?.feedbackTextViewBottomConstraint.constant = YepConfig.Feedback.bottomMargin
            self?.view.layoutIfNeeded()
        }

        let tap = UITapGestureRecognizer(target: self, action: "tap")
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        feedbackTextView.becomeFirstResponder()
    }

    // MARK: Actions

    func tap() {
        feedbackTextView.resignFirstResponder()
    }

    func done() {

        feedbackTextView.resignFirstResponder()

        let deviceInfo = (hardwareDescription() ?? "nixDevice") + ", " + NSProcessInfo().operatingSystemVersionString
        let feedback = Feedback(content: feedbackTextView.text, deviceInfo: deviceInfo)

        sendFeedback(feedback, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason, errorMessage: errorMessage)

            YepAlert.alertSorry(message: NSLocalizedString("Network error!", comment: ""), inViewController: self)

        }, completion: { [weak self] _ in

            YepAlert.alert(title: NSLocalizedString("Success", comment: ""), message: NSLocalizedString("Thanks! Your feedback has been recorded!", comment: ""), dismissTitle: NSLocalizedString("OK", comment: ""), inViewController: self, withDismissAction: {

                dispatch_async(dispatch_get_main_queue()) {
                    self?.navigationController?.popViewControllerAnimated(true)
                }
            })
        })
    }
}

// MARK: - UITextViewDelegate

extension FeedbackViewController: UITextViewDelegate {

    func textViewDidChange(textView: UITextView) {
        isDirty = !textView.text.isEmpty
    }
}


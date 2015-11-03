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

/*
class FeedbackTextView: UITextView {

//    let lineColor: UIColor = UIColor.yepBorderColor()
//    let lineWidth: CGFloat = 1
//
//    lazy var topLineLayer: CAShapeLayer = {
//        let layer = CAShapeLayer()
//        layer.lineWidth = self.lineWidth
//        layer.strokeColor = self.lineColor.CGColor
//        return layer
//        }()
//
//    lazy var bottomLineLayer: CAShapeLayer = {
//        let layer = CAShapeLayer()
//        layer.lineWidth = self.lineWidth
//        layer.strokeColor = self.lineColor.CGColor
//        return layer
//        }()

    lazy var topLineView: HorizontalLineView = HorizontalLineView()
    lazy var bottomLineView: HorizontalLineView = HorizontalLineView()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.whiteColor()

        addSubview(topLineView)
        addSubview(bottomLineView)

        topLineView.translatesAutoresizingMaskIntoConstraints = false
        bottomLineView.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "topLineView": topLineView,
            "bottomLineView": bottomLineView,
        ]

        let topLineViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-[topLineView]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        let topLineViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[topLineView(10)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(topLineViewConstraintsH)
        NSLayoutConstraint.activateConstraints(topLineViewConstraintsV)

        let bottomLineViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-[bottomLineView]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        let bottomLineViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:[bottomLineView(10)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(bottomLineViewConstraintsH)
        NSLayoutConstraint.activateConstraints(bottomLineViewConstraintsV)

//        layer.addSublayer(topLineLayer)
//        layer.addSublayer(bottomLineLayer)
    }

//    override func layoutSubviews() {
//        super.layoutSubviews()
//
//        let topPath = UIBezierPath()
//        topPath.moveToPoint(CGPoint(x: 0, y: 0))
//        topPath.addLineToPoint(CGPoint(x: CGRectGetWidth(bounds), y: 0))
//
//        topLineLayer.path = topPath.CGPath
//
//        let bottomPath = UIBezierPath()
//        bottomPath.moveToPoint(CGPoint(x: 0, y: CGRectGetHeight(bounds)))
//        bottomPath.addLineToPoint(CGPoint(x: CGRectGetWidth(bounds), y: CGRectGetHeight(bounds)))
//
//        bottomLineLayer.path = bottomPath.CGPath
//    }
}
*/

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

        view.backgroundColor = UIColor.yepViewBackgroundColor()

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


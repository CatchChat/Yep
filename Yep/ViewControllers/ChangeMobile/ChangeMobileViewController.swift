//
//  ChangeMobileViewController.swift
//  Yep
//
//  Created by NIX on 16/5/4.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class ChangeMobileViewController: UIViewController {

    @IBOutlet private weak var changeMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var changeMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var currentMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var currentMobileNumberLabel: UILabel!

    @IBOutlet private weak var areaCodeTextField: BorderTextField!
    @IBOutlet private weak var areaCodeTextFieldWidthConstraint: NSLayoutConstraint!

    @IBOutlet private weak var mobileNumberTextField: BorderTextField!
    @IBOutlet private weak var mobileNumberTextFieldTopConstraint: NSLayoutConstraint!

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .Plain, target: self, action: #selector(ChangeMobileViewController.next(_:)))
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Change Mobile", comment: ""))

        navigationItem.rightBarButtonItem = nextButton

        changeMobileNumberPromptLabel.text = NSLocalizedString("What's your new number?", comment: "")

        currentMobileNumberPromptLabel.text = NSLocalizedString("Current number:", comment: "")
        currentMobileNumberLabel.text = YepUserDefaults.fullPhoneNumber 

        areaCodeTextField.text = NSTimeZone.areaCode
        areaCodeTextField.backgroundColor = UIColor.whiteColor()

        areaCodeTextField.delegate = self
        areaCodeTextField.addTarget(self, action: #selector(ChangeMobileViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)

        mobileNumberTextField.placeholder = ""
        mobileNumberTextField.backgroundColor = UIColor.whiteColor()
        mobileNumberTextField.textColor = UIColor.yepInputTextColor()
        mobileNumberTextField.delegate = self
        mobileNumberTextField.addTarget(self, action: #selector(ChangeMobileViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)

        changeMobileNumberPromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
        mobileNumberTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value
    }

    // MARK: Actions

    private func adjustAreaCodeTextFieldWidth() {
        guard let text = areaCodeTextField.text else {
            return
        }

        let size = text.sizeWithAttributes(areaCodeTextField.editing ? areaCodeTextField.typingAttributes : areaCodeTextField.defaultTextAttributes)

        let width = 32 + (size.width + 22) + 20

        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
            self.areaCodeTextFieldWidthConstraint.constant = max(width, 100)
            self.view.layoutIfNeeded()
        }, completion: { finished in
        })
    }

    @objc private func textFieldDidChange(textField: UITextField) {

        guard let areaCode = areaCodeTextField.text, mobile = mobileNumberTextField.text else {
            return
        }

        nextButton.enabled = !areaCode.isEmpty && !mobile.isEmpty

        if textField == areaCodeTextField {
            adjustAreaCodeTextFieldWidth()
        }
    }

    @objc private func next(sender: UIBarButtonItem) {
        tryShowVerifyChangedMobile()
    }

    private func tryShowVerifyChangedMobile() {

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - UITextFieldDelegate

extension ChangeMobileViewController: UITextFieldDelegate {

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {

        if textField == areaCodeTextField {
            adjustAreaCodeTextFieldWidth()
        }

        return true
    }

    func textFieldDidEndEditing(textField: UITextField) {

        if textField == areaCodeTextField {
            UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                self.areaCodeTextFieldWidthConstraint.constant = 60
                self.view.layoutIfNeeded()
                }, completion: { finished in
            })
        }
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {

        guard let areaCode = areaCodeTextField.text, mobile = mobileNumberTextField.text else {
            return true
        }

        if !areaCode.isEmpty && !mobile.isEmpty {
            tryShowVerifyChangedMobile()
        }
        
        return true
    }
}


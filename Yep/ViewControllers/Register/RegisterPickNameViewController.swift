//
//  RegisterPickNameViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepConfig
import Ruler

final class RegisterPickNameViewController: BaseViewController {

    var mobile: String?
    var areaCode: String?

    @IBOutlet private weak var pickNamePromptLabel: UILabel!
    @IBOutlet private weak var pickNamePromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var promptTermsLabel: UILabel!

    @IBOutlet private weak var nameTextField: BorderTextField!
    @IBOutlet private weak var nameTextFieldTopConstraint: NSLayoutConstraint!
    
    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .Plain, target: self, action: #selector(RegisterPickNameViewController.next(_:)))
        return button
    }()

    private var isDirty = false {
        willSet {
            nextButton.enabled = newValue
            promptTermsLabel.alpha = newValue ? 1.0 : 0.5
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        animatedOnNavigationBar = false

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Sign up", comment: ""))

        navigationItem.rightBarButtonItem = nextButton

        pickNamePromptLabel.text = NSLocalizedString("What's your name?", comment: "")

        let text = NSLocalizedString("By tapping Next you agree to our terms.", comment: "")
        let textAttributes: [String: AnyObject] = [
            NSFontAttributeName: UIFont.systemFontOfSize(14),
            NSForegroundColorAttributeName: UIColor.grayColor(),
        ]
        let attributedText = NSMutableAttributedString(string: text, attributes: textAttributes)
        let termsAttributes: [String: AnyObject] = [
            NSForegroundColorAttributeName: UIColor.yepTintColor(),
            NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue,
        ]
        let tapRange = (text as NSString).rangeOfString(NSLocalizedString("terms", comment: ""))
        attributedText.addAttributes(termsAttributes, range: tapRange)

        promptTermsLabel.attributedText = attributedText
        promptTermsLabel.textAlignment = .Center
        promptTermsLabel.alpha = 0.5

        promptTermsLabel.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(RegisterPickNameViewController.tapTerms(_:)))
        promptTermsLabel.addGestureRecognizer(tap)

        nameTextField.backgroundColor = UIColor.whiteColor()
        nameTextField.textColor = UIColor.yepInputTextColor()
        nameTextField.placeholder = " "//NSLocalizedString("Nickname", comment: "")
        nameTextField.delegate = self
        nameTextField.addTarget(self, action: #selector(RegisterPickNameViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)

        pickNamePromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
        nameTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value

        nextButton.enabled = false
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        nameTextField.becomeFirstResponder()
    }

    // MARK: Actions

    @objc private func tapTerms(sender: UITapGestureRecognizer) {
        if let URL = NSURL(string: YepConfig.termsURLString) {
            yep_openURL(URL)
        }
    }

    @objc private func textFieldDidChange(textField: UITextField) {
        guard let text = textField.text else {
            return
        }

        isDirty = !text.isEmpty
    }

    @objc private func next(sender: UIBarButtonItem) {
        showRegisterPickMobile()
    }

    private func showRegisterPickMobile() {

        guard let text = nameTextField.text else {
            return
        }

        let nickname = text.trimming(.WhitespaceAndNewline)
        YepUserDefaults.nickname.value = nickname

        performSegueWithIdentifier("showRegisterPickMobile", sender: nil)
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showRegisterPickMobile":

            let vc = segue.destinationViewController as! RegisterPickMobileViewController

            vc.mobile = mobile
            vc.areaCode = areaCode

        default:
            break
        }
    }
}

extension RegisterPickNameViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {

        guard let text = textField.text else {
            return true
        }

        if !text.isEmpty {
            showRegisterPickMobile()
        }

        return true
    }
}


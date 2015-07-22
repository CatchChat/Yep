//
//  RegisterPickNameViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class RegisterPickNameViewController: UIViewController {

    @IBOutlet weak var pickNamePromptLabel: UILabel!
    @IBOutlet weak var pickNamePromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var nameTextField: BorderTextField!
    @IBOutlet weak var nameTextFieldTopConstraint: NSLayoutConstraint!
    
    lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .Plain, target: self, action: "next:")
        return button
        }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Sign up", comment: ""))

        navigationItem.rightBarButtonItem = nextButton

        pickNamePromptLabel.text = NSLocalizedString("What's your name?", comment: "")

        nameTextField.delegate = self
        nameTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)

        pickNamePromptLabelTopConstraint.constant = Ruler.match(.iPhoneHeights(30, 50, 60, 60))
        nameTextFieldTopConstraint.constant = Ruler.match(.iPhoneHeights(30, 40, 50, 50))
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        nextButton.enabled = false
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        nameTextField.becomeFirstResponder()
    }

    // MARK: Actions

    func textFieldDidChange(textField: UITextField) {
        nextButton.enabled = !textField.text.isEmpty
    }

    func next(sender: UIBarButtonItem) {
        showRegisterPickMobile()
    }

    private func showRegisterPickMobile() {
        let nickname = nameTextField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet());
        YepUserDefaults.nickname.value = nickname

        performSegueWithIdentifier("showRegisterPickMobile", sender: nil)
    }
}

extension RegisterPickNameViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if !textField.text.isEmpty {
            showRegisterPickMobile()
        }

        return true
    }
}
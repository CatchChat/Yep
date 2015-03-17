//
//  LoginByMobileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class LoginByMobileViewController: UIViewController {

    @IBOutlet weak var pickMobileNumberPromptLabel: UILabel!

    @IBOutlet weak var areaCodeTextField: UnderLineTextField!
    @IBOutlet weak var mobileNumberTextField: UnderLineTextField!

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!


    override func viewDidLoad() {
        super.viewDidLoad()

        areaCodeTextField.delegate = self
        areaCodeTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)

        mobileNumberTextField.delegate = self
        mobileNumberTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)
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

    func textFieldDidChange(textField: UITextField) {

        nextButton.enabled = !areaCodeTextField.text.isEmpty && !mobileNumberTextField.text.isEmpty
    }

    @IBAction func back(sender: UIButton) {
        navigationController?.popViewControllerAnimated(true)
    }


    @IBAction func next(sender: UIButton) {
        showLoginVerifyMobile()
    }

    private func showLoginVerifyMobile() {
        performSegueWithIdentifier("showLoginVerifyMobile", sender: nil)
    }

}

extension LoginByMobileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if !textField.text.isEmpty {
            showLoginVerifyMobile()
        }
        
        return true
    }
}

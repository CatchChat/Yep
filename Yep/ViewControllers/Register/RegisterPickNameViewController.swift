//
//  RegisterPickNameViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class RegisterPickNameViewController: UIViewController {

    @IBOutlet weak var pickNamePromptLabel: UILabel!

    @IBOutlet weak var nameTextField: UnderLineTextField!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.enabled = false
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        nameTextField.delegate = self
        nameTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)
        nameTextField.becomeFirstResponder()
    }

    // MARK: Actions

    func textFieldDidChange(textField: UITextField) {
        nextButton.enabled = !textField.text.isEmpty
    }

    @IBAction func back(sender: UIButton) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func next(sender: UIButton) {
        showRegisterPickMobile()
    }

    private func showRegisterPickMobile() {
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
//
//  RegisterPickNameViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Ruler
import RxSwift
import RxCocoa

final class RegisterPickNameViewController: BaseViewController {

    fileprivate lazy var disposeBag = DisposeBag()

    @IBOutlet fileprivate weak var pickNamePromptLabel: UILabel!
    @IBOutlet fileprivate weak var pickNamePromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet fileprivate weak var promptTermsLabel: UILabel!

    @IBOutlet fileprivate weak var nameTextField: BorderTextField!
    @IBOutlet fileprivate weak var nameTextFieldTopConstraint: NSLayoutConstraint!
    
    fileprivate lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = String.trans_buttonNextStep
        button.rx.tap
            .subscribe(onNext: { [weak self] in self?.showRegisterPickMobile() })
            .addDisposableTo(self.disposeBag)
        return button
    }()

    fileprivate var isDirty = false {
        willSet {
            nextButton.isEnabled = newValue
            promptTermsLabel.alpha = newValue ? 1.0 : 0.5
        }
    }

    deinit {
        println("deinit RegisterPickName")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Sign Up", comment: ""))

        navigationItem.rightBarButtonItem = nextButton

        pickNamePromptLabel.text = NSLocalizedString("What's your name?", comment: "")

        let text = String.trans_promptTapNextAgreeTerms
        let textAttributes: [String: Any] = [
            NSFontAttributeName: UIFont.systemFont(ofSize: 14),
            NSForegroundColorAttributeName: UIColor.gray,
        ]
        let attributedText = NSMutableAttributedString(string: text, attributes: textAttributes)
        let termsAttributes: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.yepTintColor(),
            NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
        ]
        let tapRange = (text as NSString).range(of: NSLocalizedString("terms", comment: ""))
        attributedText.addAttributes(termsAttributes, range: tapRange)

        promptTermsLabel.attributedText = attributedText
        promptTermsLabel.textAlignment = .center
        promptTermsLabel.alpha = 0.5

        promptTermsLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(RegisterPickNameViewController.tapTerms(_:)))
        promptTermsLabel.addGestureRecognizer(tap)

        nameTextField.backgroundColor = UIColor.white
        nameTextField.textColor = UIColor.yepInputTextColor()
        nameTextField.placeholder = " "
        nameTextField.delegate = self
        nameTextField.rx.textInput.text
            .map({ $0 ?? "" })
            .map({ !$0.isEmpty })
            .subscribe(onNext: { [weak self] in self?.isDirty = $0 })
            .addDisposableTo(disposeBag)

        pickNamePromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
        nameTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value

        nextButton.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        nameTextField.becomeFirstResponder()
    }

    // MARK: Actions

    @objc fileprivate func tapTerms(_ sender: UITapGestureRecognizer) {
        if let URL = URL(string: YepConfig.termsURLString) {
            yep_openURL(URL)
        }
    }

    fileprivate func showRegisterPickMobile() {

        guard let text = nameTextField.text else {
            return
        }

        let nickname = text.trimming(.whitespaceAndNewline)
        YepUserDefaults.nickname.value = nickname

        performSegue(withIdentifier: "showRegisterPickMobile", sender: nil)
    }
}

extension RegisterPickNameViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        guard let text = textField.text else {
            return true
        }

        if !text.isEmpty {
            showRegisterPickMobile()
        }

        return true
    }
}


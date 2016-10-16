//
//  PhoneNumberRepresentation.swift
//  Yep
//
//  Created by NIX on 16/7/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol PhoneNumberRepresentation: UITextFieldDelegate {

    var areaCodeTextField: BorderTextField! { get }
    var areaCodeTextFieldWidthConstraint: NSLayoutConstraint! { get }
    var mobileNumberTextField: BorderTextField! { get }

    func adjustAreaCodeTextFieldWidth()
    func tappedKeyboardReturn()
}

extension PhoneNumberRepresentation where Self: UIViewController {

    func adjustAreaCodeTextFieldWidth() {

        guard let text = areaCodeTextField.text else { return }

        let size = text.size(attributes: areaCodeTextField.isEditing ? areaCodeTextField.typingAttributes : areaCodeTextField.defaultTextAttributes)

        let width = 32 + (size.width + 22) + 20

        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] _ in
            self?.areaCodeTextFieldWidthConstraint.constant = max(width, 100)
            self?.view.layoutIfNeeded()
        }, completion: nil)
    }
}


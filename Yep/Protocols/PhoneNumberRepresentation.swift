//
//  PhoneNumberRepresentation.swift
//  Yep
//
//  Created by NIX on 16/7/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol PhoneNumberRepresentation: class {

    var areaCodeTextField: BorderTextField! { get }
    var areaCodeTextFieldWidthConstraint: NSLayoutConstraint! { get }
    var mobileNumberTextField: BorderTextField! { get }
    
    func adjustAreaCodeTextFieldWidth()
}

extension PhoneNumberRepresentation where Self: UIViewController {

    func adjustAreaCodeTextFieldWidth() {

        guard let text = areaCodeTextField.text else {
            return
        }

        let size = text.sizeWithAttributes(areaCodeTextField.editing ? areaCodeTextField.typingAttributes : areaCodeTextField.defaultTextAttributes)

        let width = 32 + (size.width + 22) + 20

        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] _ in
            self?.areaCodeTextFieldWidthConstraint.constant = max(width, 100)
            self?.view.layoutIfNeeded()
        }, completion: { finished in
        })
    }
}

extension RegisterPickMobileViewController: PhoneNumberRepresentation {
}

extension LoginByMobileViewController: PhoneNumberRepresentation {
}

extension ChangeMobileViewController: PhoneNumberRepresentation {
}


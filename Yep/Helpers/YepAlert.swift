//
//  YepAlert.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class YepAlert {
    class func alert(#title: String, message: String, dismissTitle: String, inViewController viewController: UIViewController, withDismissAction dismissAction: (() -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        let action: UIAlertAction = UIAlertAction(title: dismissTitle, style: .Default) { action -> Void in
            if let dismissAction = dismissAction {
                dismissAction()
            }
        }
        alertController.addAction(action)

        viewController.presentViewController(alertController, animated: true, completion: nil)
    }

    class func alertSorry(#message: String, inViewController viewController: UIViewController, withDismissAction dismissAction: () -> Void) {
        alert(title: NSLocalizedString("Sorry", comment: ""), message: message, dismissTitle: NSLocalizedString("Dismiss", comment: ""), inViewController: viewController, withDismissAction: dismissAction)
    }

    class func alertSorry(#message: String, inViewController viewController: UIViewController) {
        alert(title: NSLocalizedString("Sorry", comment: ""), message: message, dismissTitle: NSLocalizedString("Dismiss", comment: ""), inViewController: viewController, withDismissAction: nil)
    }

    class func textInput(#title: String, placeholder: String?, oldText: String?, dismissTitle: String, inViewController viewController: UIViewController, withFinishedAction finishedAction: ((text: String) -> Void)?) {

        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .Alert)

        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = placeholder
            textField.text = oldText
        }

        let action: UIAlertAction = UIAlertAction(title: dismissTitle, style: .Default) { action -> Void in
            if let finishedAction = finishedAction {
                if let textField = alertController.textFields?.first as? UITextField {
                    finishedAction(text: textField.text)
                }
            }
        }
        alertController.addAction(action)

        viewController.presentViewController(alertController, animated: true, completion: nil)
    }
}
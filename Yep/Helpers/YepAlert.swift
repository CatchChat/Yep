//
//  YepAlert.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class YepAlert {
    class func alert(#title: String, message: String?, dismissTitle: String, inViewController viewController: UIViewController, withDismissAction dismissAction: (() -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        let action: UIAlertAction = UIAlertAction(title: dismissTitle, style: .Default) { action -> Void in
            if let dismissAction = dismissAction {
                dismissAction()
            }
        }
        alertController.addAction(action)

        viewController.presentViewController(alertController, animated: true, completion: nil)
    }

    class func alertSorry(#message: String?, inViewController viewController: UIViewController, withDismissAction dismissAction: () -> Void) {
        alert(title: NSLocalizedString("Sorry", comment: ""), message: message, dismissTitle: NSLocalizedString("OK", comment: ""), inViewController: viewController, withDismissAction: dismissAction)
    }

    class func alertSorry(#message: String?, inViewController viewController: UIViewController) {
        alert(title: NSLocalizedString("Sorry", comment: ""), message: message, dismissTitle: NSLocalizedString("OK", comment: ""), inViewController: viewController, withDismissAction: nil)
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

    class func textInput(#title: String, placeholder: String?, oldText: String?, confirmTitle: String, cancelTitle: String, inViewController viewController: UIViewController, withConfirmAction confirmAction: ((text: String) -> Void)?, cancelAction: (() -> Void)?) {

        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .Alert)

        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = placeholder
            textField.text = oldText
        }

        let _cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .Cancel) { action -> Void in
            cancelAction?()
        }
        alertController.addAction(_cancelAction)

        let _confirmAction: UIAlertAction = UIAlertAction(title: confirmTitle, style: .Default) { action -> Void in
            if let textField = alertController.textFields?.first as? UITextField {
                confirmAction?(text: textField.text)
            }
        }
        alertController.addAction(_confirmAction)

        viewController.presentViewController(alertController, animated: true, completion: nil)
    }

    class func confirmOrCancel(#title: String, message: String, confirmTitle: String, cancelTitle: String, inViewController viewController: UIViewController, withConfirmAction confirmAction: () -> Void, cancelAction: () -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .Cancel) { action -> Void in
            cancelAction()
        }
        alertController.addAction(cancelAction)

        let confirmAction: UIAlertAction = UIAlertAction(title: confirmTitle, style: .Default) { action -> Void in
            confirmAction()
        }
        alertController.addAction(confirmAction)

        viewController.presentViewController(alertController, animated: true, completion: nil)
    }

}
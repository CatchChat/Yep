//
//  YepAlert.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Proposer

class YepAlert {

    class func alert(#title: String, message: String?, dismissTitle: String, inViewController viewController: UIViewController?, withDismissAction dismissAction: (() -> Void)?) {

        dispatch_async(dispatch_get_main_queue()) {

            let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)

            let action: UIAlertAction = UIAlertAction(title: dismissTitle, style: .Default) { action -> Void in
                if let dismissAction = dismissAction {
                    dismissAction()
                }
            }
            alertController.addAction(action)

            viewController?.presentViewController(alertController, animated: true, completion: nil)
        }
    }

    class func alertSorry(#message: String?, inViewController viewController: UIViewController?, withDismissAction dismissAction: () -> Void) {
        alert(title: NSLocalizedString("Sorry", comment: ""), message: message, dismissTitle: NSLocalizedString("OK", comment: ""), inViewController: viewController, withDismissAction: dismissAction)
    }

    class func alertSorry(#message: String?, inViewController viewController: UIViewController?) {
        alert(title: NSLocalizedString("Sorry", comment: ""), message: message, dismissTitle: NSLocalizedString("OK", comment: ""), inViewController: viewController, withDismissAction: nil)
    }

    class func textInput(#title: String, placeholder: String?, oldText: String?, dismissTitle: String, inViewController viewController: UIViewController?, withFinishedAction finishedAction: ((text: String) -> Void)?) {

        dispatch_async(dispatch_get_main_queue()) {

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

            viewController?.presentViewController(alertController, animated: true, completion: nil)
        }
    }

    class func textInput(#title: String, placeholder: String?, oldText: String?, confirmTitle: String, cancelTitle: String, inViewController viewController: UIViewController?, withConfirmAction confirmAction: ((text: String) -> Void)?, cancelAction: (() -> Void)?) {

        dispatch_async(dispatch_get_main_queue()) {

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

            viewController?.presentViewController(alertController, animated: true, completion: nil)
        }
    }

    class func confirmOrCancel(#title: String, message: String, confirmTitle: String, cancelTitle: String, inViewController viewController: UIViewController?, withConfirmAction confirmAction: () -> Void, cancelAction: () -> Void) {

        dispatch_async(dispatch_get_main_queue()) {

            let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)

            let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .Cancel) { action -> Void in
                cancelAction()
            }
            alertController.addAction(cancelAction)

            let confirmAction: UIAlertAction = UIAlertAction(title: confirmTitle, style: .Default) { action -> Void in
                confirmAction()
            }
            alertController.addAction(confirmAction)

            viewController?.presentViewController(alertController, animated: true, completion: nil)
        }
    }

}

extension UIViewController {

    func alertCanNotAccessCameraRoll() {

        dispatch_async(dispatch_get_main_queue()) {
            YepAlert.confirmOrCancel(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("Yep can not access your Camera Roll!\nBut you can change it in iOS Settings.\n", comment: ""), confirmTitle: NSLocalizedString("Change it now", comment: ""), cancelTitle: NSLocalizedString("Dismiss", comment: ""), inViewController: self, withConfirmAction: {

                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)

            }, cancelAction: {
            })
        }
    }

    func alertCanNotOpenCamera() {

        dispatch_async(dispatch_get_main_queue()) {
            YepAlert.confirmOrCancel(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("Yep can not open your Camera!\nBut you can change it in iOS Settings.\n", comment: ""), confirmTitle: NSLocalizedString("Change it now", comment: ""), cancelTitle: NSLocalizedString("Dismiss", comment: ""), inViewController: self, withConfirmAction: {

                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)

            }, cancelAction: {
            })
        }
    }

    func alertCanNotAccessMicrophone() {

        dispatch_async(dispatch_get_main_queue()) {
            YepAlert.confirmOrCancel(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("Yep can not access your Microphone!\nBut you can change it in iOS Settings.\n", comment: ""), confirmTitle: NSLocalizedString("Change it now", comment: ""), cancelTitle: NSLocalizedString("Dismiss", comment: ""), inViewController: self, withConfirmAction: {

                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)

                }, cancelAction: {
            })
        }
    }

    func alertCanNotAccessContacts() {

        dispatch_async(dispatch_get_main_queue()) {
            YepAlert.confirmOrCancel(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("Yep can not read your Contacts!\nBut you can change it in iOS Settings.\n", comment: ""), confirmTitle: NSLocalizedString("Change it now", comment: ""), cancelTitle: NSLocalizedString("Dismiss", comment: ""), inViewController: self, withConfirmAction: {

            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)

            }, cancelAction: {
            })
        }
    }

    func alertCanNotAccessLocation() {

        dispatch_async(dispatch_get_main_queue()) {
            YepAlert.confirmOrCancel(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("Yep can not get your Location!\nBut you can change it in iOS Settings.\n", comment: ""), confirmTitle: NSLocalizedString("Change it now", comment: ""), cancelTitle: NSLocalizedString("Dismiss", comment: ""), inViewController: self, withConfirmAction: {

                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)

            }, cancelAction: {
            })
        }
    }


    func showProposeMessageIfNeedForContactsAndTryPropose(propose: Propose) {

        if PrivateResource.Contacts.isNotDeterminedAuthorization {

            dispatch_async(dispatch_get_main_queue()) {

                YepAlert.confirmOrCancel(title: NSLocalizedString("Notice", comment: ""), message: NSLocalizedString("Yep need to read your Contacts to continue this operation.\nIs that OK?", comment: ""), confirmTitle: NSLocalizedString("OK", comment: ""), cancelTitle: NSLocalizedString("No now", comment: ""), inViewController: self, withConfirmAction: {

                    propose()

                }, cancelAction: {
                })
            }

        } else {
            propose()
        }
    }
}


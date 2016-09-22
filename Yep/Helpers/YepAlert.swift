//
//  YepAlert.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Proposer
//fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
//  switch (lhs, rhs) {
//  case let (l?, r?):
//    return l < r
//  case (nil, _?):
//    return true
//  default:
//    return false
//  }
//}
//
//fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
//  switch (lhs, rhs) {
//  case let (l?, r?):
//    return l >= r
//  default:
//    return !(lhs < rhs)
//  }
//}


final class YepAlert {

    class func alert(title: String, message: String?, dismissTitle: String, inViewController viewController: UIViewController?, withDismissAction dismissAction: (() -> Void)?) {

        SafeDispatch.async {

            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

            let action: UIAlertAction = UIAlertAction(title: dismissTitle, style: .default) { action in
                if let dismissAction = dismissAction {
                    dismissAction()
                }
            }
            alertController.addAction(action)

            viewController?.present(alertController, animated: true, completion: nil)
        }
    }

    class func alertSorry(message: String?, inViewController viewController: UIViewController?, withDismissAction dismissAction: @escaping () -> Void) {

        alert(title: NSLocalizedString("Sorry", comment: ""), message: message, dismissTitle: String.trans_titleOK, inViewController: viewController, withDismissAction: dismissAction)
    }

    class func alertSorry(message: String?, inViewController viewController: UIViewController?) {

        alert(title: NSLocalizedString("Sorry", comment: ""), message: message, dismissTitle: String.trans_titleOK, inViewController: viewController, withDismissAction: nil)
    }

    class func textInput(title: String, placeholder: String?, oldText: String?, dismissTitle: String, inViewController viewController: UIViewController?, withFinishedAction finishedAction: ((_ text: String) -> Void)?) {

        SafeDispatch.async {

            let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)

            alertController.addTextField { textField in
                textField.placeholder = placeholder
                textField.text = oldText
            }

            let action: UIAlertAction = UIAlertAction(title: dismissTitle, style: .default) { action in
                if let finishedAction = finishedAction {
                    if let textField = alertController.textFields?.first, let text = textField.text {
                        finishedAction(text)
                    }
                }
            }
            alertController.addAction(action)

            viewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    static weak var confirmAlertAction: UIAlertAction?
    
    class func textInput(title: String, message: String?, placeholder: String?, oldText: String?, confirmTitle: String, cancelTitle: String, inViewController viewController: UIViewController?, withConfirmAction confirmAction: ((_ text: String) -> Void)?, cancelAction: (() -> Void)?) {

        SafeDispatch.async {

            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

            alertController.addTextField { textField in
                textField.placeholder = placeholder
                textField.text = oldText
                textField.addTarget(self, action: #selector(YepAlert.handleTextFieldTextDidChangeNotification(_:)), for: .editingChanged)
            }

            let _cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel) { action in
                cancelAction?()
            }
            
            alertController.addAction(_cancelAction)
            
            let _confirmAction: UIAlertAction = UIAlertAction(title: confirmTitle, style: .default) { action in
                if let textField = alertController.textFields?.first, let text = textField.text {
                    
                    confirmAction?(text)
                }
            }
            _confirmAction.isEnabled = false
            self.confirmAlertAction = _confirmAction
            
            alertController.addAction(_confirmAction)

            viewController?.present(alertController, animated: true, completion: nil)
        }
    }

    @objc class func handleTextFieldTextDidChangeNotification(_ sender: UITextField) {

        guard let text = sender.text else { return }
        YepAlert.confirmAlertAction?.isEnabled = text.utf16.count >= 1
    }
    
    class func confirmOrCancel(title: String, message: String, confirmTitle: String, cancelTitle: String, inViewController viewController: UIViewController?, withConfirmAction confirmAction: @escaping () -> Void, cancelAction: @escaping () -> Void) {

        SafeDispatch.async {

            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

            let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel) { action in
                cancelAction()
            }
            alertController.addAction(cancelAction)

            let confirmAction: UIAlertAction = UIAlertAction(title: confirmTitle, style: .default) { action in
                confirmAction()
            }
            alertController.addAction(confirmAction)

            viewController?.present(alertController, animated: true, completion: nil)
        }
    }
}

extension UIViewController {

    func alertCanNotAccessCameraRoll() {

        SafeDispatch.async {
            YepAlert.confirmOrCancel(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("Yep can not access your Camera Roll!\nBut you can change it in iOS Settings.", comment: ""), confirmTitle: String.trans_titleChangeItNow, cancelTitle: String.trans_titleDismiss, inViewController: self, withConfirmAction: {

                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)

            }, cancelAction: {
            })
        }
    }

    func alertCanNotOpenCamera() {

        SafeDispatch.async {
            YepAlert.confirmOrCancel(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("Yep can not open your Camera!\nBut you can change it in iOS Settings.", comment: ""), confirmTitle: String.trans_titleChangeItNow, cancelTitle: String.trans_titleDismiss, inViewController: self, withConfirmAction: {

                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)

            }, cancelAction: {
            })
        }
    }

    func alertCanNotAccessMicrophone() {

        SafeDispatch.async {
            YepAlert.confirmOrCancel(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("Yep can not access your Microphone!\nBut you can change it in iOS Settings.", comment: ""), confirmTitle: String.trans_titleChangeItNow, cancelTitle: String.trans_titleDismiss, inViewController: self, withConfirmAction: {

                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)

            }, cancelAction: {
            })
        }
    }

    func alertCanNotAccessContacts() {

        SafeDispatch.async {
            YepAlert.confirmOrCancel(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("Yep can not read your Contacts!\nBut you can change it in iOS Settings.", comment: ""), confirmTitle: String.trans_titleChangeItNow, cancelTitle: String.trans_titleDismiss, inViewController: self, withConfirmAction: {

            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)

            }, cancelAction: {
            })
        }
    }

    func alertCanNotAccessLocation() {

        SafeDispatch.async {
            YepAlert.confirmOrCancel(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("Yep can not get your Location!\nBut you can change it in iOS Settings.", comment: ""), confirmTitle: String.trans_titleChangeItNow, cancelTitle: String.trans_titleDismiss, inViewController: self, withConfirmAction: {

                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)

            }, cancelAction: {
            })
        }
    }

    func showProposeMessageIfNeedForContactsAndTryPropose(_ propose: @escaping Propose) {

        if PrivateResource.contacts.isNotDeterminedAuthorization {

            SafeDispatch.async {

                YepAlert.confirmOrCancel(title: String.trans_titleNotice, message: NSLocalizedString("Yep need to read your Contacts to continue this operation.\nIs that OK?", comment: ""), confirmTitle: String.trans_titleOK, cancelTitle: String.trans_titleNotNow, inViewController: self, withConfirmAction: {

                    propose()

                }, cancelAction: {
                })
            }

        } else {
            propose()
        }
    }
}


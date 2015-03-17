//
//  YepAlert.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class YepAlert {
    class func alert(#title: String, message: String, inViewController viewController: UIViewController, withDismissAction dismissAction: (() -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        let action: UIAlertAction = UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .Default) { action -> Void in
            if let dismissAction = dismissAction {
                dismissAction()
            }
        }
        alertController.addAction(action)

        viewController.presentViewController(alertController, animated: true, completion: nil)
    }

    class func alertSorry(#message: String, inViewController viewController: UIViewController, withDismissAction dismissAction: () -> Void) {
        alert(title: NSLocalizedString("Sorry", comment: ""), message: message, inViewController: viewController, withDismissAction: dismissAction)
    }

    class func alertSorry(#message: String, inViewController viewController: UIViewController) {
        alert(title: NSLocalizedString("Sorry", comment: ""), message: message, inViewController: viewController, withDismissAction: nil)
    }
}
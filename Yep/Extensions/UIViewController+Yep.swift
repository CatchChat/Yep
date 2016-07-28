//
//  UIViewController+Yep.swift
//  Yep
//
//  Created by NIX on 15/7/27.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import SafariServices

// MAKR: - Heights

extension UIViewController {

    var statusBarHeight: CGFloat {

        if let window = view.window {
            let statusBarFrame = window.convertRect(UIApplication.sharedApplication().statusBarFrame, toView: view)
            return statusBarFrame.height

        } else {
            return 0
        }
    }

    var navigationBarHeight: CGFloat {

        if let navigationController = navigationController {
            return navigationController.navigationBar.frame.height

        } else {
            return 0
        }
    }

    var topBarsHeight: CGFloat {
        return statusBarHeight + navigationBarHeight
    }
}

// MAKR: - Report

extension UIViewController {

    enum ReportObject {
        case User(ProfileUser)
        case Feed(feedID: String)
        case Message(messageID: String)
    }

    func report(object: ReportObject) {

        let reportWithReason: ReportReason -> Void = { [weak self] reason in

            switch object {

            case .User(let profileUser):
                reportProfileUser(profileUser, forReason: reason, failureHandler: { [weak self] (reason, errorMessage) in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    if let errorMessage = errorMessage {
                        YepAlert.alertSorry(message: errorMessage, inViewController: self)
                    }

                }, completion: {
                })

            case .Feed(let feedID):
                reportFeedWithFeedID(feedID, forReason: reason, failureHandler: { [weak self] (reason, errorMessage) in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    if let errorMessage = errorMessage {
                        YepAlert.alertSorry(message: errorMessage, inViewController: self)
                    }

                }, completion: {
                })

            case .Message(let messageID):
                reportMessageWithMessageID(messageID, forReason: reason, failureHandler: { [weak self] (reason, errorMessage) in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    if let errorMessage = errorMessage {
                        YepAlert.alertSorry(message: errorMessage, inViewController: self)
                    }

                }, completion: {
                })
            }
        }

        let reportAlertController = UIAlertController(title: NSLocalizedString("Report Reason", comment: ""), message: nil, preferredStyle: .ActionSheet)

        let pornoReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.Porno.description, style: .Default) { action -> Void in
            reportWithReason(.Porno)
        }
        reportAlertController.addAction(pornoReasonAction)

        let advertisingReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.Advertising.description, style: .Default) { action -> Void in
            reportWithReason(.Advertising)
        }
        reportAlertController.addAction(advertisingReasonAction)

        let scamsReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.Scams.description, style: .Default) { action -> Void in
            reportWithReason(.Scams)
        }
        reportAlertController.addAction(scamsReasonAction)

        let otherReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.Other("").description, style: .Default) { [weak self] action -> Void in
            YepAlert.textInput(title: NSLocalizedString("Other Reason", comment: ""), message: nil, placeholder: nil, oldText: nil, confirmTitle: NSLocalizedString("OK", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: { text in
                reportWithReason(.Other(text))
            }, cancelAction: nil)
        }
        reportAlertController.addAction(otherReasonAction)

        let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel) { action -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        reportAlertController.addAction(cancelAction)
        
        self.presentViewController(reportAlertController, animated: true, completion: nil)
    }
}

// MAKR: - openURL

extension UIViewController {

    func yep_openURL(URL: NSURL) {

        if let URL = URL.yep_validSchemeNetworkURL {
            let safariViewController = SFSafariViewController(URL: URL)
            presentViewController(safariViewController, animated: true, completion: nil)

        } else {
            YepAlert.alertSorry(message: NSLocalizedString("Invalid URL!", comment: ""), inViewController: self)
        }
    }
}

// MARK: - Rate in App Store

extension UIViewController {

    func yep_reviewOnTheAppStore() {

        guard let version = NSBundle.releaseVersionNumber else {
            return
        }

        let noMoreReviewOnTheAppStoreKey = "yep_\(version)_noMoreReviewOnTheAppStoreKey"
        let exponentialBackoffKey = "yep_\(version)_exponentialBackoffKey"
        let tryReviewOnTheAppStoreCountKey = "yep_\(version)_tryReviewOnTheAppStoreCountKey"

        func noMoreReviewOnTheAppStore() -> Bool {
             return NSUserDefaults.standardUserDefaults().boolForKey(noMoreReviewOnTheAppStoreKey)
        }

        func setNoMoreReviewOnTheAppStore() {
            return NSUserDefaults.standardUserDefaults().setBool(true, forKey: noMoreReviewOnTheAppStoreKey)
        }

        func exponentialBackoff() -> Int {
            return (NSUserDefaults.standardUserDefaults().objectForKey(exponentialBackoffKey) as? Int) ?? 2
        }

        func increaseExponentialBackoff() {
            let newCount = exponentialBackoff() + 1
            NSUserDefaults.standardUserDefaults().setInteger(newCount, forKey: exponentialBackoffKey)
        }

        func tryReviewOnTheAppStoreCount() -> Int {
            return NSUserDefaults.standardUserDefaults().integerForKey(tryReviewOnTheAppStoreCountKey)
        }

        func increaseTryReviewOnTheAppStoreCount() {
            let newCount = tryReviewOnTheAppStoreCount() + 1
            NSUserDefaults.standardUserDefaults().setInteger(newCount, forKey: tryReviewOnTheAppStoreCountKey)
        }

        SafeDispatch.async { [weak self] in

            guard !noMoreReviewOnTheAppStore() else {
                return
            }

            defer {
                increaseTryReviewOnTheAppStoreCount()
            }

            let exponentialBackoff = exponentialBackoff()
            let tryReviewOnTheAppStoreCount = tryReviewOnTheAppStoreCount()

            guard Double(tryReviewOnTheAppStoreCount) > pow(2, Double(exponentialBackoff)) else {
                return
            }

            let title = NSLocalizedString("Review Yep", comment: "")
            let message = NSLocalizedString("Do you like Yep?\nWould you like to review it on the App Store?", comment: "")
            let doNotRemindMeATitle = NSLocalizedString("Do not remind me in this version", comment: "")
            let maybeNextTimeTitle = NSLocalizedString("Maybe next time", comment: "")
            let confirmTitle = NSLocalizedString("Review now", comment: "")

            let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)

            do {
                let action: UIAlertAction = UIAlertAction(title: doNotRemindMeATitle, style: .Default) { action in
                    setNoMoreReviewOnTheAppStore()
                }
                alertController.addAction(action)
            }

            do {
                let action: UIAlertAction = UIAlertAction(title: maybeNextTimeTitle, style: .Default) { action in
                    increaseExponentialBackoff()
                }
                alertController.addAction(action)
            }

            do {
                let action: UIAlertAction = UIAlertAction(title: confirmTitle, style: .Cancel) { action in
                    setNoMoreReviewOnTheAppStore()
                    UIApplication.sharedApplication().yep_reviewOnTheAppStore()
                }
                alertController.addAction(action)
            }

            self?.presentViewController(alertController, animated: true, completion: nil)
        }
    }
}


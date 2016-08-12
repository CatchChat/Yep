//
//  UIViewController+Yep.swift
//  Yep
//
//  Created by NIX on 15/7/27.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import SafariServices
import YepKit
import YepNetworking
import AutoReview

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

extension ReportReason {

    var title: String {
        switch self {
        case .Porno:
            return String.trans_reportPorno
        case .Advertising:
            return String.trans_reportAdvertising
        case .Scams:
            return String.trans_reportScams
        case .Other:
            return String.trans_reportOther
        }
    }
}

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

        let pornoReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.Porno.title, style: .Default) { _ in
            reportWithReason(.Porno)
        }
        reportAlertController.addAction(pornoReasonAction)

        let advertisingReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.Advertising.title, style: .Default) { _ in
            reportWithReason(.Advertising)
        }
        reportAlertController.addAction(advertisingReasonAction)

        let scamsReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.Scams.title, style: .Default) { _ in
            reportWithReason(.Scams)
        }
        reportAlertController.addAction(scamsReasonAction)

        let otherReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.Other("").title, style: .Default) { [weak self] _ in
            YepAlert.textInput(title: NSLocalizedString("Other Reason", comment: ""), message: nil, placeholder: nil, oldText: nil, confirmTitle: NSLocalizedString("OK", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: { text in
                reportWithReason(.Other(text))
            }, cancelAction: nil)
        }
        reportAlertController.addAction(otherReasonAction)

        let cancelAction: UIAlertAction = UIAlertAction(title: String.trans_cancel, style: .Cancel) { [weak self] _ in
            self?.dismissViewControllerAnimated(true, completion: nil)
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

// MARK: - Review

extension UIViewController {

    func remindUserToReview() {

        let remindAction: dispatch_block_t = { [weak self] in

            guard self?.view.window != nil else {
                return
            }

            let info = AutoReview.Info(
                appID: "983891256",
                title: NSLocalizedString("Review Yep", comment: ""),
                message: NSLocalizedString("Do you like Yep?\nWould you like to review it on the App Store?", comment: ""),
                doNotRemindMeInThisVersionTitle: NSLocalizedString("Do not remind me in this version", comment: ""),
                maybeNextTimeTitle: NSLocalizedString("Maybe next time", comment: ""),
                confirmTitle: NSLocalizedString("Review now", comment: "")
            )
            self?.autoreview_tryReviewApp(withInfo: info)
        }

        delay(3, work: remindAction)
    }
}

// MARK: - Alert

extension UIViewController {

    func alertSaveFileFailed() {
        YepAlert.alertSorry(message: NSLocalizedString("Yep can not save files!\nProbably not enough storage space.", comment: ""), inViewController: self)
    }
}


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
import AutoReview
import MonkeyKing

// MARK: - Heights

extension UIViewController {

    var statusBarHeight: CGFloat {

        if let window = view.window {
            let statusBarFrame = window.convert(UIApplication.shared.statusBarFrame, to: view)
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

// MARK: - Report

extension ReportReason {

    var title: String {
        switch self {
        case .porno:
            return String.trans_reportPorno
        case .advertising:
            return String.trans_reportAdvertising
        case .scams:
            return String.trans_reportScams
        case .other:
            return String.trans_reportOther
        }
    }
}

extension UIViewController {

    enum ReportObject {
        case user(ProfileUser)
        case feed(feedID: String)
        case message(messageID: String)
    }

    func report(_ object: ReportObject) {

        let reportWithReason: (ReportReason) -> Void = { [weak self] reason in

            switch object {

            case .user(let profileUser):
                reportProfileUser(profileUser, forReason: reason, failureHandler: { [weak self] (reason, errorMessage) in
                    if let errorMessage = errorMessage {
                        YepAlert.alertSorry(message: errorMessage, inViewController: self)
                    }

                }, completion: {
                })

            case .feed(let feedID):
                reportFeedWithFeedID(feedID, forReason: reason, failureHandler: { [weak self] (reason, errorMessage) in
                    if let errorMessage = errorMessage {
                        YepAlert.alertSorry(message: errorMessage, inViewController: self)
                    }

                }, completion: {
                })

            case .message(let messageID):
                reportMessageWithMessageID(messageID, forReason: reason, failureHandler: { [weak self] (reason, errorMessage) in
                    if let errorMessage = errorMessage {
                        YepAlert.alertSorry(message: errorMessage, inViewController: self)
                    }

                }, completion: {
                })
            }
        }

        let reportAlertController = UIAlertController(title: NSLocalizedString("Report Reason", comment: ""), message: nil, preferredStyle: .actionSheet)

        let pornoReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.porno.title, style: .default) { _ in
            reportWithReason(.porno)
        }
        reportAlertController.addAction(pornoReasonAction)

        let advertisingReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.advertising.title, style: .default) { _ in
            reportWithReason(.advertising)
        }
        reportAlertController.addAction(advertisingReasonAction)

        let scamsReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.scams.title, style: .default) { _ in
            reportWithReason(.scams)
        }
        reportAlertController.addAction(scamsReasonAction)

        let otherReasonAction: UIAlertAction = UIAlertAction(title: ReportReason.other("").title, style: .default) { [weak self] _ in
            YepAlert.textInput(title: String.trans_titleOtherReason, message: nil, placeholder: nil, oldText: nil, confirmTitle: String.trans_titleOK, cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: { text in
                reportWithReason(.other(text))
            }, cancelAction: nil)
        }
        reportAlertController.addAction(otherReasonAction)

        let cancelAction: UIAlertAction = UIAlertAction(title: String.trans_cancel, style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        reportAlertController.addAction(cancelAction)
        
        self.present(reportAlertController, animated: true, completion: nil)
    }
}

// MARK: - openURL

extension UIViewController {

    func yep_openURL(_ url: URL) {

        if let url = url.yep_validSchemeNetworkURL {
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: true, completion: nil)

        } else {
            YepAlert.alertSorry(message: String.trans_promptInvalidURL, inViewController: self)
        }
    }
}

// MARK: - Review

extension UIViewController {

    func remindUserToReview() {

        let remindAction: ()->() = { [weak self] in

            guard self?.view.window != nil else {
                return
            }

            let info = AutoReview.Info(
                appID: "983891256",
                title: NSLocalizedString("Review Yep", comment: ""),
                message: String.trans_promptAskForReview,
                doNotRemindMeInThisVersionTitle: String.trans_titleDoNotRemindMeInThisVersion,
                maybeNextTimeTitle: String.trans_titleMaybeNextTime,
                confirmTitle: NSLocalizedString("Review now", comment: "")
            )
            self?.autoreview_tryReviewApp(withInfo: info)
        }

        _ = delay(3, work: remindAction)
    }
}

// MARK: - Alert

extension UIViewController {

    func alertSaveFileFailed() {
        YepAlert.alertSorry(message: NSLocalizedString("Yep can not save files!\nProbably not enough storage space.", comment: ""), inViewController: self)
    }
}

// MARK: - Share

extension UIViewController {

    func yep_share<T: Any>(info sessionInfo: MonkeyKing.Info, timelineInfo: MonkeyKing.Info? = nil, defaultActivityItem activityItem: T, description: String? = nil) where T: Shareable {

        func weChatSessionActivity() -> WeChatActivity {

            let sessionMessage = MonkeyKing.Message.weChat(.session(info: sessionInfo))

            return WeChatActivity(
                type: .session,
                message: sessionMessage,
                completionHandler: { success in
                    println("share to WeChat Session success: \(success)")
                }
            )
        }

        func weChatTimelineActivity() -> WeChatActivity {

            let timelineMessage = MonkeyKing.Message.weChat(.timeline(info: timelineInfo ?? sessionInfo))

            return WeChatActivity(
                type: .timeline,
                message: timelineMessage,
                completionHandler: { success in
                    println("share to WeChat Timeline success: \(success)")
                }
            )
        }

        SafeDispatch.async { [weak self] in
            var activityItems: [Any] = [activityItem]
            if let description = description {
                activityItems.append(description)
            }
            let activityViewController = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: [
                    weChatSessionActivity(),
                    weChatTimelineActivity()
                ]
            )
            self?.present(activityViewController, animated: true, completion: nil)
        }
    }
}


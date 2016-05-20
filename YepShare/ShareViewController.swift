//
//  ShareViewController.swift
//  YepShare
//
//  Created by NIX on 16/5/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices.UTType
import YepNetworking

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.

        guard !(contentText ?? "").isEmpty else {
            return
        }

        guard let item = extensionContext?.inputItems.first as? NSExtensionItem else {
            return
        }

        guard let itemProvider = item.attachments?.first as? NSItemProvider else {
            return
        }

        let URLTypeIdentifier = kUTTypeURL as String
        guard itemProvider.hasItemConformingToTypeIdentifier(URLTypeIdentifier) else {
            return
        }

        itemProvider.loadItemForTypeIdentifier(URLTypeIdentifier, options: nil) { [weak self] secureCoding, error in

            guard error == nil else {
                return
            }

            guard let URL = secureCoding as? NSURL else {
                return
            }

            let message = (self?.contentText ?? "") + " " + URL.absoluteString

            YepNetworking.Manager.accessToken = {
                let appGroupID: String = "group.Catch-Inc.Yep"
                let userDefaults = NSUserDefaults(suiteName: appGroupID)
                let v1AccessTokenKey = "v1AccessToken"
                let token = userDefaults?.stringForKey(v1AccessTokenKey)
                return token
            }

            createFeedWithKind(.Text, message: message, attachments: nil, coordinate: nil, skill: nil, allowComment: true, failureHandler: nil) { [weak self] feed in
                print("share created feed: \(feed)")

                self?.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
            }
        }
    }

    override func configurationItems() -> [AnyObject]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}

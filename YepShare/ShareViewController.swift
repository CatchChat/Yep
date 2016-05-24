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
import YepKit
import YepNetworking
import OpenGraph

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {

        YepNetworking.Manager.accessToken = {
            let appGroupID: String = "group.Catch-Inc.Yep"
            let userDefaults = NSUserDefaults(suiteName: appGroupID)
            let v1AccessTokenKey = "v1AccessToken"
            let token = userDefaults?.stringForKey(v1AccessTokenKey)
            return token
        }

        return true
    }

    override func didSelectPost() {

        guard let item = extensionContext?.inputItems.first as? NSExtensionItem else {

            extensionContext?.completeRequestReturningItems([], completionHandler: nil)
            return
        }

        guard let itemProvider = item.attachments?.first as? NSItemProvider else {

            extensionContext?.completeRequestReturningItems([], completionHandler: nil)
            return
        }

        let URLTypeIdentifier = kUTTypeURL as String

        guard itemProvider.hasItemConformingToTypeIdentifier(URLTypeIdentifier) else {

            postFeed(message: contentText, URL: nil) { [weak self] finish in

                print("postFeed onlyText finish: \(finish)")

                self?.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
            }

            return
        }

        itemProvider.loadItemForTypeIdentifier(URLTypeIdentifier, options: nil) { [weak self] secureCoding, error in

            guard error == nil else {

                self?.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
                return
            }

            guard let URL = secureCoding as? NSURL else {

                self?.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
                return
            }

            self?.postFeed(message: self?.contentText, URL: URL) { [weak self] finish in

                print("postFeed URL finish: \(finish)")

                self?.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
            }
        }
    }

    override func configurationItems() -> [AnyObject]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

    private func postFeed(message message: String?, URL: NSURL?, completion: (finish: Bool) -> Void) {

        guard let URL = URL else {

            if let body = message where !body.isEmpty {

                createFeedWithKind(.Text, message: body, attachments: nil, coordinate: nil, skill: nil, allowComment: true, failureHandler: { reason, errorMessage in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    dispatch_async(dispatch_get_main_queue()) {
                        completion(finish: false)
                    }

                }, completion: { _ in
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(finish: true)
                    }
                })

            } else {
                completion(finish: false)
            }

            return
        }

        var kind: FeedKind = .Text

        var attachments: [JSONDictionary]?

        let parseOpenGraphGroup = dispatch_group_create()

        dispatch_group_enter(parseOpenGraphGroup)

        openGraphWithURL(URL, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            dispatch_async(dispatch_get_main_queue()) {
                dispatch_group_leave(parseOpenGraphGroup)
            }

        }, completion: { openGraph in

            kind = .URL

            let URLInfo = [
                "url": openGraph.URL.absoluteString,
                "site_name": (openGraph.siteName ?? "").yepshare_truncatedForFeed,
                "title": (openGraph.title ?? "").yepshare_truncatedForFeed,
                "description": (openGraph.description ?? "").yepshare_truncatedForFeed,
                "image_url": openGraph.previewImageURLString ?? "",
            ]

            attachments = [URLInfo]

            dispatch_async(dispatch_get_main_queue()) {
                dispatch_group_leave(parseOpenGraphGroup)
            }
        })

        dispatch_group_notify(parseOpenGraphGroup, dispatch_get_main_queue()) {

            let body: String
            if let message = message where !message.isEmpty {
                body = message + " " + URL.absoluteString
            } else {
                body = URL.absoluteString
            }

            createFeedWithKind(kind, message: body, attachments: attachments, coordinate: nil, skill: nil, allowComment: true, failureHandler: { reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                dispatch_async(dispatch_get_main_queue()) {
                    completion(finish: false)
                }
                
            }, completion: { _ in
                dispatch_async(dispatch_get_main_queue()) {
                    completion(finish: true)
                }
            })
        }
    }
}


//
//  MonkeyKing.swift
//  Yep
//
//  Created by nixzhu on 15/9/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

public func ==(lhs: MonkeyKing.Account, rhs: MonkeyKing.Account) -> Bool {
    return lhs.appID == rhs.appID
}

public class MonkeyKing {

    static let sharedMonkeyKing = MonkeyKing()

    public enum Account: Hashable {
        case WeChat(appID: String)

        func canOpenURL(URL: NSURL) -> Bool {
            return UIApplication.sharedApplication().canOpenURL(URL)
        }

        public var isAppInstalled: Bool {
            switch self {
            case .WeChat:
                return canOpenURL(NSURL(string: "weixin://")!)
            }
        }

        public var appID: String {
            switch self {
            case .WeChat(let appID):
                return appID
            }
        }

        public var hashValue: Int {
            return appID.hashValue
        }
    }

    var accountSet = Set<Account>()

    public class func registerAccount(account: Account) {

        if account.isAppInstalled {
            sharedMonkeyKing.accountSet.insert(account)
        }
    }

    public class func handleOpenURL(URL: NSURL) -> Bool {

        if URL.scheme.hasPrefix("wx") {

            if let data = UIPasteboard.generalPasteboard().dataForPasteboardType("content") {

                if let dic = (try? NSPropertyListSerialization.propertyListWithData(data, options: Int(NSPropertyListMutabilityOptions.Immutable.rawValue), format: nil)) as? NSDictionary {

                    for account in sharedMonkeyKing.accountSet {

                        switch account {

                        case .WeChat(let appID):

                            if let dic = dic[appID] as? NSDictionary {

                                if let result = dic["result"]?.integerValue {

                                    let success = (result == 0)

                                    sharedMonkeyKing.latestFinish?(success)

                                    return success
                                }
                            }
                        }
                    }
                }
            }

            return false
        }

        return false
    }

    public enum Message {

        public enum WeChatSubtype {

            public struct Info {
                let title: String?
                let description: String?
                let thumbnail: UIImage?

                public enum Media {
                    case URL(NSURL)
                    case Image(UIImage)
                }
                let media: Media

                public init(title: String?, description: String?, thumbnail: UIImage?, media: Media) {
                    self.title = title
                    self.description = description
                    self.thumbnail = thumbnail
                    self.media = media
                }
            }
            case Session(Info)
            case Timeline(Info)

            var scene: String {
                switch self {
                case .Session:
                    return "0"
                case .Timeline:
                    return "1"
                }
            }

            var info: Info {
                switch self {
                case .Session(let info):
                    return info
                case .Timeline(let info):
                    return info
                }
            }
        }
        case WeChat(WeChatSubtype)

        public var canBeDelivered: Bool {
            switch self {
            case .WeChat:
                for account in sharedMonkeyKing.accountSet {
                    switch account {
                    case .WeChat(let appID):
                        return account.isAppInstalled
                    }
                }

                return false
            }
        }
    }

    public typealias Finish = Bool -> Void

    var latestFinish: Finish?

    public class func shareMessage(message: Message, finish: Finish) {

        if !message.canBeDelivered {
            finish(false)
            return
        }

        sharedMonkeyKing.latestFinish = finish

        switch message {

        case .WeChat(let type):

            for account in sharedMonkeyKing.accountSet {

                switch account {

                case .WeChat(let appID):

                    var weChatMessageInfo: [String: AnyObject] = [
                        "result": "1",
                        "returnFromApp": "0",
                        "scene": type.scene,
                        "sdkver": "1.5",
                        "command": "1010",
                    ]

                    let info = type.info

                    if let title = info.title {
                        weChatMessageInfo["title"] = title
                    }

                    if let description = info.description {
                        weChatMessageInfo["description"] = description
                    }

                    if let thumbnailImage = info.thumbnail {
                        weChatMessageInfo["thumbData"] = UIImageJPEGRepresentation(thumbnailImage, 0.7)!
                    }

                    switch info.media {

                    case .URL(let URL):
                        weChatMessageInfo["objectType"] = "5"
                        weChatMessageInfo["mediaUrl"] = URL.absoluteString

                    case .Image(let image):
                        weChatMessageInfo["objectType"] = "2"
                        weChatMessageInfo["fileData"] = UIImageJPEGRepresentation(image, 1)!
                    }

                    let weChatMessage = [appID: weChatMessageInfo]

                    if let data = try? NSPropertyListSerialization.dataWithPropertyList(weChatMessage, format: NSPropertyListFormat.BinaryFormat_v1_0, options: NSPropertyListWriteOptions.allZeros) {

                        UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "content")

                        let weChatSchemeURLString = "weixin://app/\(appID)/sendreq/?"

                        if let URL = NSURL(string: weChatSchemeURLString) {

                            if UIApplication.sharedApplication().openURL(URL) {
                                return
                            } else {
                                finish(false)
                            }
                        }
                    }

                    finish(false)
                }
            }
        }
    }
}


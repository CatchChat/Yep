//
//  WeChatActivity.swift
//  Yep
//
//  Created by nixzhu on 15/9/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import MonkeyKing

final class WeChatActivity: AnyActivity {

    enum `Type` {

        case session
        case timeline

        var activityType: UIActivityType {
            switch self {
            case .session:
                return UIActivityType(rawValue: YepConfig.ChinaSocialNetwork.WeChat.sessionType)
            case .timeline:
                return UIActivityType(rawValue: YepConfig.ChinaSocialNetwork.WeChat.timelineType)
            }
        }

        var title: String {
            switch self {
            case .session:
                return YepConfig.ChinaSocialNetwork.WeChat.sessionTitle
            case .timeline:
                return YepConfig.ChinaSocialNetwork.WeChat.timelineTitle
            }
        }

        var image: UIImage {
            switch self {
            case .session:
                return YepConfig.ChinaSocialNetwork.WeChat.sessionImage
            case .timeline:
                return YepConfig.ChinaSocialNetwork.WeChat.timelineImage
            }
        }
    }

    init(type: Type, message: MonkeyKing.Message, completionHandler: @escaping MonkeyKing.DeliverCompletionHandler) {

        MonkeyKing.registerAccount(.weChat(appID: YepConfig.ChinaSocialNetwork.WeChat.appID, appKey: ""))

        super.init(
            type: type.activityType,
            title: type.title,
            image: type.image,
            message: message,
            completionHandler: completionHandler
        )
    }
}


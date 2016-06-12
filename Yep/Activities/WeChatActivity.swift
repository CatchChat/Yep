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

    enum Type {

        case Session
        case Timeline

        var type: String {
            switch self {
            case .Session:
                return YepConfig.ChinaSocialNetwork.WeChat.sessionType
            case .Timeline:
                return YepConfig.ChinaSocialNetwork.WeChat.timelineType
            }
        }

        var title: String {
            switch self {
            case .Session:
                return YepConfig.ChinaSocialNetwork.WeChat.sessionTitle
            case .Timeline:
                return YepConfig.ChinaSocialNetwork.WeChat.timelineTitle
            }
        }

        var image: UIImage {
            switch self {
            case .Session:
                return YepConfig.ChinaSocialNetwork.WeChat.sessionImage
            case .Timeline:
                return YepConfig.ChinaSocialNetwork.WeChat.timelineImage
            }
        }
    }

    init(type: Type, message: MonkeyKing.Message, finish: MonkeyKing.Finish) {

        MonkeyKing.registerAccount(.WeChat(appID: YepConfig.ChinaSocialNetwork.WeChat.appID))

        super.init(
            type: type.type,
            title: type.title,
            image: type.image,
            message: message,
            finish: finish
        )
    }
}


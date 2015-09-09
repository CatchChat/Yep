//
//  WeChatActivity.swift
//  Yep
//
//  Created by nixzhu on 15/9/9.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class WeChatActivity: UIActivity {

    enum Scene {
        case Session    // 聊天界面
        case Timeline   // 朋友圈

        var value: Int32 {
            switch self {
            case Session:
                return 0
            case Timeline:
                return 1
            }
        }

        var activityType: String {
            switch self {
            case Session:
                return "com.Catch Inc.Yep.shareToWeChatSession"
            case Timeline:
                return "com.Catch Inc.Yep.shareToWeChatTimeline"
            }
        }

        var activityTitle: String {
            switch self {
            case Session:
                return NSLocalizedString("WeChat Session", comment: "")
            case Timeline:
                return NSLocalizedString("WeChat Timeline", comment: "")
            }
        }

        var activityImage: UIImage? {
            switch self {
            case Session:
                return UIImage(named: "wechat_session")
            case Timeline:
                return UIImage(named: "wechat_timeline")
            }
        }
    }

    let scene: Scene

    init(scene: Scene) {
        self.scene = scene

        WXSceneSession
        super.init()
    }

    override class func activityCategory() -> UIActivityCategory {
        return .Share
    }

    override func activityType() -> String? {
        return scene.activityType
    }

    override func activityTitle() -> String? {
        return scene.activityTitle
    }

    override func activityImage() -> UIImage? {
        return scene.activityImage
    }

    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {

        println("Fuck WeChat!")
        println(WXApi.isWXAppInstalled())
        println(WXApi.isWXAppSupportApi())

        if WXApi.isWXAppSupportApi() {
            return true
        }

        return false
    }

    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        super.prepareWithActivityItems(activityItems)
    }

    override func activityViewController() -> UIViewController? {
        return super.activityViewController()
    }

    override func performActivity() {
        println("Share to WeChat")

        let sendMessageRequest = SendMessageToWXReq()

        sendMessageRequest.scene = scene.value

        let message = WXMediaMessage()
        message.title = "Yep! 遇见天才"
        message.description = "以技能匹配寻找共同话题，达成灵魂间的对话。"

        let webObject = WXWebpageObject()
        webObject.webpageUrl = "http://soyep.com"
        message.mediaObject = webObject

        sendMessageRequest.message = message

        WXApi.sendReq(sendMessageRequest)

        activityDidFinish(true)
    }

    // state method

    //func activityDidFinish(completed: Bool) // activity must call this when activity is finished. can be called on any thread
}



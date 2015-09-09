//
//  WeChatActivity.swift
//  Yep
//
//  Created by nixzhu on 15/9/9.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class WeChatActivity: UIActivity {

    override class func activityCategory() -> UIActivityCategory {
        return .Share
    }

    override func activityType() -> String? {
        return "com.Catch Inc.Yep"
    }

    override func activityTitle() -> String? {
        return "WeChat"
    }

    override func activityImage() -> UIImage? {
        return UIImage(named: "wechat_activity")
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

        sendMessageRequest.scene = 1
        //WXSceneSession  = 0,        // 聊天界面
        //WXSceneTimeline = 1,        // 朋友圈
        //WXSceneFavorite = 2,        // 收藏

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



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

    struct Message {
        let title: String?
        let description: String?
        let thumbnail: UIImage?

        enum Media {
            case URL(NSURL)
            case Image(UIImage)
        }

        let media: Media
    }

    let scene: Scene
    let message: Message

    init(scene: Scene, message: Message) {
        self.scene = scene
        self.message = message

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

        if WXApi.isWXAppInstalled() && WXApi.isWXAppSupportApi() {
            return true
        }

        return false
    }

    override func performActivity() {

        let sendMessageRequest = SendMessageToWXReq()

        sendMessageRequest.scene = scene.value

        let message = WXMediaMessage()

        message.title = self.message.title
        message.description = self.message.description
        message.setThumbImage(self.message.thumbnail)

        switch self.message.media {

        case .URL(let URL):
            let webObject = WXWebpageObject()
            webObject.webpageUrl = URL.absoluteString!
            message.mediaObject = webObject

        case .Image(let image):
            let imageObject = WXImageObject()
            imageObject.imageData = UIImageJPEGRepresentation(image, 1)
            message.mediaObject = imageObject
        }

        sendMessageRequest.message = message

        WXApi.sendReq(sendMessageRequest)

        activityDidFinish(true)
    }
}



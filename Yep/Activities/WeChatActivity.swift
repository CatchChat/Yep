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
        return true
    }

    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        super.prepareWithActivityItems(activityItems)
    }

    override func activityViewController() -> UIViewController? {
        return super.activityViewController()
    }

    override func performActivity() {
        println("Hello WeChat")
    }

    // state method

    //func activityDidFinish(completed: Bool) // activity must call this when activity is finished. can be called on any thread
}



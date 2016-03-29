//
//  FeedSearch.swift
//  Yep
//
//  Created by NIX on 16/3/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import CoreSpotlight

@available(iOS 9.0, *)
extension Feed {

    static let domainID = "Catch-Inc.Yep.Feed"

    var userActivityUserInfo: [NSObject: AnyObject] {
        return ["feedID": feedID]
    }

    var userActivity: NSUserActivity {
        let activity = NSUserActivity(activityType: Feed.domainID)
        activity.title = body
        activity.userInfo = userActivityUserInfo
        activity.keywords = [body]
    }
}

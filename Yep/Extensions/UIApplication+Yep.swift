//
//  UIApplication+Yep.swift
//  Yep
//
//  Created by NIX on 16/7/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

extension UIApplication {

    func yep_reviewOnTheAppStore() {

        let appID = "983891256"

        guard let appURL = NSURL(string: "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=\(appID)&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8") else {
            return
        }

        if canOpenURL(appURL) {
            openURL(appURL)
        }
    }
}


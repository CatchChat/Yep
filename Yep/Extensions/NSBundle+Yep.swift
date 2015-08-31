//
//  NSBundle+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/8/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation

extension NSBundle {

    static var releaseVersionNumber: String? {
        return NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String
    }

    static var buildVersionNumber: String? {
        return NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String
    }
}
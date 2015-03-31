//
//  YepConfig.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class YepConfig {
    class func clientType() -> Int {
        // TODO: clientType
        return 2
    }

    class func avatarMaxSize() -> CGSize {
        return CGSize(width: 600, height: 600)
    }

    class func avatarCompressionQuality() -> CGFloat {
        return 0.7
    }

    class func messageImageCompressionQuality() -> CGFloat {
        return 0.8
    }
}
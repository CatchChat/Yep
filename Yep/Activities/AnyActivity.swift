//
//  AnyActivity.swift
//  Yep
//
//  Created by nixzhu on 15/9/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

public class AnyActivity: UIActivity {

    let type: String
    let title: String
    let image: UIImage

    let canPerform: Bool
    let perform: () -> Void

    public init(type: String, title: String, image: UIImage, canPerform: Bool, perform: () -> Void) {

        self.type = type
        self.title = title
        self.image = image

        self.canPerform = canPerform
        self.perform = perform

        super.init()
    }

    override public class func activityCategory() -> UIActivityCategory {
        return .Share
    }

    override public func activityType() -> String? {
        return type
    }

    override public  func activityTitle() -> String? {
        return title
    }

    override public func activityImage() -> UIImage? {
        return image
    }

    override public func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return canPerform
    }

    override public func performActivity() {
        perform()
        activityDidFinish(true)
    }
}


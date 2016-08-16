//
//  UISegmentedControl+Yep.swift
//  Yep
//
//  Created by NIX on 16/8/3.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension UISegmentedControl {

    func yep_setTitleFont(font: UIFont, withPadding padding: CGFloat) {

        let attributes = [NSFontAttributeName: font]

        setTitleTextAttributes(attributes, forState: .Normal)

        var maxWidth: CGFloat = 0
        for i in 0..<numberOfSegments {
            if let title = titleForSegmentAtIndex(i) {
                let width = (title as NSString).sizeWithAttributes(attributes).width + (padding * 2)
                maxWidth = max(maxWidth, width)
            }
        }

        for i in 0..<numberOfSegments {
            setWidth(maxWidth, forSegmentAtIndex: i)
        }
    }
}


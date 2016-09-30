//
//  UISegmentedControl+Yep.swift
//  Yep
//
//  Created by NIX on 16/8/3.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension UISegmentedControl {

    func yep_setTitleFont(_ font: UIFont, withPadding padding: CGFloat) {

        let attributes = [NSFontAttributeName: font]

        setTitleTextAttributes(attributes, for: .normal)

        var maxWidth: CGFloat = 0
        for i in 0..<numberOfSegments {
            if let title = titleForSegment(at: i) {
                let width = (title as NSString).size(attributes: attributes).width + (padding * 2)
                maxWidth = max(maxWidth, width)
            }
        }

        for i in 0..<numberOfSegments {
            setWidth(maxWidth, forSegmentAt: i)
        }
    }
}


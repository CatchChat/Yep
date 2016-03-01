//
//  UIScrollView+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/11/2.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension UIScrollView {

    var yep_isAtTop: Bool {

        return contentOffset.y == -contentInset.top
    }

    func yep_scrollsToTop() {

        let topPoint = CGPoint(x: 0, y: -contentInset.top)
        setContentOffset(topPoint, animated: true)
    }

    func yep_zoomToPoint(zoomPoint: CGPoint, withScale scale: CGFloat, animated: Bool) {

        println("-zoomPoint: \(zoomPoint)")

        let contentSize = CGSize(
            width: self.contentSize.width / self.zoomScale,
            height: self.contentSize.height / self.zoomScale
        )
        println("contentSize: \(contentSize)")

        let zoomPoint = CGPoint(
            x: (zoomPoint.x / self.bounds.size.width) * contentSize.width,
            y: (zoomPoint.y / self.bounds.size.height) * contentSize.height
        )
        println("zoomPoint: \(zoomPoint)")

        let zoomSize = CGSize(
            width: self.bounds.size.width / scale,
            height: self.bounds.size.height / scale
        )
        println("zoomSize: \(zoomSize)")

        let zoomRect = CGRect(
            x: zoomPoint.x - zoomSize.width / 2.0,
            y: zoomPoint.y - zoomSize.height / 2.0,
            width: zoomSize.width,
            height: zoomSize.height
        )
        println("zoomRect: \(zoomRect)")

        self.zoomToRect(zoomRect, animated: animated)
    }
}


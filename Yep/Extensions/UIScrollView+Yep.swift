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

    /*
    func yep_zoomToPoint(zoomPoint: CGPoint, withScale scale: CGFloat, animated: Bool) {

        println("-zoomPoint: \(zoomPoint)")
        println("-self.contentSize: \(self.contentSize)")
        println("-self.contentOffset: \(self.contentOffset)")
        println("-self.contentInset: \(self.contentInset)")
        println("-self.zoomScale: \(self.zoomScale)")

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
    */

    ///*
    func yep_zoomToPoint(zoomPoint: CGPoint, withScale scale: CGFloat, animated: Bool) {

        println("-zoomPoint: \(zoomPoint)")
        println("-self.contentSize: \(self.contentSize)")
        println("-self.contentOffset: \(self.contentOffset)")
        println("-self.contentInset: \(self.contentInset)")
        println("-self.zoomScale: \(self.zoomScale)")

        var scale = min(scale, maximumZoomScale)
        scale = max(scale, minimumZoomScale)
        println("scale: \(scale)")

        let zoomFactor = 1.0 / self.zoomScale

        let translatedZoomPoint = CGPoint(
            x: (zoomPoint.x + self.contentOffset.x) * zoomFactor,
            y: (zoomPoint.y + self.contentOffset.y) * zoomFactor
        )
        println("translatedZoomPoint: \(translatedZoomPoint)")

        let destinationRectWidth = self.bounds.width / scale
        let destinationRectHeight = self.bounds.height / scale
        let destinationRect = CGRect(
            x: translatedZoomPoint.x - destinationRectWidth * 0.5,
            y: translatedZoomPoint.y - destinationRectHeight * 0.5,
            width: destinationRectWidth,
            height: destinationRectHeight
        )
        println("destinationRect: \(destinationRect)")

        self.zoomToRect(destinationRect, animated: animated)

        println("-self.contentSize: \(self.contentSize)")
        println("-self.contentOffset: \(self.contentOffset)")
        println("-self.contentInset: \(self.contentInset)")
        println("-self.zoomScale: \(self.zoomScale)")

        /*
        if animated {
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 01.0, initialSpringVelocity: 0.6, options: [.AllowUserInteraction], animations: { _ in
                self.zoomToRect(destinationRect, animated: animated)
            }, completion: { finished in
                if let delegate = self.delegate where delegate.respondsToSelector("scrollViewDidEndZooming:withView:atScale:") {
                    delegate.scrollViewDidEndZooming!(self, withView: delegate.viewForZoomingInScrollView!(self), atScale: scale)
                }
            })
        } else {
            self.zoomToRect(destinationRect, animated: false)
        }
        */
    }
    //*/
}


//
//  UIImageView+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/12/3.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import CoreLocation

// MARK: - ActivityIndicator

private var activityIndicatorKey: Void?
private var showActivityIndicatorWhenLoadingKey: Void?

extension UIImageView {

    private var yep_activityIndicator: UIActivityIndicatorView? {
        return objc_getAssociatedObject(self, &activityIndicatorKey) as? UIActivityIndicatorView
    }

    private func yep_setActivityIndicator(activityIndicator: UIActivityIndicatorView?) {
        objc_setAssociatedObject(self, &activityIndicatorKey, activityIndicator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public var yep_showIndicatorWhenLoading: Bool {
        get {
            guard let result = objc_getAssociatedObject(self, &showActivityIndicatorWhenLoadingKey) as? NSNumber else {
                return false
            }

            return result.boolValue
        }

        set {
            if yep_showIndicatorWhenLoading == newValue {
                return

            } else {
                if newValue {
                    let indicatorStyle = UIActivityIndicatorViewStyle.Gray
                    let indicator = UIActivityIndicatorView(activityIndicatorStyle: indicatorStyle)
                    indicator.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))

                    indicator.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleTopMargin]
                    indicator.hidden = true
                    indicator.hidesWhenStopped = true

                    self.addSubview(indicator)

                    yep_setActivityIndicator(indicator)

                } else {
                    yep_activityIndicator?.removeFromSuperview()
                    yep_setActivityIndicator(nil)
                }

                objc_setAssociatedObject(self, &showActivityIndicatorWhenLoadingKey, NSNumber(bool: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}

// MARK: - AttachmentURL

private var attachmentURLKey: Void?

extension UIImageView {

    private var yep_attachmentURL: NSURL? {
        return objc_getAssociatedObject(self, &attachmentURLKey) as? NSURL
    }

    private func yep_setAttachmentURL(URL: NSURL) {
        objc_setAssociatedObject(self, &attachmentURLKey, URL, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func yep_setImageOfAttachment(attachment: DiscoveredAttachment, withSize size: CGSize) {

        guard let attachmentURL = NSURL(string: attachment.URLString) else {
            return
        }

        yep_setAttachmentURL(attachmentURL)

        ImageCache.sharedInstance.imageOfAttachment(attachment, withMinSideLength: size.width, completion: { [weak self] (url, image, cacheType) in

            guard let strongSelf = self, yep_attachmentURL = strongSelf.yep_attachmentURL where yep_attachmentURL == url else {
                return
            }

            if cacheType != .Memory {
                UIView.transitionWithView(strongSelf, duration: imageFadeTransitionDuration, options: .TransitionCrossDissolve, animations: { () -> Void in
                    strongSelf.image = image
                }, completion: nil)

            } else {
                strongSelf.image = image
            }

            println("imageOfAttachment cacheType: \(cacheType)")
        })
    }
}

// MARK: - Location

private var locationxKey: Void?

extension UIImageView {

    private var yep_location: CLLocation? {
        return objc_getAssociatedObject(self, &locationxKey) as? CLLocation
    }

    private func yep_setLocation(location: CLLocation) {
        objc_setAssociatedObject(self, &locationxKey, location, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func yep_setImageOfLocation(location: CLLocation, withSize size: CGSize) {

        yep_setLocation(location)

        ImageCache.sharedInstance.mapImageOfLocationCoordinate(location.coordinate, withSize: size, completion: { [weak self] image in

            guard let strongSelf = self, _location = strongSelf.yep_location where _location == location else {
                return
            }

            UIView.transitionWithView(strongSelf, duration: imageFadeTransitionDuration, options: .TransitionCrossDissolve, animations: { () -> Void in
                strongSelf.image = image
            }, completion: nil)
        })
    }
}


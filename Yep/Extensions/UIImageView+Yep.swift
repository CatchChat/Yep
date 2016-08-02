//
//  UIImageView+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/12/3.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import CoreLocation
import YepKit

// MARK: - ActivityIndicator

private var activityIndicatorAssociatedKey: Void?
private var showActivityIndicatorWhenLoadingAssociatedKey: Void?

extension UIImageView {

    private var yep_activityIndicator: UIActivityIndicatorView? {
        return objc_getAssociatedObject(self, &activityIndicatorAssociatedKey) as? UIActivityIndicatorView
    }

    private func yep_setActivityIndicator(activityIndicator: UIActivityIndicatorView?) {
        objc_setAssociatedObject(self, &activityIndicatorAssociatedKey, activityIndicator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public var yep_showActivityIndicatorWhenLoading: Bool {
        get {
            guard let result = objc_getAssociatedObject(self, &showActivityIndicatorWhenLoadingAssociatedKey) as? NSNumber else {
                return false
            }

            return result.boolValue
        }

        set {
            if yep_showActivityIndicatorWhenLoading == newValue {
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

                objc_setAssociatedObject(self, &showActivityIndicatorWhenLoadingAssociatedKey, NSNumber(bool: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}

// MARK: - Message Image

private var messageImageAssociatedKey: Void?

extension UIImageView {

    private var yep_messageImageKey: String? {
        return objc_getAssociatedObject(self, &messageImageAssociatedKey) as? String
    }

    private func yep_setMessageImageKey(messageImageKey: String) {
        objc_setAssociatedObject(self, &messageImageAssociatedKey, messageImageKey, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func yep_setImageOfMessage(message: Message, withSize size: CGSize, tailDirection: MessageImageTailDirection, completion: (loadingProgress: Double, image: UIImage?) -> Void) {

        let imageKey = message.imageKey

        yep_setMessageImageKey(imageKey)

        ImageCache.sharedInstance.imageOfMessage(message, withSize: size, tailDirection: tailDirection, completion: { [weak self] progress, image in

            guard let strongSelf = self, _imageKey = strongSelf.yep_messageImageKey where _imageKey == imageKey else {
                return
            }

            completion(loadingProgress: progress, image: image)
        })
    }
}

// MARK: - Message Map Image

private var messageMapImageAssociatedKey: Void?

extension UIImageView {

    private var yep_messageMapImageKey: String? {
        return objc_getAssociatedObject(self, &messageMapImageAssociatedKey) as? String
    }

    private func yep_setMessageMapImageKey(messageMapImageKey: String) {
        objc_setAssociatedObject(self, &messageMapImageAssociatedKey, messageMapImageKey, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func yep_setMapImageOfMessage(message: Message, withSize size: CGSize, tailDirection: MessageImageTailDirection) {

        let imageKey = message.mapImageKey

        yep_setMessageMapImageKey(imageKey)

        let locationName = message.textContent
        ImageCache.sharedInstance.mapImageOfMessage(message, withSize: size, tailDirection: tailDirection, bottomShadowEnabled: !locationName.isEmpty) { [weak self] mapImage in

            guard let strongSelf = self, _imageKey = strongSelf.yep_messageMapImageKey where _imageKey == imageKey else {
                return
            }

            SafeDispatch.async { [weak self] in
                self?.image = mapImage
            }
        }
    }
}

// MARK: - AttachmentURL

private var attachmentURLAssociatedKey: Void?

extension UIImageView {

    private var yep_attachmentURL: NSURL? {
        return objc_getAssociatedObject(self, &attachmentURLAssociatedKey) as? NSURL
    }

    private func yep_setAttachmentURL(URL: NSURL) {
        objc_setAssociatedObject(self, &attachmentURLAssociatedKey, URL, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func yep_setImageOfAttachment(attachment: DiscoveredAttachment, withSize size: CGSize) {

        guard let attachmentURL = NSURL(string: attachment.URLString) else {
            return
        }

        let showActivityIndicatorWhenLoading = yep_showActivityIndicatorWhenLoading
        var activityIndicator: UIActivityIndicatorView? = nil

        if showActivityIndicatorWhenLoading {
            activityIndicator = yep_activityIndicator
            activityIndicator?.hidden = false
            activityIndicator?.startAnimating()
        }

        yep_setAttachmentURL(attachmentURL)

        ImageCache.sharedInstance.imageOfAttachment(attachment, withMinSideLength: size.width, completion: { [weak self] (url, image, cacheType) in

            guard let strongSelf = self, yep_attachmentURL = strongSelf.yep_attachmentURL where yep_attachmentURL == url else {
                return
            }

            if cacheType != .Memory {
                UIView.transitionWithView(strongSelf, duration: imageFadeTransitionDuration, options: .TransitionCrossDissolve, animations: { [weak self] in
                    self?.image = image
                }, completion: nil)

            } else {
                strongSelf.image = image
            }

            activityIndicator?.stopAnimating()
        })
    }
}

// MARK: - Location

private var locationAssociatedKey: Void?

extension UIImageView {

    private var yep_location: CLLocation? {
        return objc_getAssociatedObject(self, &locationAssociatedKey) as? CLLocation
    }

    private func yep_setLocation(location: CLLocation) {
        objc_setAssociatedObject(self, &locationAssociatedKey, location, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func yep_setImageOfLocation(location: CLLocation, withSize size: CGSize) {

        let showActivityIndicatorWhenLoading = yep_showActivityIndicatorWhenLoading
        var activityIndicator: UIActivityIndicatorView? = nil

        if showActivityIndicatorWhenLoading {
            activityIndicator = yep_activityIndicator
            activityIndicator?.hidden = false
            activityIndicator?.startAnimating()
        }

        yep_setLocation(location)

        ImageCache.sharedInstance.mapImageOfLocationCoordinate(location.coordinate, withSize: size, completion: { [weak self] image in

            guard let strongSelf = self, _location = strongSelf.yep_location where _location == location else {
                return
            }

            UIView.transitionWithView(strongSelf, duration: imageFadeTransitionDuration, options: .TransitionCrossDissolve, animations: { [weak self] in
                self?.image = image
            }, completion: nil)

            activityIndicator?.stopAnimating()
        })
    }
}


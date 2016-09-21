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

    fileprivate var yep_activityIndicator: UIActivityIndicatorView? {
        return objc_getAssociatedObject(self, &activityIndicatorAssociatedKey) as? UIActivityIndicatorView
    }

    fileprivate func yep_setActivityIndicator(_ activityIndicator: UIActivityIndicatorView?) {
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
                    let indicatorStyle = UIActivityIndicatorViewStyle.gray
                    let indicator = UIActivityIndicatorView(activityIndicatorStyle: indicatorStyle)
                    indicator.center = CGPoint(x: bounds.midX, y: bounds.midY)

                    indicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleTopMargin]
                    indicator.isHidden = true
                    indicator.hidesWhenStopped = true

                    self.addSubview(indicator)

                    yep_setActivityIndicator(indicator)

                } else {
                    yep_activityIndicator?.removeFromSuperview()
                    yep_setActivityIndicator(nil)
                }

                objc_setAssociatedObject(self, &showActivityIndicatorWhenLoadingAssociatedKey, NSNumber(value: newValue as Bool), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}

// MARK: - Message Image

private var messageImageAssociatedKey: Void?

extension UIImageView {

    fileprivate var yep_messageImageKey: String? {
        return objc_getAssociatedObject(self, &messageImageAssociatedKey) as? String
    }

    fileprivate func yep_setMessageImageKey(_ messageImageKey: String) {
        objc_setAssociatedObject(self, &messageImageAssociatedKey, messageImageKey, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func yep_setImageOfMessage(_ message: Message, withSize size: CGSize, tailDirection: MessageImageTailDirection, completion: @escaping (_ loadingProgress: Double, _ image: UIImage?) -> Void) {

        let imageKey = message.imageKey

        yep_setMessageImageKey(imageKey)

        ImageCache.sharedInstance.imageOfMessage(message, withSize: size, tailDirection: tailDirection, completion: { [weak self] progress, image in

            guard let strongSelf = self, let _imageKey = strongSelf.yep_messageImageKey , _imageKey == imageKey else {
                return
            }

            completion(progress, image)
        })
    }
}

// MARK: - Message Map Image

private var messageMapImageAssociatedKey: Void?

extension UIImageView {

    fileprivate var yep_messageMapImageKey: String? {
        return objc_getAssociatedObject(self, &messageMapImageAssociatedKey) as? String
    }

    fileprivate func yep_setMessageMapImageKey(_ messageMapImageKey: String) {
        objc_setAssociatedObject(self, &messageMapImageAssociatedKey, messageMapImageKey, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func yep_setMapImageOfMessage(_ message: Message, withSize size: CGSize, tailDirection: MessageImageTailDirection) {

        let imageKey = message.mapImageKey

        yep_setMessageMapImageKey(imageKey)

        let locationName = message.textContent
        ImageCache.sharedInstance.mapImageOfMessage(message, withSize: size, tailDirection: tailDirection, bottomShadowEnabled: !locationName.isEmpty) { [weak self] mapImage in

            guard let strongSelf = self, let _imageKey = strongSelf.yep_messageMapImageKey , _imageKey == imageKey else {
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

    fileprivate var yep_attachmentURL: URL? {
        return objc_getAssociatedObject(self, &attachmentURLAssociatedKey) as? URL
    }

    fileprivate func yep_setAttachmentURL(_ URL: Foundation.URL) {
        objc_setAssociatedObject(self, &attachmentURLAssociatedKey, URL, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func yep_setImageOfAttachment(_ attachment: DiscoveredAttachment, withSize size: CGSize) {

        guard let attachmentURL = URL(string: attachment.URLString) else {
            return
        }

        let showActivityIndicatorWhenLoading = yep_showActivityIndicatorWhenLoading
        var activityIndicator: UIActivityIndicatorView? = nil

        if showActivityIndicatorWhenLoading {
            activityIndicator = yep_activityIndicator
            activityIndicator?.isHidden = false
            activityIndicator?.startAnimating()
        }

        yep_setAttachmentURL(attachmentURL)

        ImageCache.sharedInstance.imageOfAttachment(attachment, withMinSideLength: size.width, completion: { [weak self] (url, image, cacheType) in

            guard let strongSelf = self, let yep_attachmentURL = strongSelf.yep_attachmentURL , yep_attachmentURL == url else {
                return
            }

            if case .memory = cacheType {
                strongSelf.image = image

            } else {
                UIView.transition(with: strongSelf, duration: imageFadeTransitionDuration, options: .TransitionCrossDissolve, animations: { [weak self] in
                    self?.image = image
                }, completion: nil)
            }

            activityIndicator?.stopAnimating()
        })
    }
}

// MARK: - Location

private var locationAssociatedKey: Void?

extension UIImageView {

    fileprivate var yep_location: CLLocation? {
        return objc_getAssociatedObject(self, &locationAssociatedKey) as? CLLocation
    }

    fileprivate func yep_setLocation(_ location: CLLocation) {
        objc_setAssociatedObject(self, &locationAssociatedKey, location, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func yep_setImageOfLocation(_ location: CLLocation, withSize size: CGSize) {

        let showActivityIndicatorWhenLoading = yep_showActivityIndicatorWhenLoading
        var activityIndicator: UIActivityIndicatorView? = nil

        if showActivityIndicatorWhenLoading {
            activityIndicator = yep_activityIndicator
            activityIndicator?.isHidden = false
            activityIndicator?.startAnimating()
        }

        yep_setLocation(location)

        ImageCache.sharedInstance.mapImageOfLocationCoordinate(location.coordinate, withSize: size, completion: { [weak self] image in

            guard let strongSelf = self, let _location = strongSelf.yep_location , _location == location else {
                return
            }

            UIView.transition(with: strongSelf, duration: imageFadeTransitionDuration, options: .transitionCrossDissolve, animations: { [weak self] in
                self?.image = image
            }, completion: nil)

            activityIndicator?.stopAnimating()
        })
    }
}


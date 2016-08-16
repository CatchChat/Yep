//
//  ASImageNode+Yep.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import YepKit
import Navi
import AsyncDisplayKit

private var avatarKeyAssociatedObject: Void?

extension ASImageNode {

    private var navi_avatarKey: String? {
        return objc_getAssociatedObject(self, &avatarKeyAssociatedObject) as? String
    }

    private func navi_setAvatarKey(avatarKey: String) {
        objc_setAssociatedObject(self, &avatarKeyAssociatedObject, avatarKey, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func navi_setAvatar(avatar: Navi.Avatar, withFadeTransitionDuration fadeTransitionDuration: NSTimeInterval = 0) {

        navi_setAvatarKey(avatar.key)

        AvatarPod.wakeAvatar(avatar) { [weak self] finished, image, cacheType in

            guard let strongSelf = self, avatarKey = strongSelf.navi_avatarKey where avatarKey == avatar.key else {
                return
            }

            if finished && cacheType != .Memory {
                UIView.transitionWithView(strongSelf.view, duration: fadeTransitionDuration, options: .TransitionCrossDissolve, animations: {
                    self?.image = image
                }, completion: nil)

            } else {
                self?.image = image
            }
        }
    }
}

private var messageKey: Void?

extension ASImageNode {

    private var yep_messageImageKey: String? {
        return objc_getAssociatedObject(self, &messageKey) as? String
    }

    private func yep_setMessageImageKey(messageImageKey: String) {
        objc_setAssociatedObject(self, &messageKey, messageImageKey, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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

// MARK: - ActivityIndicator

private var activityIndicatorAssociatedKey: Void?
private var showActivityIndicatorWhenLoadingAssociatedKey: Void?

extension ASImageNode {

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

                    self.view.addSubview(indicator)

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

// MARK: - AttachmentURL

private var attachmentURLAssociatedKey: Void?

extension ASImageNode {

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
                UIView.transitionWithView(strongSelf.view, duration: imageFadeTransitionDuration, options: .TransitionCrossDissolve, animations: { [weak self] in
                    self?.image = image
                }, completion: nil)

            } else {
                strongSelf.image = image
            }
            
            activityIndicator?.stopAnimating()
        })
    }
}

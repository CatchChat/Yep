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

    fileprivate var navi_avatarKey: String? {
        return objc_getAssociatedObject(self, &avatarKeyAssociatedObject) as? String
    }

    fileprivate func navi_setAvatarKey(_ avatarKey: String) {
        objc_setAssociatedObject(self, &avatarKeyAssociatedObject, avatarKey, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func navi_setAvatar(_ avatar: Navi.Avatar, withFadeTransitionDuration fadeTransitionDuration: TimeInterval = 0) {

        navi_setAvatarKey(avatar.key)

        AvatarPod.wakeAvatar(avatar) { [weak self] finished, image, cacheType in

            guard let strongSelf = self, let avatarKey = strongSelf.navi_avatarKey , avatarKey == avatar.key else {
                return
            }

            if finished && cacheType != .memory {
                UIView.transition(with: strongSelf.view, duration: fadeTransitionDuration, options: .transitionCrossDissolve, animations: {
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

    fileprivate var yep_messageImageKey: String? {
        return objc_getAssociatedObject(self, &messageKey) as? String
    }

    fileprivate func yep_setMessageImageKey(_ messageImageKey: String) {
        objc_setAssociatedObject(self, &messageKey, messageImageKey, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func yep_setImageOfMessage(_ message: Message, withSize size: CGSize, tailDirection: MessageImageTailDirection, completion: @escaping (_ loadingProgress: Double, _ image: UIImage?) -> Void) {

        let imageKey = message.imageKey

        yep_setMessageImageKey(imageKey)

        YepImageCache.sharedInstance.imageOfMessage(message, withSize: size, tailDirection: tailDirection, completion: { [weak self] progress, image in

            guard let strongSelf = self, let _imageKey = strongSelf.yep_messageImageKey , _imageKey == imageKey else {
                return
            }

            completion(progress, image)
        })
    }
}

// MARK: - ActivityIndicator

private var activityIndicatorAssociatedKey: Void?
private var showActivityIndicatorWhenLoadingAssociatedKey: Void?

extension ASImageNode {

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

                    self.view.addSubview(indicator)

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

// MARK: - AttachmentURL

private var attachmentURLAssociatedKey: Void?

extension ASImageNode {

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

        YepImageCache.sharedInstance.imageOfAttachment(attachment, withMinSideLength: size.width, completion: { [weak self] (url, image, cacheType) in

            guard let strongSelf = self, let yep_attachmentURL = strongSelf.yep_attachmentURL , yep_attachmentURL == url else {
                return
            }

            if cacheType != .memory {
                UIView.transition(with: strongSelf.view, duration: imageFadeTransitionDuration, options: .transitionCrossDissolve, animations: { [weak self] in
                    self?.image = image
                }, completion: nil)

            } else {
                strongSelf.image = image
            }
            
            activityIndicator?.stopAnimating()
        })
    }
}

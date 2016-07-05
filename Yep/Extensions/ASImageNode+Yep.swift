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

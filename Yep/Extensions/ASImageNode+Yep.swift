//
//  ASImageNode+Yep.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

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

    func navi_setAvatar(avatar: Avatar, withFadeTransitionDuration fadeTransitionDuration: NSTimeInterval = 0) {

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


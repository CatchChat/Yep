//
//  UIImageView+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/12/3.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

private var attachmentURLKey: Void?

extension UIImageView {

    var yep_attachmentURL: NSURL? {
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

        ImageCache.sharedInstance.imageOfAttachment(attachment, withSize: size, completion: { [weak self] (url, image) in

            guard let strongSelf = self, yep_attachmentURL = strongSelf.yep_attachmentURL where yep_attachmentURL == url else {
                return
            }

            UIView.transitionWithView(strongSelf, duration: 0.3, options: .TransitionCrossDissolve, animations: { () -> Void in
                strongSelf.image = image
            }, completion: nil)
        })
    }
}


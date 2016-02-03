//
//  FeedMediaView.swift
//  Yep
//
//  Created by nixzhu on 15/9/28.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedMediaView: UIView {
    
    var attachmentURLs = [NSURL]()

    lazy var imageView1: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    lazy var imageView2: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    lazy var imageView3: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    lazy var imageView4: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    func setImagesWithAttachments(attachments: [DiscoveredAttachment]) {

        let fullRect = bounds
        let halfRect = CGRect(x: 0, y: 0, width: fullRect.width * 0.5, height: fullRect.height)
        let quarterRect = CGRect(x: 0, y: 0, width: fullRect.width * 0.5, height: fullRect.height * 0.5)

        hidden = (attachments.count == 0)
        
        attachmentURLs = attachments.map({ NSURL(string: $0.URLString) }).flatMap({ $0 })

        switch attachments.count {

        case 1:
            imageView1.frame = fullRect

            if let thumbnailImage = attachments[0].thumbnailImage {
                imageView1.image = thumbnailImage

            } else {
                imageView1.yep_setImageOfAttachment(attachments[0], withSize: fullRect.size)
            }

            addSubview(imageView1)

        case 2:
            imageView1.frame = halfRect
            imageView1.center = CGPoint(x: halfRect.width * 0.5, y: imageView1.center.y)

            if let thumbnailImage = attachments[0].thumbnailImage {
                imageView1.image = thumbnailImage

            } else {
                imageView1.yep_setImageOfAttachment(attachments[0], withSize: halfRect.size)
            }

            imageView2.frame = halfRect
            imageView2.center = CGPoint(x: halfRect.width * 1.5, y: imageView2.center.y)

            if let thumbnailImage = attachments[1].thumbnailImage {
                imageView2.image = thumbnailImage

            } else {
                imageView2.yep_setImageOfAttachment(attachments[1], withSize: halfRect.size)
            }

            addSubview(imageView1)
            addSubview(imageView2)

        case 3:
            imageView1.frame = quarterRect

            if let thumbnailImage = attachments[0].thumbnailImage {
                imageView1.image = thumbnailImage

            } else {
                imageView1.yep_setImageOfAttachment(attachments[0], withSize: quarterRect.size)
            }

            imageView2.frame = quarterRect
            imageView2.center = CGPoint(x: imageView2.center.x, y: quarterRect.height * 1.5)

            if let thumbnailImage = attachments[1].thumbnailImage {
                imageView2.image = thumbnailImage

            } else {
                imageView2.yep_setImageOfAttachment(attachments[1], withSize: quarterRect.size)
            }

            imageView3.frame = halfRect
            imageView3.center = CGPoint(x: halfRect.width * 1.5, y: imageView3.center.y)

            if let thumbnailImage = attachments[2].thumbnailImage {
                imageView3.image = thumbnailImage

            } else {
                imageView3.yep_setImageOfAttachment(attachments[2], withSize: halfRect.size)
            }

            addSubview(imageView1)
            addSubview(imageView2)
            addSubview(imageView3)

        case 4..<Int.max:

            imageView1.frame = quarterRect

            if let thumbnailImage = attachments[0].thumbnailImage {
                imageView1.image = thumbnailImage

            } else {
                imageView1.yep_setImageOfAttachment(attachments[0], withSize: quarterRect.size)
            }

            imageView2.frame = quarterRect
            imageView2.center = CGPoint(x: imageView2.center.x, y: quarterRect.height * 1.5)

            if let thumbnailImage = attachments[1].thumbnailImage {
                imageView2.image = thumbnailImage

            } else {
                imageView2.yep_setImageOfAttachment(attachments[1], withSize: quarterRect.size)
            }

            imageView3.frame = quarterRect
            imageView3.center = CGPoint(x: quarterRect.width * 1.5, y: imageView3.center.y)

            if let thumbnailImage = attachments[2].thumbnailImage {
                imageView3.image = thumbnailImage

            } else {
                imageView3.yep_setImageOfAttachment(attachments[2], withSize: quarterRect.size)
            }

            imageView4.frame = quarterRect
            imageView4.center = CGPoint(x: quarterRect.width * 1.5, y: quarterRect.height * 1.5)

            if let thumbnailImage = attachments[3].thumbnailImage {
                imageView4.image = thumbnailImage

            } else {
                imageView4.yep_setImageOfAttachment(attachments[3], withSize: quarterRect.size)
            }

            addSubview(imageView1)
            addSubview(imageView2)
            addSubview(imageView3)
            addSubview(imageView4)

        case 0:
            imageView1.image = nil
            imageView2.image = nil
            imageView3.image = nil
            imageView4.image = nil

        default:
            break
        }
    }
}


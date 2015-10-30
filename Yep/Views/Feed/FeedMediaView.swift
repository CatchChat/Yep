//
//  FeedMediaView.swift
//  Yep
//
//  Created by nixzhu on 15/9/28.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Kingfisher

class FeedMediaView: UIView {

    lazy var imageView1: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFill
        view.clipsToBounds = true
        view.layer.minificationFilter = kCAFilterTrilinear
        return view
        }()

    lazy var imageView2: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFill
        view.clipsToBounds = true
        view.layer.minificationFilter = kCAFilterTrilinear
        return view
        }()

    lazy var imageView3: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFill
        view.clipsToBounds = true
        view.layer.minificationFilter = kCAFilterTrilinear
        return view
        }()

    lazy var imageView4: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFill
        view.clipsToBounds = true
        view.layer.minificationFilter = kCAFilterTrilinear
        return view
        }()
    
    func setImagesWithURLs(URLs: [NSURL]) {

        let fullRect = bounds
        let halfRect = CGRect(x: 0, y: 0, width: fullRect.width * 0.5, height: fullRect.height)
        let quarterRect = CGRect(x: 0, y: 0, width: fullRect.width * 0.5, height: fullRect.height * 0.5)

        hidden = (URLs.count == 0)
        
        imageView1.image = nil
        imageView2.image = nil
        imageView3.image = nil
        imageView4.image = nil

        switch URLs.count {

        case 1:
            imageView1.frame = fullRect
            imageView1.kf_setImageWithURL(URLs[0], placeholderImage: nil, optionsInfo: MediaOptionsInfos)

            addSubview(imageView1)

        case 2:
            imageView1.frame = halfRect
            imageView1.center = CGPoint(x: halfRect.width * 0.5, y: imageView1.center.y)
            imageView1.kf_setImageWithURL(URLs[0], placeholderImage: nil, optionsInfo: MediaOptionsInfos)

            imageView2.frame = halfRect
            imageView2.center = CGPoint(x: halfRect.width * 1.5, y: imageView2.center.y)
            imageView2.kf_setImageWithURL(URLs[1], placeholderImage: nil, optionsInfo: MediaOptionsInfos)

            addSubview(imageView1)
            addSubview(imageView2)

        case 3:
            imageView1.frame = quarterRect
            imageView1.kf_setImageWithURL(URLs[0], placeholderImage: nil, optionsInfo: MediaOptionsInfos)

            imageView2.frame = quarterRect
            imageView2.center = CGPoint(x: imageView2.center.x, y: quarterRect.height * 1.5)
            imageView2.kf_setImageWithURL(URLs[1], placeholderImage: nil, optionsInfo: MediaOptionsInfos)

            imageView3.frame = halfRect
            imageView3.center = CGPoint(x: halfRect.width * 1.5, y: imageView3.center.y)
            imageView3.kf_setImageWithURL(URLs[2], placeholderImage: nil, optionsInfo: MediaOptionsInfos)

            addSubview(imageView1)
            addSubview(imageView2)
            addSubview(imageView3)

        case 4..<Int.max:

            imageView1.frame = quarterRect
            imageView1.kf_setImageWithURL(URLs[0], placeholderImage: nil, optionsInfo: MediaOptionsInfos)

            imageView2.frame = quarterRect
            imageView2.center = CGPoint(x: imageView2.center.x, y: quarterRect.height * 1.5)
            imageView2.kf_setImageWithURL(URLs[1], placeholderImage: nil, optionsInfo: MediaOptionsInfos)

            imageView3.frame = quarterRect
            imageView3.center = CGPoint(x: quarterRect.width * 1.5, y: imageView3.center.y)
            imageView3.kf_setImageWithURL(URLs[2], placeholderImage: nil, optionsInfo: MediaOptionsInfos)

            imageView4.frame = quarterRect
            imageView4.center = CGPoint(x: quarterRect.width * 1.5, y: quarterRect.height * 1.5)
            imageView4.kf_setImageWithURL(URLs[3], placeholderImage: nil, optionsInfo: MediaOptionsInfos)

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


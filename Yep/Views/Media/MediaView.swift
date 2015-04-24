//
//  MediaView.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation

class MediaView: UIView {

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        return imageView
        }()

    lazy var videoPlayerLayer: AVPlayerLayer = {
        let player = AVPlayer()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        //playerLayer.backgroundColor = UIColor.darkGrayColor().CGColor
        return playerLayer
        }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        layer.addSublayer(videoPlayerLayer)
        videoPlayerLayer.frame = bounds
    }

    func makeUI() {

        addSubview(imageView)

        imageView.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "imageView": imageView,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[imageView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)
    }
}

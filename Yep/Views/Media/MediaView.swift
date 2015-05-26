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

    var image: UIImage? {
        didSet {
            if let image = image {
                imageView.image = image

                let size = image.size
//
                scrollView.frame = UIScreen.mainScreen().bounds
//                scrollView.contentSize = size
//
                imageView.frame = CGRect(origin: CGPointZero, size: size)

                setZoomParametersForSize(scrollView.bounds.size, imageSize: size)
                scrollView.zoomScale = scrollView.minimumZoomScale

                recenterImage()
            }
        }
    }

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        return scrollView
        }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFit
        return imageView
        }()

    lazy var videoPlayerLayer: AVPlayerLayer = {
        let player = AVPlayer()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        //playerLayer.backgroundColor = UIColor.darkGrayColor().CGColor
        return playerLayer
        }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        layer.addSublayer(videoPlayerLayer)

        println("videoPlayerLayer.frame: \(videoPlayerLayer.frame)")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        videoPlayerLayer.frame = UIScreen.mainScreen().bounds
    }

    func makeUI() {

        addSubview(scrollView)

        scrollView.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "view": self,
            "scrollView": scrollView,
            "imageView": imageView,
        ]

        let scrollViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[scrollView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let scrollViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[scrollView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(scrollViewConstraintsV)
        NSLayoutConstraint.activateConstraints(scrollViewConstraintsH)


        scrollView.addSubview(imageView)

        //imageView.setTranslatesAutoresizingMaskIntoConstraints(false)
//
//
//        let imageViewLeadingConstraint = NSLayoutConstraint(item: imageView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: 0)
//
//        let imageViewTrailingConstraint = NSLayoutConstraint(item: imageView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: 0)
//
//        let imageViewTopConstraint = NSLayoutConstraint(item: imageView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0)
//
//        let imageViewBottomConstraint = NSLayoutConstraint(item: imageView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0)
//
//         NSLayoutConstraint.activateConstraints([
//            imageViewLeadingConstraint,
//            imageViewTrailingConstraint,
//            imageViewTopConstraint,
//            imageViewBottomConstraint,
//            ])

//        let imageViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)
//
//        let imageViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[imageView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)
//
//        NSLayoutConstraint.activateConstraints(imageViewConstraintsV)
//        NSLayoutConstraint.activateConstraints(imageViewConstraintsH)
    }

    func setZoomParametersForSize(scrollViewSize: CGSize, imageSize: CGSize) {


        let widthScale = scrollViewSize.width / imageSize.width
        let heightScale = scrollViewSize.height / imageSize.height
        let minScale = min(widthScale, heightScale)

        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 3.0

        println("scrollView.minimumZoomScale: \(scrollView.minimumZoomScale)")
    }

    func recenterImage() {
        let scrollViewSize = scrollView.bounds.size
        let imageSize = imageView.frame.size

        let hSpace = imageSize.width < scrollViewSize.width ? (scrollViewSize.width - imageSize.width) * 0.5 : 0
        let vSpace = imageSize.height < scrollViewSize.height ? (scrollViewSize.height - imageSize.height) * 0.5 : 0


        println("hSpace: \(hSpace), vSpace: \(vSpace)")
        scrollView.contentInset = UIEdgeInsets(top: vSpace, left: hSpace, bottom: vSpace, right: hSpace)
    }
}

extension MediaView: UIScrollViewDelegate {

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(scrollView: UIScrollView) {
        recenterImage()
    }
}

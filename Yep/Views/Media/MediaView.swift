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

    func updateImageViewWithImage(image: UIImage) {

        scrollView.frame = UIScreen.mainScreen().bounds

        let size = image.size
        imageView.frame = CGRect(origin: CGPointZero, size: size)

        setZoomParametersForSize(scrollView.bounds.size, imageSize: size)
        scrollView.zoomScale = scrollView.minimumZoomScale

        //println("scrollView.zoomScale: \(scrollView.zoomScale)")
        //println("scrollView.minimumZoomScale: \(scrollView.minimumZoomScale)")
        //println("scrollView.maximumZoomScale: \(scrollView.maximumZoomScale)")

        recenterImage(image)

        //println("\n\n\n")
    }

    var image: UIImage? {
        didSet {
            if let image = image {
                imageView.image = image

                updateImageViewWithImage(image)
            }
        }
    }

    var coverImage: UIImage? {
        didSet {
            if let coverImage = coverImage {
                coverImageView.image = coverImage
                coverImageView.alpha = 1
                bringSubviewToFront(coverImageView)

                scrollView.alpha = 0
                videoPlayerLayer.opacity = 0
                
            } else {
                scrollView.alpha = 1
                videoPlayerLayer.opacity = 1

                coverImageView.alpha = 0
            }
        }
    }

    lazy var scrollView: UIScrollView = {

        let scrollView = UIScrollView()
        scrollView.delegate = self

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        return scrollView
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        return imageView
    }()

    lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        return imageView
    }()

    lazy var videoPlayerLayer: AVPlayerLayer = {
        let player = AVPlayer()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        return playerLayer
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        layer.addSublayer(videoPlayerLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        videoPlayerLayer.frame = UIScreen.mainScreen().bounds
    }

    func makeUI() {

        addSubview(scrollView)
        addSubview(coverImageView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.translatesAutoresizingMaskIntoConstraints = false

        let viewsDictionary = [
            "scrollView": scrollView,
            "imageView": imageView,
            "coverImageView": coverImageView,
        ]

        let scrollViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[scrollView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        let scrollViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[scrollView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(scrollViewConstraintsV)
        NSLayoutConstraint.activateConstraints(scrollViewConstraintsH)


        let coverImageViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[coverImageView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        let coverImageViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[coverImageView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(coverImageViewConstraintsV)
        NSLayoutConstraint.activateConstraints(coverImageViewConstraintsH)

        scrollView.addSubview(imageView)

        imageView.translatesAutoresizingMaskIntoConstraints = false

        let imageViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        let imageViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[imageView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(imageViewConstraintsV)
        NSLayoutConstraint.activateConstraints(imageViewConstraintsH)
    }

    func setZoomParametersForSize(scrollViewSize: CGSize, imageSize: CGSize) {

        //println("<----- scrollViewSize: \(scrollViewSize), imageSize: \(imageSize)")

        let widthScale = scrollViewSize.width / imageSize.width
        //let heightScale = scrollViewSize.height / imageSize.height
        //let minScale = min(widthScale, heightScale)
        let minScale = widthScale

        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = max(minScale, 3.0)
    }

    func recenterImage(image: UIImage) {

        let scrollViewSize = scrollView.bounds.size
        let imageSize = image.size
        let scale = scrollView.minimumZoomScale
        let scaledImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        let hSpace = scaledImageSize.width < scrollViewSize.width ? (scrollViewSize.width - scaledImageSize.width) * 0.5 : 0
        let vSpace = scaledImageSize.height < scrollViewSize.height ? (scrollViewSize.height - scaledImageSize.height) * 0.5 : 0
        //let viewHeight = UIScreen.mainScreen().bounds.height
        //let vSpace = scaledImageSize.height < scrollViewSize.height ? (scrollViewSize.height - scaledImageSize.height) * 0.5 : -(scaledImageSize.height - viewHeight * scale) * 0.5

        scrollView.contentInset = UIEdgeInsets(top: vSpace, left: hSpace, bottom: vSpace, right: hSpace)

//        println("------>>>>>>>>>>>>")
//        println("scrollView.zoomScale: \(scrollView.zoomScale)")
//        println("scrollViewSize: \(scrollViewSize), imageSize: \(imageSize), scaledImageSize: \(scaledImageSize)")
//        println("scrollView.contentInset: \(scrollView.contentInset)")
//        println("------>")

        if (scaledImageSize.height / scaledImageSize.width) > (scrollViewSize.height / scrollViewSize.width) {
            scrollView.setContentOffset(CGPointZero, animated: true)
        }
    }
}

extension MediaView: UIScrollViewDelegate {

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(scrollView: UIScrollView) {
        if let image = image {
            recenterImage(image)
        }
    }
}


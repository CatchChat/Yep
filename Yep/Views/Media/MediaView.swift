//
//  MediaView.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import AVFoundation

final class MediaView: UIView {

    var inTapZoom: Bool = false
    var isZoomIn: Bool = false
    var zoomScaleBeforeZoomIn: CGFloat?

    var tapToDismissAction: (() -> Void)? {
        didSet {
            inTapZoom = false
            isZoomIn = false
            zoomScaleBeforeZoomIn = nil
        }
    }

    func updateImageViewWithImage(_ image: UIImage) {

        scrollView.frame = UIScreen.main.bounds

        //let size = image.size
        let size = CGSize(width: floor(image.size.width), height: floor(image.size.height))
        //println("size: \(size)")

        imageView.frame = CGRect(origin: CGPoint.zero, size: size)

        setZoomParametersForSize(scrollView.bounds.size, imageSize: size)
        scrollView.zoomScale = scrollView.minimumZoomScale

        //println("scrollView.zoomScale: \(scrollView.zoomScale)")
        //println("scrollView.minimumZoomScale: \(scrollView.minimumZoomScale)")
        //println("scrollView.maximumZoomScale: \(scrollView.maximumZoomScale)")

        recenterImage(image)

        setNormalScrollViewScrollEnabled()
    }

    fileprivate func setNormalScrollViewScrollEnabled() {

        guard let image = image else {
            return
        }

        let isVerticalLong = (image.size.height / image.size.width) > (bounds.height / bounds.width)
        scrollView.isScrollEnabled = isVerticalLong
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
                bringSubview(toFront: coverImageView)

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
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
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

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(MediaView.doubleTapToZoom(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)

        let tap = UITapGestureRecognizer(target: self, action: #selector(MediaView.tapToDismiss(_:)))
        tap.require(toFail: doubleTap)
        addGestureRecognizer(tap)
    }

    @objc fileprivate func doubleTapToZoom(_ sender: UITapGestureRecognizer) {

        inTapZoom = true
        let zoomPoint = sender.location(in: self)

        if !isZoomIn {
            isZoomIn = true
            zoomScaleBeforeZoomIn = scrollView.zoomScale
            scrollView.yep_zoomToPoint(zoomPoint, withScale: scrollView.zoomScale * 2, animated: true)

            scrollView.isScrollEnabled = true

        } else {
            if let zoomScale = zoomScaleBeforeZoomIn {
                zoomScaleBeforeZoomIn = nil
                isZoomIn = false
                scrollView.yep_zoomToPoint(zoomPoint, withScale: zoomScale, animated: true)

                setNormalScrollViewScrollEnabled()
            }
        }
    }

    @objc fileprivate func tapToDismiss(_ sender: UITapGestureRecognizer) {

        if let zoomScale = zoomScaleBeforeZoomIn {
            let quickZoomDuration: TimeInterval = 0.35
            scrollView.yep_zoomToPoint(CGPoint.zero, withScale: zoomScale, animationDuration: quickZoomDuration, animationCurve: .easeInOut)
            delay(quickZoomDuration) { [weak self] in
                self?.tapToDismissAction?()
            }
            
        } else {
            tapToDismissAction?()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        videoPlayerLayer.frame = UIScreen.main.bounds
    }

    func makeUI() {

        addSubview(scrollView)
        addSubview(coverImageView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.translatesAutoresizingMaskIntoConstraints = false

        let viewsDictionary: [String: AnyObject] = [
            "scrollView": scrollView,
            "imageView": imageView,
            "coverImageView": coverImageView,
        ]

        let scrollViewConstraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: [], metrics: nil, views: viewsDictionary)

        let scrollViewConstraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: [], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activate(scrollViewConstraintsV)
        NSLayoutConstraint.activate(scrollViewConstraintsH)


        let coverImageViewConstraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[coverImageView]|", options: [], metrics: nil, views: viewsDictionary)

        let coverImageViewConstraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[coverImageView]|", options: [], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activate(coverImageViewConstraintsV)
        NSLayoutConstraint.activate(coverImageViewConstraintsH)

        scrollView.addSubview(imageView)

        imageView.translatesAutoresizingMaskIntoConstraints = false

        let imageViewConstraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageView]|", options: [], metrics: nil, views: viewsDictionary)

        let imageViewConstraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[imageView]|", options: [], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activate(imageViewConstraintsV)
        NSLayoutConstraint.activate(imageViewConstraintsH)
    }

    func setZoomParametersForSize(_ scrollViewSize: CGSize, imageSize: CGSize) {

        //println("<----- scrollViewSize: \(scrollViewSize), imageSize: \(imageSize)")

        let widthScale = scrollViewSize.width / imageSize.width
        //let heightScale = scrollViewSize.height / imageSize.height
        //let minScale = min(widthScale, heightScale)
        let minScale = widthScale

        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = max(minScale, 3.0)
    }

    func recenterImage(_ image: UIImage) {

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
            scrollView.setContentOffset(CGPoint.zero, animated: true)
        }
    }
}

extension MediaView: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if inTapZoom {
            inTapZoom = false
            return
        }

        if let image = image {
            recenterImage(image)

            zoomScaleBeforeZoomIn = scrollView.minimumZoomScale
            isZoomIn = !(scrollView.zoomScale == scrollView.minimumZoomScale)

            if isZoomIn {
                scrollView.isScrollEnabled = true

            } else {
                setNormalScrollViewScrollEnabled()
            }
        }
    }
}


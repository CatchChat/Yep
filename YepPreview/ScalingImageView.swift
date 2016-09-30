//
//  ScalingImageView.swift
//  Yep
//
//  Created by NIX on 16/6/16.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class ScalingImageView: UIScrollView {

    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    var image: UIImage? {
        didSet {
            if let image = image {
                setupWithImage(image)
            }
        }
    }

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.bouncesZoom = true
        self.decelerationRate = UIScrollViewDecelerationRateFast

        self.addSubview(imageView)

        self.clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup

    fileprivate func setupWithImage(_ image: UIImage) {

        updateWithImage(image)
    }

    fileprivate func updateWithImage(_ image: UIImage) {

        imageView.transform = CGAffineTransform.identity
        imageView.image = image
        imageView.frame = CGRect(origin: CGPoint.zero, size: image.size)

        contentSize = image.size

        updateZoomScaleWithImage(image)

        centerContent()
    }

    fileprivate func updateZoomScaleWithImage(_ image: UIImage) {

        let scrollViewFrame = bounds
        let imageSize = image.size

        let widthScale = scrollViewFrame.width / imageSize.width
        let heightScale = scrollViewFrame.height / imageSize.height

        let minScale = min(widthScale, heightScale)
        minimumZoomScale = minScale

        maximumZoomScale = minScale * 4
        if (imageSize.height / imageSize.width) > (scrollViewFrame.height / scrollViewFrame.width) {
            maximumZoomScale = max(maximumZoomScale, widthScale)
        }

        zoomScale = minimumZoomScale

        panGestureRecognizer.isEnabled = false
    }

    fileprivate func centerContent() {

        var horizontalInset: CGFloat = 0
        var verticalInset: CGFloat = 0

        if contentSize.width < bounds.width {
            horizontalInset = (bounds.width - contentSize.width) * 0.5
        }

        if contentSize.height < bounds.height {
            verticalInset = (bounds.height - contentSize.height) * 0.5
        }

        if let scale = window?.screen.scale, scale < 2 {
            horizontalInset = floor(horizontalInset)
            verticalInset = floor(verticalInset)
        }

        contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }
}


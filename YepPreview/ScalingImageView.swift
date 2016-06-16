//
//  ScalingImageView.swift
//  Yep
//
//  Created by NIX on 16/6/16.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class ScalingImageView: UIScrollView {

    enum ImageType {

        case image(UIImage)
        case imageData(NSData)
        case imageURL(NSURL)
        case imageFileURL(NSURL)

        var image: UIImage? {
            switch self {
            case .image(let image): return image
            case .imageData(let data): return UIImage(data: data)
            case .imageURL: return nil
            case .imageFileURL: return nil
            }
        }
    }

    private let imageType: ImageType

    private lazy var imageView = UIImageView()

    var image: UIImage? {
        didSet {
            if let image = image {
                setupWithImage(image)
            }
        }
    }

    // MARK: Init

    init(frame: CGRect, imageType: ImageType) {
        self.imageType = imageType
        super.init(frame: frame)

        self.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.bouncesZoom = true
        self.decelerationRate = UIScrollViewDecelerationRateFast

        self.addSubview(imageView)

        self.image = imageType.image
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup

    private func setupWithImage(image: UIImage) {

        updateWithImage(image)
    }

    private func updateWithImage(image: UIImage) {

        imageView.transform = CGAffineTransformIdentity
        imageView.image = image
        imageView.frame = CGRect(origin: CGPointZero, size: image.size)

        contentSize = image.size

        updateZoomScaleWithImage(image)

        centerContent()
    }

    private func updateZoomScaleWithImage(image: UIImage) {

        let scrollViewFrame = bounds
        let imageSize = image.size

        let widthScale = scrollViewFrame.width / imageSize.width
        let heightScale = scrollViewFrame.height / imageSize.height

        let minScale = min(widthScale, heightScale)
        minimumZoomScale = minScale
        maximumZoomScale = max(minScale, maximumZoomScale)
        zoomScale = minimumZoomScale

        panGestureRecognizer.enabled = false
    }

    private func centerContent() {

        var horizontalInset: CGFloat = 0
        var verticalInset: CGFloat = 0

        if contentSize.width < bounds.width {
            horizontalInset = (bounds.width - contentSize.width) * 0.5
        }

        if contentSize.height < bounds.height {
            verticalInset = (bounds.height - contentSize.height) * 0.5
        }

        if let scale = window?.screen.scale where scale < 2 {
            horizontalInset = floor(horizontalInset)
            verticalInset = floor(verticalInset)
        }

        contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }

}


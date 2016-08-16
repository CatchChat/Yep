//
//  PhotoViewController.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {

    let photo: Photo

    lazy var scalingImageView: ScalingImageView = {

        let view = ScalingImageView(frame: self.view.bounds)
        view.delegate = self
        return view
    }()

    private lazy var loadingView: UIActivityIndicatorView = {

        let view = UIActivityIndicatorView(activityIndicatorStyle: .White)
        view.hidesWhenStopped = true
        return view
    }()

    lazy var doubleTapGestureRecognizer: UITapGestureRecognizer = {

        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(PhotoViewController.didDoubleTap(_:)))
        tap.numberOfTapsRequired = 2
        return tap
    }()

    private lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {

        let longPress = UILongPressGestureRecognizer()
        longPress.addTarget(self, action: #selector(PhotoViewController.didLongPress(_:)))
        return longPress
    }()

    deinit {
        scalingImageView.delegate = nil

        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: Init

    init(photo: Photo) {
        self.photo = photo

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Life Circle

    override func viewDidLoad() {
        super.viewDidLoad()

        scalingImageView.frame = view.bounds
        scalingImageView.image = photo.image
        view.addSubview(scalingImageView)

        photo.updatedImage = { [weak self] image in
            self?.scalingImageView.image = image

            if image != nil {
                self?.loadingView.stopAnimating()
            }
        }

        if photo.image == nil {
            loadingView.startAnimating()
        }
        view.addSubview(loadingView)

        view.addGestureRecognizer(doubleTapGestureRecognizer)
        view.addGestureRecognizer(longPressGestureRecognizer)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        scalingImageView.frame = view.bounds

        loadingView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }

    // MARK: Selectors

    @objc private func didDoubleTap(sender: UITapGestureRecognizer) {

        let scrollViewSize = scalingImageView.bounds.size

        var pointInView = sender.locationInView(scalingImageView.imageView)

        var newZoomScale = min(scalingImageView.maximumZoomScale, scalingImageView.minimumZoomScale * 2)

        if let imageSize = scalingImageView.imageView.image?.size where (imageSize.height / imageSize.width) > (scrollViewSize.height / scrollViewSize.width) {

            pointInView.x = scalingImageView.imageView.bounds.width / 2

            let widthScale = scrollViewSize.width / imageSize.width
            newZoomScale = widthScale
        }

        let isZoomIn = (scalingImageView.zoomScale >= newZoomScale) || (abs(scalingImageView.zoomScale - newZoomScale) <= 0.01)

        if isZoomIn {
            newZoomScale = scalingImageView.minimumZoomScale
        }

        scalingImageView.directionalLockEnabled = !isZoomIn

        let width = scrollViewSize.width / newZoomScale
        let height = scrollViewSize.height / newZoomScale
        let originX = pointInView.x - (width / 2)
        let originY = pointInView.y - (height / 2)

        let rectToZoomTo = CGRect(x: originX, y: originY, width: width, height: height)

        scalingImageView.zoomToRect(rectToZoomTo, animated: true)
    }

    @objc private func didLongPress(sender: UILongPressGestureRecognizer) {

        // TODO: didLongPress
    }
}

// MARK: - UIScrollViewDelegate

extension PhotoViewController: UIScrollViewDelegate {

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {

        return scalingImageView.imageView
    }

    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {

        scrollView.panGestureRecognizer.enabled = true
    }

    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?) {

        if scrollView.zoomScale == scrollView.minimumZoomScale {
            scrollView.panGestureRecognizer.enabled = false
        }
    }
}


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

    struct Notification {

        static let photoImageUpdated = "PhotoViewControllerPhotoImageUpdatedNotification"
    }

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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(photoImageUpdated(_:)), name: Notification.photoImageUpdated, object: nil)

        scalingImageView.frame = view.bounds
        scalingImageView.imageType = photo.imageType
        view.addSubview(scalingImageView)

        if photo.imageType.image == nil {
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

    @objc private func photoImageUpdated(sender: NSNotification) {

        // TODO: check photo

        guard let photo = sender.object as? Photo else {
            return
        }

        scalingImageView.imageType = photo.imageType

        let needLoad = (scalingImageView.imageType?.image == nil)
        if needLoad {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
    }

    @objc private func didDoubleTap(sender: UITapGestureRecognizer) {

        let pointInView = sender.locationInView(scalingImageView.imageView)

        var newZoomScale = scalingImageView.maximumZoomScale
        if (scalingImageView.zoomScale >= scalingImageView.maximumZoomScale) || (abs(scalingImageView.zoomScale - scalingImageView.maximumZoomScale) <= 0.01) {
            newZoomScale = scalingImageView.minimumZoomScale
        }

        let scrollViewSize = scalingImageView.bounds.size

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


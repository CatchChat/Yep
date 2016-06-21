//
//  PhotosViewController.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

public class PhotosViewController: UIViewController {

    private weak var delegate: PhotosViewControllerDelegate?

    private let dataSource: PhotosViewControllerDataSource

    private lazy var transitionController = PhotoTransitonController()

    private lazy var pageViewController: UIPageViewController = {

        let vc = UIPageViewController(
            transitionStyle: .Scroll,
            navigationOrientation: .Horizontal,
            options: [UIPageViewControllerOptionInterPageSpacingKey: 16])

        vc.dataSource = self
        vc.delegate = self

        vc.view.backgroundColor = UIColor.clearColor()

        vc.view.addGestureRecognizer(self.panGestureRecognizer)
        vc.view.addGestureRecognizer(self.singleTapGestureRecognizer)

        return vc
    }()

    private var currentPhotoViewController: PhotoViewController? {
        return pageViewController.viewControllers?.first as? PhotoViewController
    }
    private var currentlyDisplayedPhoto: Photo? {
        return currentPhotoViewController?.photo
    }
    private var referenceViewForCurrentPhoto: UIView? {
        guard let photo = currentlyDisplayedPhoto else {
            return nil
        }
        
        return delegate?.photosViewController(self, referenceViewForPhoto: photo)
    }

    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {

        let pan = UIPanGestureRecognizer()
        pan.addTarget(self, action: #selector(PhotosViewController.didPan(_:)))
        return pan
    }()

    private lazy var singleTapGestureRecognizer: UITapGestureRecognizer = {

        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(PhotosViewController.didSingleTap(_:)))
        return tap
    }()

    private var boundsCenterPoint: CGPoint {
        return CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }

    deinit {
        pageViewController.dataSource = nil
        pageViewController.delegate = nil
    }

    // MARK: Init

    public init(photos: [Photo], initialPhoto: Photo, delegate: PhotosViewControllerDelegate? = nil) {

        self.dataSource = PhotosDataSource(photos: photos)
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        self.modalPresentationStyle = .Custom
        self.transitioningDelegate = transitionController
        self.modalPresentationCapturesStatusBarAppearance = true

        //overlayView...        

        print("initialPhoto.imageType.image: \(initialPhoto.imageType.image)")

        let initialPhotoViewController: PhotoViewController
        if dataSource.containsPhoto(initialPhoto) {
            initialPhotoViewController = newPhotoViewControllerForPhoto(initialPhoto)
        } else {
            guard let firstPhoto = dataSource.photoAtIndex(0) else {
                fatalError("Empty dataSource")
            }
            initialPhotoViewController = newPhotoViewControllerForPhoto(firstPhoto)
        }
        setCurrentlyDisplayedViewController(initialPhotoViewController, animated: false)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func newPhotoViewControllerForPhoto(photo: Photo) -> PhotoViewController {

        let photoViewController = PhotoViewController(photo: photo)

        //photoViewController.delegate = self

        singleTapGestureRecognizer.requireGestureRecognizerToFail(photoViewController.doubleTapGestureRecognizer)

        // ...

        return photoViewController
    }

    private func setCurrentlyDisplayedViewController(vc: PhotoViewController, animated: Bool) {

        pageViewController.setViewControllers([vc], direction: .Forward, animated: animated, completion: nil)
    }

    // MARK: Life Circle

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.tintColor = UIColor.whiteColor()
        view.backgroundColor = UIColor.blackColor()

        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMoveToParentViewController(self)

        // TODO: add overlay

        transitionController.setStartingView(referenceViewForCurrentPhoto)

        if currentlyDisplayedPhoto?.imageType.image != nil {
            transitionController.setEndingView(currentPhotoViewController?.scalingImageView.imageView)
        }
    }

    // MARK: Selectors

    @objc private func didPan(sender: UIPanGestureRecognizer) {

        switch sender.state {

        case .Began:
            transitionController.forcesNonInteractiveDismissal = false
            dismissViewControllerAnimated(true, userInitiated: true, completion: nil)

        default:
            transitionController.forcesNonInteractiveDismissal = true
            transitionController.didPanWithPanGestureRecognizer(sender, viewToPan: pageViewController.view, anchorPoint: boundsCenterPoint)
        }
    }

    @objc private func didSingleTap(sender: UITapGestureRecognizer) {

        // TODO: didSingleTap
    }

    // MARK: Dismissal

    private func dismissViewControllerAnimated(animated: Bool, userInitiated: Bool, completion: (() -> Void)? = nil) {

        if presentedViewController != nil {
            super.dismissViewControllerAnimated(animated, completion: completion)
        }

        let startingView = currentPhotoViewController?.scalingImageView.imageView
        transitionController.setStartingView(startingView)
        transitionController.setEndingView(referenceViewForCurrentPhoto)

        // TODO
        super.dismissViewControllerAnimated(animated) {
            completion?()
        }
    }
}

extension PhotosViewController: UIPageViewControllerDataSource {

    public func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {

        guard let viewController = viewController as? PhotoViewController else {
            return nil
        }

        let photoIndex = dataSource.indexOfPhoto(viewController.photo)

        guard let previousPhoto = dataSource.photoAtIndex(photoIndex - 1) else {
            return nil
        }

        return newPhotoViewControllerForPhoto(previousPhoto)
    }

    public func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {

        guard let viewController = viewController as? PhotoViewController else {
            return nil
        }

        let photoIndex = dataSource.indexOfPhoto(viewController.photo)

        guard let previousPhoto = dataSource.photoAtIndex(photoIndex + 1) else {
            return nil
        }

        return newPhotoViewControllerForPhoto(previousPhoto)
    }
}

extension PhotosViewController: UIPageViewControllerDelegate {

    public func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

        // TODO
    }
}



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

    private var overlayActionViewWasHiddenBeforeTransition = false
    private lazy var overlayActionView: OverlayActionView = {

        let view = OverlayActionView()
        view.backgroundColor = UIColor.clearColor()

        view.shareAction = { [weak self] in
            guard let image = self?.currentlyDisplayedPhoto?.image else {
                return
            }

            let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            self?.presentViewController(activityViewController, animated: true, completion: nil)
        }

        return view
    }()

    private lazy var pageViewController: UIPageViewController = {

        let vc = UIPageViewController(
            transitionStyle: .Scroll,
            navigationOrientation: .Horizontal,
            options: [UIPageViewControllerOptionInterPageSpacingKey: 30])

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

    private func setOverlayActionViewHidden(hidden: Bool, animated: Bool) {

        guard overlayActionView.hidden != hidden else {
            return
        }

        if animated {
            overlayActionView.hidden = false
            overlayActionView.alpha = hidden ? 1 : 0

            UIView.animateWithDuration(0.25, delay: 0, options: [.CurveEaseIn, .CurveEaseOut, .AllowAnimatedContent, .AllowUserInteraction], animations: { [weak self] in
                self?.overlayActionView.alpha = hidden ? 0 : 1

            }, completion: { [weak self] finished in
                self?.overlayActionView.hidden = hidden
            })

        } else {
            overlayActionView.hidden = hidden
        }
    }

    private func newPhotoViewControllerForPhoto(photo: Photo) -> PhotoViewController {

        let photoViewController = PhotoViewController(photo: photo)

        singleTapGestureRecognizer.requireGestureRecognizerToFail(photoViewController.doubleTapGestureRecognizer)

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

        do {
            addChildViewController(pageViewController)
            view.addSubview(pageViewController.view)
            pageViewController.didMoveToParentViewController(self)
        }

        do {
            view.addSubview(overlayActionView)
            overlayActionView.translatesAutoresizingMaskIntoConstraints = false

            let leading = overlayActionView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor, constant: 0)
            let trailing = overlayActionView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor, constant: 0)
            let bottom = overlayActionView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: 0)
            let height = overlayActionView.heightAnchor.constraintEqualToConstant(80)

            NSLayoutConstraint.activateConstraints([leading, trailing, bottom, height])

            setOverlayActionViewHidden(true, animated: false)
        }

        do {
            transitionController.setStartingView(referenceViewForCurrentPhoto)

            if currentlyDisplayedPhoto?.image != nil {
                transitionController.setEndingView(currentPhotoViewController?.scalingImageView.imageView)
            }
        }
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.15 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { [weak self] in
            self?.statusBarHidden = true
        }
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if !overlayActionViewWasHiddenBeforeTransition {
            setOverlayActionViewHidden(false, animated: true)
        }
    }

    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        statusBarHidden = false
    }

    // MARK: Status Bar

    var statusBarHidden: Bool = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    public override func prefersStatusBarHidden() -> Bool {
        return statusBarHidden
    }

    public override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Fade
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

        //setOverlayActionViewHidden(!overlayActionView.hidden, animated: true)
        dismissViewControllerAnimated(true, userInitiated: true, completion: nil)
    }

    // MARK: Dismissal

    private func dismissViewControllerAnimated(animated: Bool, userInitiated: Bool, completion: (() -> Void)? = nil) {

        if presentedViewController != nil {
            dismissViewControllerAnimated(animated, completion: completion)
            return
        }

        let startingView = currentPhotoViewController?.scalingImageView.imageView
        transitionController.setStartingView(startingView)
        transitionController.setEndingView(referenceViewForCurrentPhoto)

        let overlayActionViewWasHidden = overlayActionView.hidden
        self.overlayActionViewWasHiddenBeforeTransition = overlayActionViewWasHidden
        setOverlayActionViewHidden(true, animated: animated)

        delegate?.photosViewControllerWillDismiss(self)

        dismissViewControllerAnimated(animated) { [weak self] in

            let isStillOnscreen = (self?.view.window != nil)

            if (isStillOnscreen && !overlayActionViewWasHidden) {
                self?.setOverlayActionViewHidden(false, animated: true)
            }

            if !isStillOnscreen {
                if let vc = self {
                    vc.delegate?.photosViewControllerDidDismiss(vc)
                }
            }

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

        guard completed else {
            return
        }

        if let photo = currentlyDisplayedPhoto {
            let index = dataSource.indexOfPhoto(photo)
            delegate?.photosViewController(self, didNavigateToPhoto: photo, atIndex: index)
        }
    }
}


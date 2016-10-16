//
//  PhotosViewController.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

open class PhotosViewController: UIViewController {

    fileprivate weak var delegate: PhotosViewControllerDelegate?

    fileprivate let dataSource: PhotosViewControllerDataSource

    fileprivate lazy var transitionController = PhotoTransitonController()

    fileprivate var overlayActionViewWasHiddenBeforeTransition = false
    fileprivate lazy var overlayActionView: OverlayActionView = {

        let view = OverlayActionView()
        view.backgroundColor = UIColor.clear

        view.shareAction = { [weak self] in
            guard let strongSelf = self else { return }
            guard let image = strongSelf.currentlyDisplayedPhoto?.image else { return }
            Config.shareImageAction?(image, strongSelf)
        }

        return view
    }()

    fileprivate lazy var pageViewController: UIPageViewController = {

        let vc = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [UIPageViewControllerOptionInterPageSpacingKey: 30])

        vc.dataSource = self
        vc.delegate = self

        vc.view.backgroundColor = UIColor.clear

        vc.view.addGestureRecognizer(self.panGestureRecognizer)
        vc.view.addGestureRecognizer(self.singleTapGestureRecognizer)

        return vc
    }()

    fileprivate var currentPhotoViewController: PhotoViewController? {

        return pageViewController.viewControllers?.first as? PhotoViewController
    }
    fileprivate var currentlyDisplayedPhoto: Photo? {

        return currentPhotoViewController?.photo
    }
    fileprivate var referenceForCurrentPhoto: Reference? {

        guard let photo = currentlyDisplayedPhoto else {
            return nil
        }
        
        return delegate?.photosViewController(self, referenceForPhoto: photo)
    }

    fileprivate lazy var panGestureRecognizer: UIPanGestureRecognizer = {

        let pan = UIPanGestureRecognizer()
        pan.addTarget(self, action: #selector(PhotosViewController.didPan(_:)))
        return pan
    }()

    fileprivate lazy var singleTapGestureRecognizer: UITapGestureRecognizer = {

        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(PhotosViewController.didSingleTap(_:)))
        return tap
    }()

    fileprivate var boundsCenterPoint: CGPoint {

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

        self.modalPresentationStyle = .custom
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

    fileprivate func setOverlayActionViewHidden(_ hidden: Bool, animated: Bool) {

        guard overlayActionView.isHidden != hidden else {
            return
        }

        if animated {
            overlayActionView.isHidden = false
            overlayActionView.alpha = hidden ? 1 : 0

            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn, .curveEaseOut, .allowAnimatedContent, .allowUserInteraction], animations: { [weak self] in
                self?.overlayActionView.alpha = hidden ? 0 : 1

            }, completion: { [weak self] finished in
                self?.overlayActionView.isHidden = hidden
            })

        } else {
            overlayActionView.isHidden = hidden
        }
    }

    fileprivate func newPhotoViewControllerForPhoto(_ photo: Photo) -> PhotoViewController {

        let photoViewController = PhotoViewController(photo: photo)

        singleTapGestureRecognizer.require(toFail: photoViewController.doubleTapGestureRecognizer)

        return photoViewController
    }

    fileprivate func setCurrentlyDisplayedViewController(_ vc: PhotoViewController, animated: Bool) {

        pageViewController.setViewControllers([vc], direction: .forward, animated: animated, completion: nil)
    }

    // MARK: Life Circle

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.tintColor = UIColor.white
        view.backgroundColor = UIColor.black

        do {
            addChildViewController(pageViewController)
            view.addSubview(pageViewController.view)
            pageViewController.didMove(toParentViewController: self)
        }

        do {
            view.addSubview(overlayActionView)
            overlayActionView.translatesAutoresizingMaskIntoConstraints = false

            let leading = overlayActionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0)
            let trailing = overlayActionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
            let bottom = overlayActionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
            let height = overlayActionView.heightAnchor.constraint(equalToConstant: 80)

            NSLayoutConstraint.activate([leading, trailing, bottom, height])

            setOverlayActionViewHidden(true, animated: false)
        }

        do {
            transitionController.setStartingReference(referenceForCurrentPhoto)

            if currentlyDisplayedPhoto?.image != nil {
                var endingReference: Reference?
                if let imageView = currentPhotoViewController?.scalingImageView.imageView {
                    endingReference = Reference(view: imageView, image: imageView.image)
                }
                transitionController.setEndingReference(endingReference)
            }
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.15 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { [weak self] in
            self?.statusBarHidden = true
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !overlayActionViewWasHiddenBeforeTransition {
            setOverlayActionViewHidden(false, animated: true)
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        statusBarHidden = false
    }

    // MARK: Status Bar

    var statusBarHidden: Bool = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    open override var prefersStatusBarHidden : Bool {
        return statusBarHidden
    }

    open override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return .fade
    }

    // MARK: Selectors

    @objc fileprivate func didPan(_ sender: UIPanGestureRecognizer) {

        switch sender.state {

        case .began:
            transitionController.forcesNonInteractiveDismissal = false
            dismissViewControllerAnimated(true, userInitiated: true, completion: nil)

        default:
            transitionController.forcesNonInteractiveDismissal = true
            transitionController.didPanWithPanGestureRecognizer(sender, viewToPan: pageViewController.view, anchorPoint: boundsCenterPoint)
        }
    }

    @objc fileprivate func didSingleTap(_ sender: UITapGestureRecognizer) {

        //setOverlayActionViewHidden(!overlayActionView.hidden, animated: true)
        dismissViewControllerAnimated(true, userInitiated: true, completion: nil)
    }

    // MARK: Dismissal

    fileprivate func dismissViewControllerAnimated(_ animated: Bool, userInitiated: Bool, completion: (() -> Void)? = nil) {

        if presentedViewController != nil {
            dismiss(animated: animated, completion: completion)
            return
        }

        var startingReference: Reference?
        if let imageView = currentPhotoViewController?.scalingImageView.imageView {
            startingReference = Reference(view: imageView, image: imageView.image)
        }
        transitionController.setStartingReference(startingReference)
        transitionController.setEndingReference(referenceForCurrentPhoto)

        let overlayActionViewWasHidden = overlayActionView.isHidden
        self.overlayActionViewWasHiddenBeforeTransition = overlayActionViewWasHidden
        setOverlayActionViewHidden(true, animated: animated)

        delegate?.photosViewControllerWillDismiss(self)

        dismiss(animated: animated) { [weak self] in

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

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

        guard let viewController = viewController as? PhotoViewController else {
            return nil
        }

        let photoIndex = dataSource.indexOfPhoto(viewController.photo)

        guard let previousPhoto = dataSource.photoAtIndex(photoIndex - 1) else {
            return nil
        }

        return newPhotoViewControllerForPhoto(previousPhoto)
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {

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

    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

        guard completed else {
            return
        }

        if let photo = currentlyDisplayedPhoto {
            let index = dataSource.indexOfPhoto(photo)
            delegate?.photosViewController(self, didNavigateToPhoto: photo, atIndex: index)
        }
    }
}


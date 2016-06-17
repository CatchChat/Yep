//
//  PhotosViewController.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController {

    let dataSource: PhotosViewControllerDataSource

    private lazy var pageViewController: UIPageViewController = {
        let vc = UIPageViewController(
            transitionStyle: .Scroll,
            navigationOrientation: .Horizontal,
            options: [UIPageViewControllerOptionInterPageSpacingKey: 16])
        vc.dataSource = self
        vc.delegate = self
        return vc
    }()

    private var currentPhotoViewController: PhotoViewController?

    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer()
        pan.addTarget(self, action: #selector(didPan(_:)))
        return pan
    }()

    private lazy var singleTapGestureRecognizer: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(didSingleTap(_:)))
        return tap
    }()

    deinit {
        pageViewController.dataSource = nil
        pageViewController.delegate = nil
    }

    // MARK: Init

    init(photos: [Photo], initialPhoto: Photo) {

        self.dataSource = PhotosDataSource(photos: photos)
        
        // dataSource
        // delegate
        // transitionController

        super.init(nibName: nil, bundle: nil)

        self.modalPresentationStyle = .Custom
        //self.transitioningDelegate = transitionController
        self.modalPresentationCapturesStatusBarAppearance = true

        //overlayView...        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Life Circle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: Selectors

    @objc private func didPan(sender: UIPanGestureRecognizer) {

    }

    @objc private func didSingleTap(sender: UITapGestureRecognizer) {

    }
}

extension PhotosViewController: UIPageViewControllerDataSource {

    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {

        // TODO
        return nil
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        // TODO
        return nil
    }
}

extension PhotosViewController: UIPageViewControllerDelegate {

    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

        // TODO
    }
}



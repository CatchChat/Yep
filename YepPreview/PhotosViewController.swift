//
//  PhotosViewController.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController {

    private lazy var pageViewController = UIPageViewController()

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


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

    private lazy var scalingImageView: ScalingImageView = {
        let view = ScalingImageView(frame: self.view.bounds, imageType: nil)
        return view
    }()

    private lazy var doubleTapGestureRecognizer: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(doubleTapped(_:)))
        tap.numberOfTapsRequired = 2
        return tap
    }()

    private lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let longPress = UILongPressGestureRecognizer()
        longPress.addTarget(self, action: #selector(longPressed(_:)))
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

        scalingImageView.imageType = photo.imageType
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Life Circle

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(photoImageUpdated(_:)), name: Notification.photoImageUpdated, object: nil)

        scalingImageView.frame = view.bounds
        view.addSubview(scalingImageView)

        view.addGestureRecognizer(doubleTapGestureRecognizer)
        view.addGestureRecognizer(longPressGestureRecognizer)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        scalingImageView.frame = view.bounds
    }

    // MARK: Selectors

    @objc private func photoImageUpdated(sender: NSNotification) {
        
    }

    @objc private func doubleTapped(sender: UITapGestureRecognizer) {

    }

    @objc private func longPressed(sender: UILongPressGestureRecognizer) {

    }
}


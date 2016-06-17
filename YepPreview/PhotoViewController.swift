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

    private var scalingImageView: ScalingImageView?

    deinit {
        scalingImageView?.delegate = nil

        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    init(photo: Photo) {
        self.photo = photo

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}


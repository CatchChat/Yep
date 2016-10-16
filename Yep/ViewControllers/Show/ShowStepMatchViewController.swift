//
//  ShowStepMatchViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class ShowStepMatchViewController: ShowStepViewController {

    @IBOutlet fileprivate weak var camera: UIImageView!
    @IBOutlet fileprivate weak var pen: UIImageView!
    @IBOutlet fileprivate weak var book: UIImageView!
    @IBOutlet fileprivate weak var controller: UIImageView!
    @IBOutlet fileprivate weak var keyboard: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = String.trans_titleMatch
        subTitleLabel.text = String.trans_showMatchFriendsWithSkills
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        animate(camera, offset: 10, duration: 4)
        animate(pen, offset: 5, duration: 5)
        animate(book, offset: 10, duration: 3)
        animate(controller, offset: 15, duration: 2)
        animate(keyboard, offset: 20, duration: 4)
    }
}


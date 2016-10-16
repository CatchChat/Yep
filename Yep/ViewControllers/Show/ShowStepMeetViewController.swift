//
//  ShowStepMeetViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class ShowStepMeetViewController: ShowStepViewController {

    @IBOutlet fileprivate weak var yellowTriangle: UIImageView!
    @IBOutlet fileprivate weak var greenTriangle: UIImageView!
    @IBOutlet fileprivate weak var purpleTriangle: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = String.trans_showMeet
        subTitleLabel.text = String.trans_subtitleBuildWorldTogether
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        animate(yellowTriangle, offset: 3, duration: 3)
        animate(greenTriangle, offset: 7, duration: 2)
        animate(purpleTriangle, offset: 5, duration: 2)
    }
}

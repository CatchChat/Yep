//
//  ShowStepMeetViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ShowStepMeetViewController: ShowStepViewController {

    @IBOutlet private weak var yellowTriangle: UIImageView!
    @IBOutlet private weak var greenTriangle: UIImageView!
    @IBOutlet private weak var purpleTriangle: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = NSLocalizedString("Meet", comment: "")
        subTitleLabel.text = NSLocalizedString("Build world together", comment: "")
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        animate(yellowTriangle, offset: 3, duration: 3)
        animate(greenTriangle, offset: 7, duration: 2)
        animate(purpleTriangle, offset: 5, duration: 2)
    }
}

//
//  GeniusInterviewActionView.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class GeniusInterviewActionView: UIView {

    lazy var sayHiButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFontOfSize(14)
        button.setTitle(NSLocalizedString("Say Hi", comment: ""), forState: .Normal)
        button.backgroundColor = UIColor.yepTintColor()
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(GeniusInterviewActionView.sayHi(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        return button
    }()

    @objc private func sayHi(sender: UIButton) {
        println("Say Hi")
    }
}


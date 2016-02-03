//
//  NavigationTitleLabel.swift
//  Yep
//
//  Created by NIX on 15/6/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class NavigationTitleLabel: UILabel {

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(title: String) {
        super.init(frame: CGRect(x: 0, y: 0, width: 150, height: 30))

        text = title

        textAlignment = .Center
        font = UIFont.navigationBarTitleFont() // make sure it's the same as system use
        textColor = UIColor.yepNavgationBarTitleColor()

        sizeToFit()
    }
}


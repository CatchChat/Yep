//
//  SwipeUpPromptView.swift
//  Yep
//
//  Created by NIX on 16/9/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class SwipeUpPromptView: UIView {

    lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_swipeUp
        return imageView
    }()

    lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.redColor()
        label.font = UIFont.systemFontOfSize(15)
        return label
    }()
}


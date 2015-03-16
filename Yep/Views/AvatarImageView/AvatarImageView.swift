//
//  AvatarImageView.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class AvatarImageView: UIImageView {
    let maskLayer = CAShapeLayer()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        layer.mask = maskLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        maskLayer.path = UIBezierPath(ovalInRect: bounds).CGPath
    }
}

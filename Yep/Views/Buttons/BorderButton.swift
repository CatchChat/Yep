//
//  BorderButton.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
class BorderButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = 6
    @IBInspectable var borderColor: UIColor = UIColor.yepTintColor()
    @IBInspectable var borderWidth: CGFloat = 1

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        layer.cornerRadius = cornerRadius
        layer.borderColor = borderColor.CGColor
        layer.borderWidth = borderWidth
    }

}

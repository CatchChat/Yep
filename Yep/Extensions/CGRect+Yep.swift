//
//  CGRect+Yep.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension CGRect {

    func largestCenteredSquare() -> CGRect {

        let width = self.size.width
        let height = self.size.height
        let widthBigger = width / height > 1.0
        let size = min(width, height)

        let square = CGRect(x: widthBigger ? (width - height) * 0.5 : 0.0, y: widthBigger ? 0.0 : (height - width) * 0.5, width: size, height: size)

        return square
    }
}


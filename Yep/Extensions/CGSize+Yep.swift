//
//  CGSize+Yep.swift
//  Yep
//
//  Created by nixzhu on 16/1/19.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

extension CGSize {

    func yep_ensureMinWidthOrHeight(value: CGFloat) -> CGSize {
        if width > height {

            if height < value {
                let ratio = height / value
                return CGSize(width: floor(width / ratio), height: value)
            }

        } else {
            if width < value {
                let ratio = width / value
                return CGSize(width: value, height: floor(height / ratio))
            }
        }

        return self
    }
}


//
//  UIDevice+Yep.swift
//  Yep
//
//  Created by NIX on 15/5/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension UIDevice {

    enum ScreenWidthModel {
        case Classic
        case Bigger
        case BiggerPlus
    }

    static let screenWidthModel: ScreenWidthModel = {

        let screen = UIScreen.mainScreen()
        let nativeWidth = screen.nativeBounds.size.width

        if nativeWidth == 320 * 2 {
            return .Classic

        } else if nativeWidth == 375 * 2 {
            return .Bigger

        } else if nativeWidth == 414 * 3 {
            return .BiggerPlus
        }

        return .Bigger // Default
        }()
}

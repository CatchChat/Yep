//
//  UIDevice+Yep.swift
//  Yep
//
//  Created by NIX on 15/5/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension UIDevice {

    enum ScreenWidthModel: Int {
        case Classic = 0
        case Bigger
        case BiggerPlus

        static var caseCount: Int {
            var max: Int = 0
            while let _ = self(rawValue: ++max) {}
            return max
        }
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

    class func pickMarginIn(margins: [CGFloat]) -> CGFloat {

        if margins.count < ScreenWidthModel.caseCount {
            println("Warning: NOT enough margins")

            if margins.count > 0 {
                return margins[0]
            } else {
                return 0
            }
        }

        return margins[screenWidthModel.rawValue]
    }
}

//
//  UIDevice+Yep.swift
//  Yep
//
//  Created by NIX on 15/5/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension UIDevice {

    // 只考虑宽度的模型

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

    class func matchWidthFrom(classic: CGFloat, _ bigger: CGFloat, _ biggerPlus: CGFloat) -> CGFloat {
        switch screenWidthModel {
        case .Classic:
            return classic
        case .Bigger:
            return bigger
        case .BiggerPlus:
            return biggerPlus
        }
    }


    // 整个屏幕的模型

    enum ScreenModel {
        case Inch35
        case Inch4
        case Bigger
        case BiggerPlus
    }

    static let screenModel: ScreenModel = {

        let screen = UIScreen.mainScreen()
        let nativeWidth = screen.nativeBounds.size.width

        if nativeWidth == 320 * 2 {
            let nativeHeight = screen.nativeBounds.size.height
            return nativeHeight > (480 * 2) ? .Inch4 : .Inch35

        } else if nativeWidth == 375 * 2 {
            return .Bigger

        } else if nativeWidth == 414 * 3 {
            return .BiggerPlus
        }

        return .Bigger // Default
        }()

    class func matchFrom(inch35: CGFloat, _ inch4: CGFloat, _ bigger: CGFloat, _ biggerPlus: CGFloat) -> CGFloat {
        switch screenModel {
        case .Inch35:
            return inch35
        case .Inch4:
            return inch4
        case .Bigger:
            return bigger
        case .BiggerPlus:
            return biggerPlus
        }
    }
}

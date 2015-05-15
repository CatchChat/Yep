//
//  UIDevice+Yep.swift
//  Yep
//
//  Created by NIX on 15/5/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension UIDevice {

    enum ScreenModel {
        case Classic
        case Bigger
        case BiggerPlus
    }

    static let screenModel: ScreenModel = {

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

    class func matchMarginFrom(classic: CGFloat, _ bigger: CGFloat, _ biggerPlus: CGFloat) -> CGFloat {
        switch screenModel {
        case .Classic:
            return classic
        case .Bigger:
            return bigger
        case .BiggerPlus:
            return biggerPlus
        }
    }
}

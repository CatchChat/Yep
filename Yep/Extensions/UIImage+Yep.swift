//
//  UIImage+Yep.swift
//  Yep
//
//  Created by NIX on 16/8/10.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension UIImage {

    static var yep_iconLocationCheckmark: UIImage {
        return UIImage(named: "icon_location_checkmark")!
    }

    static func yep_badgeWithName(name: String) -> UIImage {
        return UIImage(named: "badge_" + name)!
    }
}


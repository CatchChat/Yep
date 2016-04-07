//
//  UISearchBar+Yep.swift
//  Yep
//
//  Created by NIX on 16/4/7.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension UISearchBar {

    func yep_enableCancelButton() {

        for subview in self.subviews {
            for subview in subview.subviews {
                (subview as? UIControl)?.enabled = true
            }
        }
    }
}

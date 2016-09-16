//
//  CanScrollsToTop.swift
//  Yep
//
//  Created by NIX on 16/9/12.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol CanScrollsToTop: class {

    var scrollView: UIScrollView? { get }

    func scrollsToTopIfNeed(otherwise otherwise: (() -> Void)?)
}

extension CanScrollsToTop {

    func scrollsToTopIfNeed(otherwise otherwise: (() -> Void)? = nil) {

        guard let scrollView = scrollView else { return }

        if !scrollView.yep_isAtTop {
            scrollView.yep_scrollsToTop()

        } else {
            otherwise?()
        }
    }
}

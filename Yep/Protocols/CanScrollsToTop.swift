//
//  CanScrollsToTop.swift
//  Yep
//
//  Created by NIX on 16/9/12.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol CanScrollsToTop: class {

    var scrollView: UIScrollView { get }
}

extension CanScrollsToTop {

    func scrollsToTopIfNeed {
        if !scrollView.yep_isAtTop {
            scrollView.yep_scrollsToTop()
        }
    }
}

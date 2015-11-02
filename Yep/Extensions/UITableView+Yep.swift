//
//  UITableView+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/11/2.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension UITableView {

    var yep_isAtTop: Bool {
        println("contentOffset.y: \(contentOffset.y), -contentInset.top: \(-contentInset.top)")
        return contentOffset.y == -contentInset.top
    }
    
    func yep_scrollsToTop() {

        let topPoint = CGPoint(x: 0, y: -contentInset.top)
        setContentOffset(topPoint, animated: true)
    }
}


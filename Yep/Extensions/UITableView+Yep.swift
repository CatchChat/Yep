//
//  UITableView+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/11/2.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension UITableView {
    
    func tryScrollsToTop() {

        println("tryScrollsToTop: \(numberOfSections), \(numberOfRowsInSection(0))")

//        if numberOfSections > 0 && numberOfRowsInSection(0) > 0 {
//            let topIndexPath = NSIndexPath(forRow: 0, inSection: 0)
//            scrollToRowAtIndexPath(topIndexPath, atScrollPosition: .Top, animated: true)
//        }

        let topPoint = CGPoint(x: 0, y: -contentInset.top)
        setContentOffset(topPoint, animated: true)
    }
}


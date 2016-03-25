//
//  ReplaceSegue.swift
//  Yep
//
//  Created by ChaiYixiao on 3/24/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit

class ReplaceSegue: UIStoryboardSegue {

    override func perform() {
         let fromView = sourceViewController.view
        let toView = destinationViewController.view
        toView.backgroundColor = UIColor.redColor()
        let detailView = (UIApplication.sharedApplication().delegate as! AppDelegate).detail.view
        print(fromView, toView, detailView)
        detailView.insertSubview(toView, aboveSubview: fromView)
//
    }
}

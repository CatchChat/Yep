//
//  SegueViewController.swift
//  Yep
//
//  Created by nixzhu on 16/1/4.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class SegueViewController: UIViewController {

    override func performSegueWithIdentifier(identifier: String, sender: AnyObject?) {

        if let navigationController = navigationController {
            guard navigationController.topViewController == self else {
                return
            }
        }

        super.performSegueWithIdentifier(identifier, sender: sender)
    }
}


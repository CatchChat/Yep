//
//  BaseViewController.swift
//  Yep
//
//  Created by kevinzhow on 15/5/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class BaseViewController: SegueViewController {
    
    var animatedOnNavigationBar = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let navigationController = navigationController else {
            return
        }

        navigationController.navigationBar.backgroundColor = nil
        navigationController.navigationBar.isTranslucent = true
        navigationController.navigationBar.shadowImage = nil
        navigationController.navigationBar.barStyle = UIBarStyle.default
        navigationController.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)

        let textAttributes: [String: AnyObject] = [
            NSForegroundColorAttributeName: UIColor.yepNavgationBarTitleColor(),
            NSFontAttributeName: UIFont.navigationBarTitleFont()
        ]

        navigationController.navigationBar.titleTextAttributes = textAttributes
        navigationController.navigationBar.tintColor = nil

        if navigationController.isNavigationBarHidden {
            navigationController.setNavigationBarHidden(false, animated: animatedOnNavigationBar)
        }
    }
}


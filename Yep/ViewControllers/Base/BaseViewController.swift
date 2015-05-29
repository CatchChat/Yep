//
//  BaseViewController.swift
//  Yep
//
//  Created by kevinzhow on 15/5/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    
    var animatedOnNavigationBar = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navigationController = navigationController {
            
            navigationController.navigationBar.backgroundColor = nil
            navigationController.navigationBar.translucent = true
            navigationController.navigationBar.shadowImage = nil
            navigationController.navigationBar.barStyle = UIBarStyle.Default
            navigationController.navigationBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
            
            let textAttributes = [
                NSForegroundColorAttributeName: UIColor.yepTintColor(),
                NSFontAttributeName: UIFont.navigationBarTitleFont()
            ]
            
            navigationController.navigationBar.titleTextAttributes = textAttributes
            navigationController.navigationBar.tintColor = nil
        }
        
        if let hidden = self.navigationController?.navigationBarHidden {
            
            if hidden {
                self.navigationController?.setNavigationBarHidden(false, animated: animatedOnNavigationBar)
            }

        }

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

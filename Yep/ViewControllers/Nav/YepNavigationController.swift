//
//  YepNavigationController.swift
//  Yep
//
//  Created by kevinzhow on 15/5/27.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class YepNavigationController: UINavigationController, UIGestureRecognizerDelegate, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        if respondsToSelector("interactivePopGestureRecognizer") {
            interactivePopGestureRecognizer.delegate = self
            
            delegate = self
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func pushViewController(viewController: UIViewController, animated: Bool) {
        if respondsToSelector("interactivePopGestureRecognizer") && animated {
            interactivePopGestureRecognizer.enabled = false
        }
        
        super.pushViewController(viewController, animated: animated)
    }
    
    override func popToRootViewControllerAnimated(animated: Bool) -> [AnyObject]? {
        if respondsToSelector("interactivePopGestureRecognizer") && animated {
            interactivePopGestureRecognizer.enabled = false
        }
        
        return super.popToRootViewControllerAnimated(animated)
    }
    
    override func popToViewController(viewController: UIViewController, animated: Bool) -> [AnyObject]? {
        if respondsToSelector("interactivePopGestureRecognizer") && animated {
            interactivePopGestureRecognizer.enabled = false
        }
        
        return super.popToViewController(viewController, animated: false)
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        if respondsToSelector("interactivePopGestureRecognizer") {
            interactivePopGestureRecognizer.enabled = true
        }
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == interactivePopGestureRecognizer
        {
            if self.viewControllers.count < 2 || self.visibleViewController == self.viewControllers[0] as! UIViewController
            {
                return false
            }
        }
        
        return true
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

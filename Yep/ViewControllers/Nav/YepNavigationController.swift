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

}

// http://stackoverflow.com/questions/20327165/popviewcontroller-strange-behaviour
// 很难work，无法重载
//// MARK: UINavigationBarDelegate
//
//extension UINavigationController {
//
////    func navigationBar(navigationBar: UINavigationBar, shouldPopItem item: UINavigationItem) -> Bool {
////        return true
////    }
//}
//
//extension YepNavigationController: UINavigationBarDelegate {
//
//    //override
//    func navigationBar(navigationBar: UINavigationBar, shouldPopItem item: UINavigationItem) -> Bool {
//
//        let forcePop: () -> Void = {
//            self.dirtyAction = nil
//            self.forcePopAction?()
//            self.forcePopAction = nil
//        }
//
//        if let dirtyAction = dirtyAction {
//
//            YepAlert.confirmOrCancel(title: NSLocalizedString("Notice", comment: ""), message: NSLocalizedString("Save before pop?", comment: ""), confirmTitle: NSLocalizedString("OK", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self.topViewController, withConfirmAction: {
//
//                dirtyAction()
//
//                forcePop()
//
//            }, cancelAction: {
//                forcePop()
//            })
//            
//            return false
//        }
//
//        return true
//        //return super.navigationBar(navigationBar, shouldPopItem: item)
//    }
//
//    func navigationBar(navigationBar: UINavigationBar, didPopItem item: UINavigationItem) {
////        self.forcePopAction?()
////        self.forcePopAction = nil
//        self.popViewControllerAnimated(true)
//    }
//}

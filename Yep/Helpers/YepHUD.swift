//
//  YepHUD.swift
//  Yep
//
//  Created by NIX on 15/4/27.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepConfig

final class YepHUD: NSObject {

    static let sharedInstance = YepHUD()

    var isShowing = false
    var dismissTimer: NSTimer?

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        return view
        }()

    lazy var activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        return view
        }()

    class func showActivityIndicator() {
        showActivityIndicatorWhileBlockingUI(true)
    }

    class func showActivityIndicatorWhileBlockingUI(blockingUI: Bool) {

        if self.sharedInstance.isShowing {
            return // TODO: 或者用新的取代旧的
        }

        dispatch_async(dispatch_get_main_queue()) {
            if
                let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
                let window = appDelegate.window {

                    self.sharedInstance.isShowing = true

                    self.sharedInstance.containerView.userInteractionEnabled = blockingUI

                    self.sharedInstance.containerView.alpha = 0
                    window.addSubview(self.sharedInstance.containerView)
                    self.sharedInstance.containerView.frame = window.bounds

                    UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions(rawValue: 0), animations: { () -> Void in
                        self.sharedInstance.containerView.alpha = 1

                    }, completion: { (finished) -> Void in
                        self.sharedInstance.containerView.addSubview(self.sharedInstance.activityIndicator)
                        self.sharedInstance.activityIndicator.center = self.sharedInstance.containerView.center
                        self.sharedInstance.activityIndicator.startAnimating()

                        self.sharedInstance.activityIndicator.alpha = 0
                        self.sharedInstance.activityIndicator.transform = CGAffineTransformMakeScale(0.0001, 0.0001)
                        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions(rawValue: 0), animations: { () -> Void in
                            self.sharedInstance.activityIndicator.transform = CGAffineTransformMakeScale(1.0, 1.0)
                            self.sharedInstance.activityIndicator.alpha = 1

                        }, completion: { (finished) -> Void in
                            self.sharedInstance.activityIndicator.transform = CGAffineTransformIdentity

                            if let dismissTimer = self.sharedInstance.dismissTimer {
                                dismissTimer.invalidate()
                            }
                            
                            self.sharedInstance.dismissTimer = NSTimer.scheduledTimerWithTimeInterval(YepConfig.forcedHideActivityIndicatorTimeInterval, target: self, selector: #selector(YepHUD.forcedHideActivityIndicator), userInfo: nil, repeats: false)
                        })
                    })
            }
        }
    }

    class func forcedHideActivityIndicator() {
        hideActivityIndicator() {
            if
                let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
                let viewController = appDelegate.window?.rootViewController {
                    YepAlert.alertSorry(message: NSLocalizedString("Wait too long, the operation may not be completed.", comment: ""), inViewController: viewController)
            }
        }
    }

    class func hideActivityIndicator() {
        hideActivityIndicator() {
        }
    }

    class func hideActivityIndicator(completion: () -> Void) {

        dispatch_async(dispatch_get_main_queue()) {

            if self.sharedInstance.isShowing {

                self.sharedInstance.activityIndicator.transform = CGAffineTransformIdentity

                UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions(rawValue: 0), animations: { () -> Void in
                    self.sharedInstance.activityIndicator.transform = CGAffineTransformMakeScale(0.0001, 0.0001)
                    self.sharedInstance.activityIndicator.alpha = 0

                }, completion: { (finished) -> Void in
                    self.sharedInstance.activityIndicator.removeFromSuperview()

                    UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions(rawValue: 0), animations: { () -> Void in
                        self.sharedInstance.containerView.alpha = 0

                    }, completion: { (finished) -> Void in
                        self.sharedInstance.containerView.removeFromSuperview()

                        completion()
                    })
                })
            }
            
            self.sharedInstance.isShowing = false
        }
    }
}



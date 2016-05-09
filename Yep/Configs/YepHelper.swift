//
//  YepHelper.swift
//  Yep
//
//  Created by kevinzhow on 15/5/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import RealmSwift
import Navi

typealias CancelableTask = (cancel: Bool) -> Void

extension String {
    
    func contains(find: String) -> Bool{
        return self.rangeOfString(find) != nil
    }
}

func delay(time: NSTimeInterval, work: dispatch_block_t) -> CancelableTask? {

    var finalTask: CancelableTask?

    let cancelableTask: CancelableTask = { cancel in
        if cancel {
            finalTask = nil // key

        } else {
            dispatch_async(dispatch_get_main_queue(), work)
        }
    }

    finalTask = cancelableTask

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
        if let task = finalTask {
            task(cancel: false)
        }
    }

    return finalTask
}

func cancel(cancelableTask: CancelableTask?) {
    cancelableTask?(cancel: true)
}

func unregisterThirdPartyPush() {
    dispatch_async(dispatch_get_main_queue()) {
        #if JPUSH
        JPUSHService.setAlias(nil, callbackSelector: nil, object: nil)
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        #endif
    }
}

func cleanRealmAndCaches() {

    // clean Realm

    guard let realm = try? Realm() else {
        return
    }

    let _ = try? realm.write {
        realm.deleteAll()
    }

    realm.refresh()

    println("cleaned realm!")

    // cleam all memory caches
    
    AvatarPod.clear()

    ImageCache.sharedInstance.cache.removeAllObjects()

    println("cleaned caches!")

    // clean Message File caches

    NSFileManager.cleanMessageCaches()

    // clean Avatar File caches

    NSFileManager.cleanAvatarCaches()

    println("cleaned files!")

    // clean shortcuts

    clearDynamicShortcuts()

    dispatch_async(dispatch_get_main_queue()) {
        NSNotificationCenter.defaultCenter().postNotificationName(EditProfileViewController.Notification.Logout, object: nil)
    }
}

extension String {
    func stringByAppendingPathComponent(path: String) -> String {
        return (self as NSString).stringByAppendingPathComponent(path)
    }
}


func cleanDiskCacheFolder() {
    
    let folderPath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
    let fileMgr = NSFileManager.defaultManager()
    
    guard let fileArray = try? fileMgr.contentsOfDirectoryAtPath(folderPath) else {
        return
    }
    
    for filename in fileArray  {
        do {
            try fileMgr.removeItemAtPath(folderPath.stringByAppendingPathComponent(filename))
        } catch {
            print(" clean error ")
        }
        
    }
}

extension UIImage {
    class func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

extension UINavigationBar {

    func hideBottomHairline() {
        let navigationBarImageView = hairlineImageViewInNavigationBar(self)
        navigationBarImageView?.hidden = true
    }
    
    func showBottomHairline() {
        let navigationBarImageView = hairlineImageViewInNavigationBar(self)
        navigationBarImageView?.hidden = false
    }
    
    func changeBottomHairImage() {
    }
    
    private func hairlineImageViewInNavigationBar(view: UIView) -> UIImageView? {
        if let view = view as? UIImageView where view.bounds.height <= 1.0 {
            return view
        }

        for subview in view.subviews {
            if let imageView = hairlineImageViewInNavigationBar(subview) {
                return imageView
            }
        }

        return nil
    }
}


//
//  YepHelpers.swift
//  Yep
//
//  Created by nixzhu on 15/11/2.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit
import RealmSwift
import Navi

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

    YepImageCache.sharedInstance.cache.removeAllObjects()

    println("cleaned caches!")

    // clean Message File caches

    FileManager.cleanMessageCaches()

    // clean Avatar File caches

    FileManager.cleanAvatarCaches()

    println("cleaned files!")

    // clean shortcuts

    clearDynamicShortcuts()

    SafeDispatch.async {
        NotificationCenter.default.post(name: YepConfig.NotificationName.logout, object: nil)
    }
}

extension String {
    func stringByAppendingPathComponent(_ path: String) -> String {
        return (self as NSString).appendingPathComponent(path)
    }
}


func cleanDiskCacheFolder() {
    
    let folderPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    let fileMgr = FileManager.default
    
    guard let fileArray = try? fileMgr.contentsOfDirectory(atPath: folderPath) else {
        return
    }
    
    for filename in fileArray  {
        do {
            try fileMgr.removeItem(atPath: folderPath.stringByAppendingPathComponent(filename))
        } catch {
            print(" clean error ")
        }
        
    }
}

extension UIImage {
    class func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}

extension UINavigationBar {

    func hideBottomHairline() {
        let navigationBarImageView = hairlineImageViewInNavigationBar(self)
        navigationBarImageView?.isHidden = true
    }
    
    func showBottomHairline() {
        let navigationBarImageView = hairlineImageViewInNavigationBar(self)
        navigationBarImageView?.isHidden = false
    }
    
    func changeBottomHairImage() {
    }
    
    fileprivate func hairlineImageViewInNavigationBar(_ view: UIView) -> UIImageView? {
        if let view = view as? UIImageView, view.bounds.height <= 1.0 {
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


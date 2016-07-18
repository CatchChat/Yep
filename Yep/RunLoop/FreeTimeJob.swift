//
//  FreeTimeJob.swift
//  Yep
//
//  Created by NIX on 16/7/18.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

class FreeTimeJob: NSObject {

    static var set = NSMutableSet()

    private class func setup() {

        var onceToken : dispatch_once_t = 0
        dispatch_once(&onceToken) {
            let runLoop = CFRunLoopGetMain()
            let observer: CFRunLoopObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.BeforeWaiting.rawValue | CFRunLoopActivity.Exit.rawValue, true, 0xFFFFFF) { (observer, activity) in
                guard set.count != 0 else {
                    return
                }

                let currentSet = set
                set = NSMutableSet()

                currentSet.enumerateObjectsUsingBlock({ (object, stop) in
                    if let job = object as? FreeTimeJob {
                        job.target.performSelector(job.selector)
                    }
                })
            }
            CFRunLoopAddObserver(runLoop, observer, kCFRunLoopCommonModes)
        }
    }

    let target: NSObject
    let selector: Selector

    init(target: NSObject, selector: Selector) {
        self.target = target
        self.selector = selector
        super.init()
    }
}


//
//  FreeTimeJob.swift
//  Yep
//
//  Created by NIX on 16/7/18.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

class FreeTimeJob {

    private static var once: Void = {
        let runLoop = CFRunLoopGetMain()
        let observer: CFRunLoopObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue | CFRunLoopActivity.exit.rawValue, true, 0xFFFFFF) { (observer, activity) in
            guard set.count != 0 else {
                return
            }

            let currentSet = set
            set = NSMutableSet()

            currentSet.enumerateObjects({ (object, stop) in
                if let job = object as? FreeTimeJob {
                    _ = job.target?.perform(job.selector)
                }
            })
        }
        CFRunLoopAddObserver(runLoop, observer, CFRunLoopMode.commonModes)
    }()

    fileprivate static var set = NSMutableSet()

    fileprivate static var onceToken: Int = 0
    fileprivate class func setup() {
        _ = FreeTimeJob.once
    }

    fileprivate weak var target: NSObject?
    fileprivate let selector: Selector

    init(target: NSObject, selector: Selector) {
        self.target = target
        self.selector = selector
    }

    func commit() {
        FreeTimeJob.setup()
        FreeTimeJob.set.add(self)
    }
}


//
//  SafeGCD.swift
//  Yep
//
//  Created by NIX on 16/6/15.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

class SafeGCD {

    private let mainQueueKey = UnsafeMutablePointer<Void>.alloc(1)
    private let mainQueueValue = UnsafeMutablePointer<Void>.alloc(1)

    private static let sharedSafeGCD = SafeGCD()

    private init() {
        dispatch_queue_set_specific(dispatch_get_main_queue(), mainQueueKey, mainQueueValue, nil)
    }

    class func asyncDispatch(onQueue queue: dispatch_queue_t = dispatch_get_main_queue(), forWork block: dispatch_block_t) {
        if queue === dispatch_get_main_queue() {
            if dispatch_get_specific(sharedSafeGCD.mainQueueKey) == sharedSafeGCD.mainQueueValue {
                block()
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    block()
                }
            }
        } else {
            dispatch_async(queue) {
                block()
            }
        }
    }
}


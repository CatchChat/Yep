//
//  SafeDispatch.swift
//  Yep
//
//  Created by NIX on 16/6/15.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

open class SafeDispatch {

    fileprivate let mainQueueKey = UnsafeMutableRawPointer(allocatingCapacity: 1)
    fileprivate let mainQueueValue = UnsafeMutableRawPointer(allocatingCapacity: 1)

    fileprivate static let sharedSafeDispatch = SafeDispatch()

    fileprivate init() {
        DispatchQueue.main.setSpecific(key: /*Migrator FIXME: Use a variable of type DispatchSpecificKey*/ mainQueueKey, value: mainQueueValue)
    }

    open class func async(onQueue queue: DispatchQueue = DispatchQueue.main, forWork block: @escaping ()->()) {
        if queue === DispatchQueue.main {
            if DispatchQueue.getSpecific(sharedSafeDispatch.mainQueueKey) == sharedSafeDispatch.mainQueueValue {
                block()
            } else {
                DispatchQueue.main.async {
                    block()
                }
            }
        } else {
            queue.async {
                block()
            }
        }
    }
}


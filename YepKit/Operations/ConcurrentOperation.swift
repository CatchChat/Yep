//
//  ConcurrentOperation.swift
//  Yep
//
//  Created by nixzhu on 16/1/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

open class ConcurrentOperation: Operation {

    enum State: String {
        case Ready, Executing, Finished

        fileprivate var keyPath: String {
            return "is" + rawValue
        }
    }

    var state = State.Ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }

    override open var isReady: Bool {
        return super.isReady && state == .Ready
    }

    override open var isExecuting: Bool {
        return state == .Executing
    }

    override open var isFinished: Bool {
        return state == .Finished
    }

    override open var isAsynchronous: Bool {
        return true
    }

    override open func start() {
        if isCancelled {
            state = .Finished
            return
        }

        main()
        state = .Executing
    }

    override open func cancel() {
        state = .Finished
    }
}


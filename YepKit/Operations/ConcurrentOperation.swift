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
        case ready, executing, finished

        fileprivate var keyPath: String {
            return "is" + rawValue.capitalized
        }
    }

    var state: State = .ready {
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
        return super.isReady && state == .ready
    }

    override open var isExecuting: Bool {
        return state == .executing
    }

    override open var isFinished: Bool {
        return state == .finished
    }

    override open var isAsynchronous: Bool {
        return true
    }

    override open func start() {
        if isCancelled {
            state = .finished
            return
        }

        main()
        state = .executing
    }

    override open func cancel() {
        state = .finished
    }
}


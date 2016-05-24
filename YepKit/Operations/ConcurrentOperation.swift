//
//  ConcurrentOperation.swift
//  Yep
//
//  Created by nixzhu on 16/1/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

public class ConcurrentOperation: NSOperation {

    enum State: String {
        case Ready, Executing, Finished

        private var keyPath: String {
            return "is" + rawValue
        }
    }

    var state = State.Ready {
        willSet {
            willChangeValueForKey(newValue.keyPath)
            willChangeValueForKey(state.keyPath)
        }
        didSet {
            didChangeValueForKey(oldValue.keyPath)
            didChangeValueForKey(state.keyPath)
        }
    }
}

public extension ConcurrentOperation {

    override public var ready: Bool {
        return super.ready && state == .Ready
    }

    override public var executing: Bool {
        return state == .Executing
    }

    override public var finished: Bool {
        return state == .Finished
    }

    override public var asynchronous: Bool {
        return true
    }

    override public func start() {
        if cancelled {
            state = .Finished
            return
        }

        main()
        state = .Executing
    }
    
    override public func cancel() {
        state = .Finished
    }
}


//
//  FPSLabel.swift
//  Yep
//
//  Created by nixzhu on 15/12/15.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FPSLabel: UILabel {

    private var displayLink: CADisplayLink?
    private var lastTime: NSTimeInterval = 0
    private var count: Int = 0

    deinit {
        displayLink?.invalidate()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        run()
    }

    func run() {

        displayLink = CADisplayLink(target: self, selector: "tick:")
        displayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
    }

    func tick(displayLink: CADisplayLink) {

        if lastTime == 0 {
            lastTime = displayLink.timestamp
            return
        }

        count += 1

        let timeDelta = displayLink.timestamp - lastTime

        if timeDelta < 1 {
            return
        }

        lastTime = displayLink.timestamp

        let fps: Double = Double(count) / timeDelta

        count = 0

        text = String(format: "%.1f", fps)
    }
}


//
//  FreeTimeJob.swift
//  Yep
//
//  Created by NIX on 16/7/18.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

class FreeTimeJob: NSObject {

    let target: NSObject
    let selector: Selector

    init(target: NSObject, selector: Selector) {
        self.target = target
        self.selector = selector
        super.init()
    }
}


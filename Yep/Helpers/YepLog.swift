//
//  YepLog.swift
//  Yep
//
//  Created by nixzhu on 15/9/4.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation

func println(@autoclosure item: () -> Any) {
    #if DEBUG
        Swift.print(item())
    #endif
}


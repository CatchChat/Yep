//
//  YepHelpers.swift
//  Yep
//
//  Created by nixzhu on 15/11/2.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import Foundation

final class Box<T> {
    let value: T

    init(value: T) {
        self.value = value
    }
}
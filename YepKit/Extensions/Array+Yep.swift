//
//  Array+Yep.swift
//  Yep
//
//  Created by NIX on 15/7/30.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

public extension Array {

    public subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}


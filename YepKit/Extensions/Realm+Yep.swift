//
//  Realm+Yep.swift
//  Yep
//
//  Created by NIX on 15/6/30.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import RealmSwift

public extension Results {

    public subscript (safe index: Int) -> T? {
        return indices ~= index ? self[index] : nil
    }
}

public extension List {

    public subscript (safe index: Int) -> T? {
        return indices ~= index ? self[index] : nil
    }
}


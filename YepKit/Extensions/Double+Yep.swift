//
//  Double+Yep.swift
//  Yep
//
//  Created by NIX on 16/5/23.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

public extension Double {

    public func yep_format(f: String) -> String {
        return NSString(format: "%\(f)f", self) as String
    }
}


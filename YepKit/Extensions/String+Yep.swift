//
//  String+Yep.swift
//  Yep
//
//  Created by NIX on 16/5/23.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

public extension String {

    public func contains(find: String) -> Bool{
        return self.rangeOfString(find) != nil
    }
}


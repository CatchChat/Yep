//
//  String+YepShare.swift
//  Yep
//
//  Created by NIX on 16/5/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

extension String {

    func yepshare_truncate(length: Int, trailing: String? = nil) -> String {
        if self.characters.count > length {
            return self.substringToIndex(self.startIndex.advancedBy(length)) + (trailing ?? "")
        } else {
            return self
        }
    }

    var yepshare_truncatedForFeed: String {
        return yepshare_truncate(120, trailing: "...")
    }
}


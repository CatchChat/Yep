//
//  DeviceGuru+Yep.swift
//  Yep
//
//  Created by NIX on 16/4/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import DeviceGuru

extension Hardware {

    var yep_supportQuickAction: Bool {

        switch self {
        case .IPHONE_6S, .IPHONE_6_PLUS:
            return true
        default:
            return false
        }
    }
}

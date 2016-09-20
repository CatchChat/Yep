//
//  DeviceUtil+Yep.swift
//  Yep
//
//  Created by NIX on 16/9/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import DeviceUtil

extension DeviceUtil {

    static var yep_isLowEndDevice: Bool {

        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            if DeviceUtil.hardwareNumber() < 6 {
                return true
            }
        case .pad:
            if DeviceUtil.hardwareNumber() < 4 {
                return true
            }
        default:
            return false
        }

        return false
    }
}


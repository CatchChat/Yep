//
//  DeviceGuru+Yep.swift
//  Yep
//
//  Created by NIX on 16/4/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import DeviceGuru

extension DeviceGuru {

    static var yep_isLowEndDevice: Bool {

        switch UIDevice.currentDevice().userInterfaceIdiom {
        case .Phone:
            if DeviceGuru.hardwareNumber() < 6 {
                return true
            }
        case .Pad:
            if DeviceGuru.hardwareNumber() < 4 {
                return true
            }
        default:
            return false
        }
 
        return false
    }
}


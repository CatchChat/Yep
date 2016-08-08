//
//  CLPlacemark+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/12/8.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import CoreLocation

extension CLPlacemark {

    var yep_autoName: String? {

        if let a = areasOfInterest?.first {
            return a
        }

        if let locality = locality, thoroughfare = thoroughfare {
            return String(format: NSLocalizedString("localityAndThoroughfare_%@_%@", comment: ""), locality, thoroughfare)
        }

        return name ?? administrativeArea
    }
}


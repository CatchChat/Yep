//
//  CLLocationCoordinate2D+Yep.swift
//  Yep
//
//  Created by nixzhu on 16/1/7.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import CoreLocation

extension CLLocationCoordinate2D {

    var yep_applyChinaLocationShift: CLLocationCoordinate2D {

        let latitudeShift: CLLocationDegrees = YepUserDefaults.latitudeShift.value ?? 0
        let longitudeShift: CLLocationDegrees = YepUserDefaults.longitudeShift.value ?? 0

        println("latitudeShift: \(latitudeShift)")
        println("longitudeShift: \(longitudeShift)")

        return CLLocationCoordinate2D(latitude: latitude + latitudeShift, longitude: longitude + longitudeShift)
    }
}


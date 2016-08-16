//
//  YepLocationService.swift
//  Yep
//
//  Created by kevinzhow on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import CoreLocation
import YepKit

final class YepLocationService: NSObject, CLLocationManagerDelegate {

    class func turnOn() {
        if (CLLocationManager.locationServicesEnabled()){
            println("begin updating location")
            self.sharedManager.locationManager.startUpdatingLocation()
        }
    }
    
    static let sharedManager = YepLocationService()

    var afterUpdatedLocationAction: (CLLocation -> Void)?
    
    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.requestWhenInUseAuthorization()
        return locationManager
    }()

    var currentLocation: CLLocation? {
        didSet {
            if let currentLocation = currentLocation {
                YepUserDefaults.userCoordinateLatitude.value = currentLocation.coordinate.latitude
                YepUserDefaults.userCoordinateLongitude.value = currentLocation.coordinate.longitude
            }
        }
    }
    var address: String?
    let geocoder = CLGeocoder()

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        guard let newLocation = locations.last else {
            return
        }

        afterUpdatedLocationAction?(newLocation)

        // 尽量减少对服务器的请求和反向查询

        if let oldLocation = currentLocation {
            let distance = newLocation.distanceFromLocation(oldLocation)

            if distance < YepConfig.Location.distanceThreshold {
                return
            }
        }

        currentLocation = newLocation

        updateMyselfWithInfo(["latitude": newLocation.coordinate.latitude, "longitude": newLocation.coordinate.longitude], failureHandler: nil, completion: { _ in
        })

        geocoder.reverseGeocodeLocation(newLocation, completionHandler: { (placemarks, error) in

            SafeDispatch.async { [weak self] in

                if (error != nil) {
                    println("self reverse geocode fail: \(error?.localizedDescription)")

                } else {
                    if let placemarks = placemarks {

                        if let firstPlacemark = placemarks.first {

                            self?.address = firstPlacemark.locality ?? (firstPlacemark.name ?? firstPlacemark.country)

                            NSNotificationCenter.defaultCenter().postNotificationName("YepLocationUpdated", object: nil)
                        }
                    }
                }
            }
        })
    }
}


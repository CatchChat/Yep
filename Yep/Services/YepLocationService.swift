//
//  YepLocationService.swift
//  Yep
//
//  Created by kevinzhow on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import CoreLocation

class YepLocationService: NSObject, CLLocationManagerDelegate {

    class func turnOn() {
        if (CLLocationManager.locationServicesEnabled()){
            println("Update Location")
            self.sharedManager.locationManager.startUpdatingLocation()
        }
    }
    
    static let sharedManager = YepLocationService()
    
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

    var currentLocation: CLLocation?
    var address: String?
    let geocoder = CLGeocoder()
    var userLocationUpdated = false


    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        
        if !userLocationUpdated {
            updateMyselfWithInfo(["latitude": newLocation.coordinate.latitude, "longitude": newLocation.coordinate.longitude], failureHandler: nil, completion: { success in
                if success {
                    self.userLocationUpdated = true
                }
            })
        }
        
        geocoder.reverseGeocodeLocation(newLocation, completionHandler: { (placemarks, error) in
            
            if (error != nil) {println("reverse geodcode fail: \(error.localizedDescription)")}
            
            if let pm = placemarks as? [CLPlacemark] {
                if pm.count > 0 {
                    
                    var placemark = pm.first
                    
                    self.address = placemark?.locality
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("YepLocationUpdated", object: self.address)
                }
            }
            
        })
    }
}


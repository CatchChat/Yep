//
//  PickLocationViewController.swift
//  Yep
//
//  Created by NIX on 15/5/4.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import MapKit

class PickLocationViewController: UIViewController {


    @IBOutlet weak var mapView: MKMapView!


    override func viewDidLoad() {
        super.viewDidLoad()

        let location = YepLocationService.sharedManager.locationManager.location
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 20000, 20000)
        mapView.setRegion(region, animated: true)

        mapView.showsUserLocation = true
        mapView.delegate = self
    }


    // MARK: Actions
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func send(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: { () -> Void in
            // TODO: send location
        })
    }
}

extension PickLocationViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        let location = userLocation.location
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        mapView.setRegion(region, animated: true)
    }
}


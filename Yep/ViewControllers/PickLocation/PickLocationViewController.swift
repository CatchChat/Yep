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

    @IBOutlet weak var sendButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarTopToSuperBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!

    var isFirstShowUserLocation = true

    var userPickedLocationPin: UserPickedLocationPin?


    let pickLocationCellIdentifier = "PickLocationCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerNib(UINib(nibName: pickLocationCellIdentifier, bundle: nil), forCellReuseIdentifier: pickLocationCellIdentifier)
        tableView.rowHeight = 50

        sendButton.enabled = false
        
        mapView.showsUserLocation = true
        mapView.delegate = self

        let location = YepLocationService.sharedManager.locationManager.location
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 20000, 20000)
        mapView.setRegion(region, animated: false)

        let tap = UITapGestureRecognizer(target: self, action: "addAnnotation:")
        mapView.addGestureRecognizer(tap)
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

    func addAnnotation(sender: UITapGestureRecognizer) {

        mapView.removeAnnotation(userPickedLocationPin)

        let point = sender.locationInView(mapView)
        let coordinate = mapView.convertPoint(point, toCoordinateFromView: mapView)

        let pin = UserPickedLocationPin(title: "Pin", subtitle: "User Picked Location", coordinate: coordinate)
        mapView.addAnnotation(pin)

        userPickedLocationPin = pin
    }
}

extension PickLocationViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {

        if isFirstShowUserLocation {
            isFirstShowUserLocation = false

            sendButton.enabled = true

            let location = userLocation.location
            let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
            mapView.setRegion(region, animated: true)
        }

    }

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {

        if let annotation = annotation as? UserPickedLocationPin {

            let identifier = "UserPickedLocationPinView"

            if let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) {
                annotationView.annotation = annotation

                return annotationView

            } else {
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView.image = UIImage(named: "icon_pin")
                annotationView.enabled = false
                annotationView.canShowCallout = false

                return annotationView
            }
        }

        return nil
    }
}

extension PickLocationViewController: UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {

        navigationController?.setNavigationBarHidden(true, animated: true)

        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
            self.searchBarTopToSuperBottomConstraint.constant = CGRectGetHeight(self.view.bounds) - 20
            self.view.layoutIfNeeded()

        }, completion: { finished in
            self.searchBar.setShowsCancelButton(true, animated: true)
        })

        return true
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {

        searchBar.resignFirstResponder()

        navigationController?.setNavigationBarHidden(false, animated: true)

        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
            self.searchBarTopToSuperBottomConstraint.constant = 250
            self.view.layoutIfNeeded()

        }, completion: { finished in
            self.searchBar.setShowsCancelButton(false, animated: true)
        })
    }
}

extension PickLocationViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(pickLocationCellIdentifier) as! PickLocationCell
        return cell
    }
}


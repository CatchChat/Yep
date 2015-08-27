//
//  PickLocationViewController.swift
//  Yep
//
//  Created by NIX on 15/5/4.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import MapKit
import Proposer

typealias SendLocationAction = (coordinate: CLLocationCoordinate2D) -> Void

class PickLocationViewController: UIViewController {

    var sendLocationAction: SendLocationAction?

    @IBOutlet weak var sendButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarTopToSuperBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!

    var isFirstShowUserLocation = true

    var userPickedLocationPin: UserPickedLocationPin? {
        didSet {
            reloadTableView()
        }
    }

    var searchedMapItems = [MKMapItem]() {
        didSet {
            reloadTableView()
        }
    }
    var searchedLocationPins = [UserPickedLocationPin]()

    lazy var geocoder = CLGeocoder()

    var placemarks = [CLPlacemark]() {
        didSet {
            reloadTableView()
        }
    }

    var foursquareVenues = [FoursquareVenue]() {
        didSet {
            for venue in foursquareVenues {
                let pin = UserPickedLocationPin(title: "Pin", subtitle: "Foursquare Venue", coordinate: venue.coordinate)
                mapView.addAnnotation(pin)
            }

            reloadTableView()
        }
    }

    let pickLocationCellIdentifier = "PickLocationCell"
    var pickedLocationIndexPath: NSIndexPath?
    var pickedLocationCoordinate: CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Pick Location", comment: "")

        tableView.registerNib(UINib(nibName: pickLocationCellIdentifier, bundle: nil), forCellReuseIdentifier: pickLocationCellIdentifier)
        tableView.rowHeight = 50

        sendButton.enabled = false
        
        mapView.showsUserLocation = true
        mapView.delegate = self

        if let location = YepLocationService.sharedManager.locationManager.location {
            let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 20000, 20000)
            mapView.setRegion(region, animated: false)

        } else {
            proposeToAccess(.Location(.WhenInUse), agreed: {

                YepLocationService.turnOn()

            }, rejected: {
                self.alertCanNotAccessLocation()
            })
        }

        let tap = UITapGestureRecognizer(target: self, action: "addAnnotation:")
        mapView.addGestureRecognizer(tap)
    }


    // MARK: Actions
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func send(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: { () -> Void in
            if let sendLocationAction = self.sendLocationAction {

                if let coordinate = self.pickedLocationCoordinate {
                    sendLocationAction(coordinate: coordinate)
                } else {
                    sendLocationAction(coordinate: self.mapView.userLocation.location.coordinate)
                }
            }
        })
    }

    func addAnnotation(sender: UITapGestureRecognizer) {

        mapView.removeAnnotation(userPickedLocationPin)

        let point = sender.locationInView(mapView)
        let coordinate = mapView.convertPoint(point, toCoordinateFromView: mapView)

        let pin = UserPickedLocationPin(title: "Pin", subtitle: "User Picked Location", coordinate: coordinate)
        mapView.addAnnotation(pin)

        pickedLocationCoordinate = pin.coordinate
        pickedLocationIndexPath = NSIndexPath(forRow: 0, inSection: Section.UserPickedLocation.rawValue)
        userPickedLocationPin = pin
    }

    func placemarksAroundLocation(location: CLLocation, completion: [CLPlacemark] -> Void) {
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in

            if (error != nil) {
                println("reverse geodcode fail: \(error.localizedDescription)")

                completion([])
            }

            if let placemarks = placemarks as? [CLPlacemark] {
                
                completion(placemarks)

            } else {
                println("No Placemarks!")

                completion([])
            }
        })
    }

    func reloadTableView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
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

            foursquareVenuesNearby(location, failureHandler: nil, completion: { [weak self] venues in
                self?.foursquareVenues = venues
            })
        }

        placemarksAroundLocation(userLocation.location) { placemarks in
            self.placemarks = placemarks.filter({ $0.name != nil })
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
        shrinkSearchLocationView()
    }

    func shrinkSearchLocationView() {
        searchBar.resignFirstResponder()

        navigationController?.setNavigationBarHidden(false, animated: true)

        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
            self.searchBarTopToSuperBottomConstraint.constant = 250
            self.view.layoutIfNeeded()

        }, completion: { finished in
            self.searchBar.setShowsCancelButton(false, animated: true)
        })
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let name = searchBar.text

        searchPlacesByName(name)

        shrinkSearchLocationView()
    }

    private func searchPlacesByName(name: String, needAppend: Bool = false) {

        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = name

        request.region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.location.coordinate, 200000, 200000)

        let search = MKLocalSearch(request: request)

        search.startWithCompletionHandler { [weak self] response, error in
            if error == nil {
                if let mapItems = response.mapItems as? [MKMapItem] {

                    let searchedMapItems = mapItems.filter({ $0.placemark.name != nil })

                    if needAppend {
                        self?.searchedMapItems += searchedMapItems

                    } else {
                        self?.searchedMapItems = searchedMapItems

                        self?.mapView.removeAnnotations(self?.searchedLocationPins)
                    }

                    var searchedLocationPins = [UserPickedLocationPin]()

                    for item in searchedMapItems {
                        let pin = UserPickedLocationPin(title: "Pin", subtitle: "User Searched Location", coordinate: item.placemark.location.coordinate)
                        self?.mapView.addAnnotation(pin)

                        searchedLocationPins.append(pin)
                    }

                    if needAppend {
                        self?.searchedLocationPins += searchedLocationPins
                    } else {
                        self?.searchedLocationPins = searchedLocationPins
                    }
                }
            }
        }
    }
}

extension PickLocationViewController: UITableViewDataSource, UITableViewDelegate {

    enum Section: Int {
        case CurrentLocation = 0
        case UserPickedLocation
        case Placemarks
        case SearchedLocation
        case FoursquareVenue
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 5
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch section {
        case Section.CurrentLocation.rawValue:
            return 1
        case Section.UserPickedLocation.rawValue:
            return (userPickedLocationPin == nil ? 0 : 1)
        case Section.Placemarks.rawValue:
            return placemarks.count
        case Section.SearchedLocation.rawValue:
            return searchedMapItems.count
        case Section.FoursquareVenue.rawValue:
            return foursquareVenues.count
        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(pickLocationCellIdentifier) as! PickLocationCell

        switch indexPath.section {

        case Section.CurrentLocation.rawValue:
            cell.iconImageView.hidden = false
            cell.iconImageView.image = UIImage(named: "icon_current_location")
            cell.locationLabel.text = NSLocalizedString("My Current Location", comment: "")
            cell.checkImageView.hidden = false

        case Section.UserPickedLocation.rawValue:
            cell.iconImageView.hidden = false
            cell.iconImageView.image = UIImage(named: "icon_pin")
            cell.locationLabel.text = NSLocalizedString("Picked Location", comment: "")
            cell.checkImageView.hidden = true

        case Section.Placemarks.rawValue:
            cell.iconImageView.hidden = true
            let placemark = placemarks[indexPath.row]

            let text = placemark.name ?? "🐌"

            cell.locationLabel.text = text

            cell.checkImageView.hidden = true

        case Section.SearchedLocation.rawValue:
            cell.iconImageView.hidden = false
            cell.iconImageView.image = UIImage(named: "icon_pin")

            if let placemark = searchedMapItems[indexPath.row].placemark {
                cell.locationLabel.text = placemark.name ?? ""
            } else {
                cell.locationLabel.text = ""
            }

            cell.checkImageView.hidden = true

        case Section.FoursquareVenue.rawValue:
            cell.iconImageView.hidden = false
            cell.iconImageView.image = UIImage(named: "icon_pin")

            let foursquareVenue = foursquareVenues[indexPath.row]
            cell.locationLabel.text = foursquareVenue.name

            cell.checkImageView.hidden = true

        default:
            break
        }

        if let pickLocationIndexPath = pickedLocationIndexPath {
            cell.checkImageView.hidden = !(pickLocationIndexPath == indexPath)
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if let pickedLocationIndexPath = pickedLocationIndexPath {
            if let cell = tableView.cellForRowAtIndexPath(pickedLocationIndexPath) as? PickLocationCell {
                cell.checkImageView.hidden = true
            }

        } else {
            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: Section.CurrentLocation.rawValue)) as? PickLocationCell {
                cell.checkImageView.hidden = true
            }
        }

        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PickLocationCell {
            cell.checkImageView.hidden = false
        }

        pickedLocationIndexPath = indexPath


        switch indexPath.section {

        case Section.CurrentLocation.rawValue:
            if let location = mapView.userLocation.location {
                pickedLocationCoordinate = location.coordinate
            }

        case Section.UserPickedLocation.rawValue:
            pickedLocationCoordinate = userPickedLocationPin?.coordinate

        case Section.Placemarks.rawValue:
            let placemark = placemarks[indexPath.row]
            pickedLocationCoordinate = placemark.location.coordinate

        case Section.SearchedLocation.rawValue:
            let placemark = self.searchedMapItems[indexPath.row].placemark
            pickedLocationCoordinate = placemark.location.coordinate

        case Section.FoursquareVenue.rawValue:
            let foursquareVenue = foursquareVenues[indexPath.row]
            pickedLocationCoordinate = foursquareVenue.coordinate

        default:
            break
        }

        if let pickedLocationCoordinate = pickedLocationCoordinate {
            let region = MKCoordinateRegionMakeWithDistance(pickedLocationCoordinate, 200, 200)
            mapView.setRegion(region, animated: true)
        }

    }
}


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

class PickLocationViewController: UIViewController {

    typealias SendLocationAction = (locationInfo: Location.Info) -> Void
    var sendLocationAction: SendLocationAction?

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var sendButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarTopToSuperBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var isFirstShowUserLocation = true

    var locationPin: LocationPin? {
        didSet {
            reloadTableView()
        }
    }

    var searchedMapItems = [MKMapItem]() {
        didSet {
            reloadTableView()
        }
    }

    lazy var geocoder = CLGeocoder()

    var placemarks = [CLPlacemark]() {
        didSet {
            reloadTableView()
        }
    }

    var foursquareVenues = [FoursquareVenue]() {
        didSet {
            reloadTableView()
        }
    }

    let pickLocationCellIdentifier = "PickLocationCell"

    enum Location {

        struct Info {
            let coordinate: CLLocationCoordinate2D
            let name: String?
        }

        case Picked(info: Info)
        case Selected(info: Info)

        var info: Info {
            switch self {
            case .Picked(let locationInfo):
                return locationInfo
            case .Selected(let locationInfo):
                return locationInfo
            }
        }

        var isPicked: Bool {
            switch self {
            case .Picked:
                return true
            default:
                return false
            }
        }
    }

    var location: Location? {
        willSet {
            if let coordinate = newValue?.info.coordinate {
                updateLocationPinWithCoordinate(coordinate)
            }
        }
    }

    var selectedLocationIndexPath: NSIndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Pick Location", comment: "")

        cancelButton.title = NSLocalizedString("Cancel", comment: "")
        sendButton.title = NSLocalizedString("Send", comment: "")

        searchBar.placeholder = NSLocalizedString("Search", comment: "")

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

        activityIndicator.startAnimating()

        view.bringSubviewToFront(tableView)
        view.bringSubviewToFront(searchBar)
        view.bringSubviewToFront(activityIndicator)
    }

    // MARK: Actions
    
    @IBAction func cancel(sender: UIBarButtonItem) {

        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func send(sender: UIBarButtonItem) {

        dismissViewControllerAnimated(true, completion: {

            if let sendLocationAction = self.sendLocationAction {

                if let location = self.location {
                    sendLocationAction(locationInfo: location.info)

                } else {
                    guard let location = self.mapView.userLocation.location else {
                        return
                    }

                    sendLocationAction(locationInfo: Location.Info(coordinate: location.coordinate, name: nil))
                }
            }
        })
    }

    private func updateLocationPinWithCoordinate(coordinate: CLLocationCoordinate2D) {

        if let locationPin = locationPin {
            mapView.removeAnnotation(locationPin)
        }

        let pin = LocationPin(title: "Pin", subtitle: "User Picked Location", coordinate: coordinate)
        mapView.addAnnotation(pin)

        locationPin = pin
    }

    func addAnnotation(sender: UITapGestureRecognizer) {

        let point = sender.locationInView(mapView)
        let coordinate = mapView.convertPoint(point, toCoordinateFromView: mapView)

        location = .Picked(info: Location.Info(coordinate: coordinate, name: nil))

        selectedLocationIndexPath = NSIndexPath(forRow: 0, inSection: Section.UserPickedLocation.rawValue)
    }

    func placemarksAroundLocation(location: CLLocation, completion: [CLPlacemark] -> Void) {

        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in

            if (error != nil) {
                println("reverse geodcode fail: \(error?.localizedDescription)")

                completion([])

                return
            }

            if let placemarks = placemarks {
                
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

// MARK: - MKMapViewDelegate

extension PickLocationViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {

        guard let location = userLocation.location else {
            return
        }

        activityIndicator.stopAnimating()

        if isFirstShowUserLocation {
            isFirstShowUserLocation = false

            sendButton.enabled = true

            let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
            mapView.setRegion(region, animated: true)

            foursquareVenuesNearby(location, failureHandler: nil, completion: { [weak self] venues in
                self?.foursquareVenues = venues
            })
        }

        placemarksAroundLocation(location) { placemarks in
            self.placemarks = placemarks.filter({ $0.name != nil })
        }
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {

        if let annotation = annotation as? LocationPin {

            let identifier = "LocationPinView"

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

// MARK: - UISearchBarDelegate

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

        guard let name = searchBar.text else {
            return
        }

        searchPlacesByName(name)

        shrinkSearchLocationView()
    }

    private func searchPlacesByName(name: String, needAppend: Bool = false) {

        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = name

        if let location = mapView.userLocation.location {
            request.region = MKCoordinateRegionMakeWithDistance(location.coordinate, 200000, 200000)
        }

        let search = MKLocalSearch(request: request)

        search.startWithCompletionHandler { [weak self] response, error in
            if error == nil {
                if let mapItems = response?.mapItems {

                    let searchedMapItems = mapItems.filter({ $0.placemark.name != nil })

                    if needAppend {
                        self?.searchedMapItems += searchedMapItems

                    } else {
                        self?.searchedMapItems = searchedMapItems
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

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
            if let isPicked = location?.isPicked {
                if isPicked {
                    return 1
                }
            }
            return 0
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

            let placemark = searchedMapItems[indexPath.row].placemark
            cell.locationLabel.text = placemark.name

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

        if let pickLocationIndexPath = selectedLocationIndexPath {
            cell.checkImageView.hidden = !(pickLocationIndexPath == indexPath)
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if let selectedLocationIndexPath = selectedLocationIndexPath {
            if let cell = tableView.cellForRowAtIndexPath(selectedLocationIndexPath) as? PickLocationCell {
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

        selectedLocationIndexPath = indexPath


        switch indexPath.section {

        case Section.CurrentLocation.rawValue:
            if let _location = mapView.userLocation.location {
                location = .Selected(info: Location.Info(coordinate: _location.coordinate, name: NSLocalizedString("My Current Location", comment: "")))
            }

        case Section.UserPickedLocation.rawValue:
            if let coordinate = locationPin?.coordinate {
                location = .Picked(info: Location.Info(coordinate: coordinate, name: NSLocalizedString("Picked Location", comment: "")))
            }

        case Section.Placemarks.rawValue:
            let placemark = placemarks[indexPath.row]
            guard let _location = placemark.location else {
                break
            }
            location = .Selected(info: Location.Info(coordinate: _location.coordinate, name: placemark.name))

        case Section.SearchedLocation.rawValue:
            let placemark = self.searchedMapItems[indexPath.row].placemark
            guard let _location = placemark.location else {
                break
            }
            location = .Selected(info: Location.Info(coordinate: _location.coordinate, name: placemark.name))

        case Section.FoursquareVenue.rawValue:
            let foursquareVenue = foursquareVenues[indexPath.row]
            location = .Selected(info: Location.Info(coordinate: foursquareVenue.coordinate, name: foursquareVenue.name))

        default:
            break
        }

        if let locationPin = locationPin {
            let region = MKCoordinateRegionMakeWithDistance(locationPin.coordinate, 200, 200)
            mapView.setRegion(region, animated: true)
        }
    }
}


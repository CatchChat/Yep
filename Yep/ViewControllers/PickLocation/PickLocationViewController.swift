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

class PickLocationViewController: SegueViewController {

    enum Purpose {
        case Message
        case Feed
    }
    var purpose: Purpose = .Message

    var preparedSkill: Skill?

    var afterCreatedFeedAction: ((feed: DiscoveredFeed) -> Void)?

    typealias SendLocationAction = (locationInfo: Location.Info) -> Void
    var sendLocationAction: SendLocationAction?

    @IBOutlet private weak var cancelButton: UIBarButtonItem!
    @IBOutlet private weak var doneButton: UIBarButtonItem!
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var pinImageView: UIImageView!
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var searchBarTopToSuperBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private var isFirstShowUserLocation = true

    private var searchedMapItems = [MKMapItem]() {
        didSet {
            reloadTableView()
        }
    }

    private lazy var geocoder = CLGeocoder()

    private var userLocationPlacemarks = [CLPlacemark]() {
        didSet {
            if let placemark = userLocationPlacemarks.first {
                if let location = self.location {
                    if case .Default = location {
                        var info = location.info
                        info.name = placemark.yep_autoName
                        self.location = .Default(info: info)
                    }
                }
            }

            reloadTableView()
        }
    }

    private var pickedLocationPlacemarks = [CLPlacemark]() {
        didSet {
            if let placemark = pickedLocationPlacemarks.first {
                if let location = self.location {
                    if case .Picked = location {
                        var info = location.info
                        info.name = placemark.yep_autoName
                        self.location = .Picked(info: info)
                    }
                }
            }

            reloadTableView()
        }
    }

    private var foursquareVenues = [FoursquareVenue]() {
        didSet {
            reloadTableView()
        }
    }

    private let pickLocationCellIdentifier = "PickLocationCell"

    enum Location {

        struct Info {
            let coordinate: CLLocationCoordinate2D
            var name: String?
        }

        case Default(info: Info)
        case Picked(info: Info)
        case Selected(info: Info)

        var info: Info {
            switch self {
            case .Default(let locationInfo):
                return locationInfo
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

    private var location: Location? {
        willSet {
            if let _ = newValue {
                doneButton.enabled = true
            }
        }
    }

    private var selectedLocationIndexPath: NSIndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Pick Location", comment: "")

        cancelButton.title = NSLocalizedString("Cancel", comment: "")

        switch purpose {
        case .Message:
            doneButton.title = NSLocalizedString("Send", comment: "")
        case .Feed:
            doneButton.title = NSLocalizedString("Next", comment: "")
        }

        searchBar.placeholder = NSLocalizedString("Search", comment: "")

        tableView.registerNib(UINib(nibName: pickLocationCellIdentifier, bundle: nil), forCellReuseIdentifier: pickLocationCellIdentifier)
        tableView.rowHeight = 50

        doneButton.enabled = false
        
        mapView.showsUserLocation = true
        mapView.delegate = self

        if let location = YepLocationService.sharedManager.locationManager.location {
            let region = MKCoordinateRegionMakeWithDistance(location.coordinate.yep_applyChinaLocationShift, 1000, 1000)
            mapView.setRegion(region, animated: false)

            self.location = .Default(info: Location.Info(coordinate: location.coordinate.yep_applyChinaLocationShift, name: nil))

            placemarksAroundLocation(location) { [weak self] placemarks in
                self?.userLocationPlacemarks = placemarks.filter({ $0.name != nil })
            }

            foursquareVenuesNearby(coordinate: location.coordinate, failureHandler: nil, completion: { [weak self] venues in
                self?.foursquareVenues = venues
            })

        } else {
            proposeToAccess(.Location(.WhenInUse), agreed: {

                YepLocationService.turnOn()

            }, rejected: {
                self.alertCanNotAccessLocation()
            })

            activityIndicator.startAnimating()
        }

        view.bringSubviewToFront(tableView)
        view.bringSubviewToFront(searchBar)
        view.bringSubviewToFront(activityIndicator)

        let pan = UIPanGestureRecognizer(target: self, action: "pan:")
        mapView.addGestureRecognizer(pan)
        pan.delegate = self
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showNewFeed":

            let vc = segue.destinationViewController as! NewFeedViewController

            let location = (sender as! Box<Location>).value

            vc.attachment = .Location(location)

            vc.preparedSkill = preparedSkill

            vc.afterCreatedFeedAction = afterCreatedFeedAction

        default:
            break
        }
    }

    // MARK: Actions
    
    @IBAction private func cancel(sender: UIBarButtonItem) {

        dismissViewControllerAnimated(true, completion: nil)
    }

    private var fixedCenterCoordinate: CLLocationCoordinate2D {
        return mapView.convertPoint(mapView.center, toCoordinateFromView: mapView)
    }

    @IBAction private func done(sender: UIBarButtonItem) {

        switch purpose {

        case .Message:

            dismissViewControllerAnimated(true, completion: {

                if let sendLocationAction = self.sendLocationAction {

                    if let location = self.location {
                        sendLocationAction(locationInfo: location.info)

                    } else {
                        sendLocationAction(locationInfo: Location.Info(coordinate: self.fixedCenterCoordinate, name: nil))
                    }
                }
            })

        case .Feed:

            if let location = location {
                performSegueWithIdentifier("showNewFeed", sender: Box(location))

            } else {
                let _location = Location.Default(info: Location.Info(coordinate: fixedCenterCoordinate, name: userLocationPlacemarks.first?.yep_autoName))

                performSegueWithIdentifier("showNewFeed", sender: Box(_location))
            }
        }
    }

    @objc private func pan(sender: UIPanGestureRecognizer) {

        if sender.state == .Ended {

            selectedLocationIndexPath = nil
            tableView.reloadData()

            let coordinate = fixedCenterCoordinate

            self.location = .Picked(info: Location.Info(coordinate: coordinate, name: nil))

            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            placemarksAroundLocation(location) { [weak self] placemarks in
                self?.pickedLocationPlacemarks = placemarks.filter({ $0.name != nil })
            }

            foursquareVenuesNearby(coordinate: coordinate.yep_cancelChinaLocationShift, failureHandler: nil, completion: { [weak self] venues in
                self?.foursquareVenues = venues
            })
        }
    }

    private func placemarksAroundLocation(location: CLLocation, completion: [CLPlacemark] -> Void) {

        geocoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in

            if error != nil {
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

    private func reloadTableView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
}

// MARK: - MKMapViewDelegate

extension PickLocationViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }
}

// MARK: - MKMapViewDelegate

extension PickLocationViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {

        guard let location = userLocation.location else {
            return
        }

        if let realLocation = YepLocationService.sharedManager.locationManager.location {

            /*
            println("reallatitude: \(realLocation.coordinate.latitude)")
            println("fakelatitude: \(location.coordinate.latitude)")
            println("reallongitude: \(realLocation.coordinate.longitude)")
            println("fakelongitude: \(location.coordinate.longitude)")
            println("\n")
            */

            let latitudeShift = location.coordinate.latitude - realLocation.coordinate.latitude
            let longitudeShift = location.coordinate.longitude - realLocation.coordinate.longitude

            YepUserDefaults.latitudeShift.value = latitudeShift
            YepUserDefaults.longitudeShift.value = longitudeShift
        }

        activityIndicator.stopAnimating()

        if isFirstShowUserLocation {
            isFirstShowUserLocation = false

            doneButton.enabled = true

            //let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 1000, 1000)
            //mapView.setRegion(region, animated: true)
            mapView.setCenterCoordinate(location.coordinate, animated: true)

            if let _location = self.location {
                if case .Default = _location {
                    self.location = .Default(info: Location.Info(coordinate: location.coordinate, name: nil))
                }
            }

            placemarksAroundLocation(location) { [weak self] placemarks in
                self?.userLocationPlacemarks = placemarks.filter({ $0.name != nil })
            }

            foursquareVenuesNearby(coordinate: location.coordinate.yep_cancelChinaLocationShift, failureHandler: nil, completion: { [weak self] venues in
                self?.foursquareVenues = venues
            })

            mapView.showsUserLocation = false
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
                annotationView.image = UIImage(named: "icon_pin_shadow")
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

    private enum Section: Int {
        case CurrentLocation = 0
        case UserPickedLocation
        case UserLocationPlacemarks
        case SearchedLocation
        case FoursquareVenue
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 5
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch section {
        case Section.CurrentLocation.rawValue:
            return 0
        case Section.UserPickedLocation.rawValue:
            return 0
        case Section.UserLocationPlacemarks.rawValue:
            return 0
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

        case Section.UserLocationPlacemarks.rawValue:
            cell.iconImageView.hidden = true
            let placemark = userLocationPlacemarks[indexPath.row]

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

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

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
                location = .Selected(info: Location.Info(coordinate: _location.coordinate, name: userLocationPlacemarks.first?.yep_autoName ?? NSLocalizedString("My Current Location", comment: "")))
            }

        case Section.UserPickedLocation.rawValue:
            break

        case Section.UserLocationPlacemarks.rawValue:
            let placemark = userLocationPlacemarks[indexPath.row]
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
            mapView.setCenterCoordinate(_location.coordinate, animated: true)

        case Section.FoursquareVenue.rawValue:
            let foursquareVenue = foursquareVenues[indexPath.row]
            let coordinate = foursquareVenue.coordinate.yep_applyChinaLocationShift
            location = .Selected(info: Location.Info(coordinate: coordinate, name: foursquareVenue.name))
            mapView.setCenterCoordinate(coordinate, animated: true)

        default:
            break
        }
    }
}


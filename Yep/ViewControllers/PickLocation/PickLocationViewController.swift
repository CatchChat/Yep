//
//  PickLocationViewController.swift
//  Yep
//
//  Created by NIX on 15/5/4.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import MapKit
import YepKit
import Proposer

final class PickLocationViewController: SegueViewController {

    enum Purpose {
        case message
        case feed
    }
    var purpose: Purpose = .message

    var preparedSkill: Skill?

    var afterCreatedFeedAction: ((_ feed: DiscoveredFeed) -> Void)?

    typealias SendLocationAction = (_ locationInfo: PickLocationViewControllerLocation.Info) -> Void
    var sendLocationAction: SendLocationAction?

    @IBOutlet fileprivate weak var cancelButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var doneButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var mapView: MKMapView!
    @IBOutlet fileprivate weak var pinImageView: UIImageView!
    @IBOutlet fileprivate weak var searchBar: UISearchBar!
    @IBOutlet fileprivate weak var searchBarTopToSuperBottomConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

    fileprivate var isFirstShowUserLocation = true

    fileprivate var searchedMapItems = [MKMapItem]() {
        didSet {
            reloadTableView()
        }
    }

    fileprivate lazy var geocoder = CLGeocoder()

    fileprivate var userLocationPlacemarks = [CLPlacemark]() {
        didSet {
            if let placemark = userLocationPlacemarks.first {
                if let location = self.location {
                    if case .default(let info) = location {
                        var info = info
                        info.name = placemark.yep_autoName
                        self.location = .default(info: info)
                    }
                }
            }

            reloadTableView()
        }
    }

    fileprivate var pickedLocationPlacemarks = [CLPlacemark]() {
        didSet {
            if let placemark = pickedLocationPlacemarks.first {
                if let location = self.location {
                    if case .picked(let info) = location {
                        var info = info
                        info.name = placemark.yep_autoName
                        self.location = .picked(info: info)
                    }
                }
            }

            reloadTableView()
        }
    }

    fileprivate var foursquareVenues = [FoursquareVenue]() {
        didSet {
            reloadTableView()
        }
    }

    fileprivate var location: PickLocationViewControllerLocation? {
        willSet {
            if let _ = newValue {
                doneButton.isEnabled = true
            }
        }
    }

    fileprivate var selectedLocationIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titlePickLocation

        cancelButton.title = String.trans_cancel

        switch purpose {
        case .message:
            doneButton.title = NSLocalizedString("Send", comment: "")
        case .feed:
            doneButton.title = String.trans_buttonNextStep
        }

        searchBar.placeholder = NSLocalizedString("Search", comment: "")

        tableView.registerNibOf(PickLocationCell.self)
        tableView.rowHeight = 50

        doneButton.isEnabled = false
        
        mapView.showsUserLocation = true
        mapView.delegate = self

        if let location = YepLocationService.sharedManager.locationManager.location {
            let region = MKCoordinateRegionMakeWithDistance(location.coordinate.yep_applyChinaLocationShift, 1000, 1000)
            mapView.setRegion(region, animated: false)

            self.location = .default(info: PickLocationViewControllerLocation.Info(coordinate: location.coordinate.yep_applyChinaLocationShift, name: nil))

            placemarksAroundLocation(location) { [weak self] placemarks in
                self?.userLocationPlacemarks = placemarks.filter({ $0.name != nil })
            }

            foursquareVenuesNearby(coordinate: location.coordinate, failureHandler: nil, completion: { [weak self] venues in
                self?.foursquareVenues = venues
            })

        } else {
            proposeToAccess(.location(.whenInUse), agreed: {

                YepLocationService.turnOn()

            }, rejected: {
                self.alertCanNotAccessLocation()
            })

            activityIndicator.startAnimating()
        }

        view.bringSubview(toFront: tableView)
        view.bringSubview(toFront: searchBar)
        view.bringSubview(toFront: activityIndicator)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(PickLocationViewController.pan(_:)))
        mapView.addGestureRecognizer(pan)
        pan.delegate = self
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showNewFeed":

            let vc = segue.destination as! NewFeedViewController

            let location = sender as! PickLocationViewControllerLocation
            vc.attachment = .location(location)

            vc.preparedSkill = preparedSkill

            vc.afterCreatedFeedAction = afterCreatedFeedAction

        default:
            break
        }
    }

    // MARK: Actions
    
    @IBAction fileprivate func cancel(_ sender: UIBarButtonItem) {

        dismiss(animated: true, completion: nil)
    }

    fileprivate var fixedCenterCoordinate: CLLocationCoordinate2D {
        return mapView.convert(mapView.center, toCoordinateFrom: mapView)
    }

    @IBAction fileprivate func done(_ sender: UIBarButtonItem) {

        switch purpose {

        case .message:

            dismiss(animated: true, completion: { [weak self] in

                guard let strongSelf = self else { return }

                if let sendLocationAction = strongSelf.sendLocationAction {

                    if let location = strongSelf.location {
                        sendLocationAction(location.info)

                    } else {
                        sendLocationAction(PickLocationViewControllerLocation.Info(coordinate: strongSelf.fixedCenterCoordinate, name: nil))
                    }
                }
            })

        case .feed:

            let location = self.location ?? PickLocationViewControllerLocation.default(
                info: PickLocationViewControllerLocation.Info(
                    coordinate: fixedCenterCoordinate,
                    name: userLocationPlacemarks.first?.yep_autoName
                )
            )

            performSegue(withIdentifier: "showNewFeed", sender: location)
        }
    }

    @objc fileprivate func pan(_ sender: UIPanGestureRecognizer) {

        if sender.state == .ended {

            selectedLocationIndexPath = nil
            tableView.reloadData()

            let coordinate = fixedCenterCoordinate

            self.location = .picked(info: PickLocationViewControllerLocation.Info(coordinate: coordinate, name: nil))

            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            placemarksAroundLocation(location) { [weak self] placemarks in
                self?.pickedLocationPlacemarks = placemarks.filter({ $0.name != nil })
            }

            foursquareVenuesNearby(coordinate: coordinate.yep_cancelChinaLocationShift, failureHandler: nil, completion: { [weak self] venues in
                self?.foursquareVenues = venues
            })
        }
    }

    fileprivate func placemarksAroundLocation(_ location: CLLocation, completion: @escaping ([CLPlacemark]) -> Void) {

        geocoder.reverseGeocodeLocation(location) { placemarks, error in

            if let error = error {
                println("reverse geodcode fail: \(error)")
            }

            completion(placemarks ?? [])
        }
    }

    fileprivate func reloadTableView() {

        SafeDispatch.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

// MARK: - MKMapViewDelegate

extension PickLocationViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }
}

// MARK: - MKMapViewDelegate

extension PickLocationViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {

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

            doneButton.isEnabled = true

            //let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 1000, 1000)
            //mapView.setRegion(region, animated: true)
            mapView.setCenter(location.coordinate, animated: true)

            if let _location = self.location {
                if case .default = _location {
                    self.location = .default(info: PickLocationViewControllerLocation.Info(coordinate: location.coordinate, name: nil))
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

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        if let annotation = annotation as? LocationPin {

            let identifier = "LocationPinView"

            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                annotationView.annotation = annotation

                return annotationView

            } else {
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView.image = UIImage.yep_iconPinShadow
                annotationView.isEnabled = false
                annotationView.canShowCallout = false

                return annotationView
            }
        }

        return nil
    }
}

// MARK: - UISearchBarDelegate

extension PickLocationViewController: UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {

        navigationController?.setNavigationBarHidden(true, animated: true)

        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.searchBarTopToSuperBottomConstraint.constant = strongSelf.view.bounds.height - 20
            strongSelf.view.layoutIfNeeded()

        }, completion: { [weak self] _ in
            self?.searchBar.setShowsCancelButton(true, animated: true)
        })

        return true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        shrinkSearchLocationView()
    }

    func shrinkSearchLocationView() {
        searchBar.resignFirstResponder()

        navigationController?.setNavigationBarHidden(false, animated: true)

        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: { [weak self] in
            self?.searchBarTopToSuperBottomConstraint.constant = 250
            self?.view.layoutIfNeeded()

        }, completion: { [weak self] _ in
            self?.searchBar.setShowsCancelButton(false, animated: true)
        })
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        guard let name = searchBar.text else {
            return
        }

        searchPlacesByName(name)

        shrinkSearchLocationView()
    }

    fileprivate func searchPlacesByName(_ name: String, needAppend: Bool = false) {

        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = name

        if let location = mapView.userLocation.location {
            request.region = MKCoordinateRegionMakeWithDistance(location.coordinate, 200000, 200000)
        }

        let search = MKLocalSearch(request: request)

        search.start { [weak self] response, error in
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

    fileprivate enum Section: Int {
        case currentLocation = 0
        case userPickedLocation
        case userLocationPlacemarks
        case searchedLocation
        case foursquareVenue
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch section {
        case Section.currentLocation.rawValue:
            return 0
        case Section.userPickedLocation.rawValue:
            return 0
        case Section.userLocationPlacemarks.rawValue:
            return 0
        case Section.searchedLocation.rawValue:
            return searchedMapItems.count
        case Section.foursquareVenue.rawValue:
            return foursquareVenues.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: PickLocationCell = tableView.dequeueReusableCell()

        switch indexPath.section {

        case Section.currentLocation.rawValue:
            cell.iconImageView.isHidden = false
            cell.iconImageView.image = UIImage.yep_iconCurrentLocation
            cell.locationLabel.text = String.trans_titleMyCurrentLocation
            cell.checkImageView.isHidden = false

        case Section.userPickedLocation.rawValue:
            cell.iconImageView.isHidden = false
            cell.iconImageView.image = UIImage.yep_iconPin
            cell.locationLabel.text = NSLocalizedString("Picked Location", comment: "")
            cell.checkImageView.isHidden = true

        case Section.userLocationPlacemarks.rawValue:
            cell.iconImageView.isHidden = true
            let placemark = userLocationPlacemarks[indexPath.row]

            let text = placemark.name ?? "🐌"

            cell.locationLabel.text = text

            cell.checkImageView.isHidden = true

        case Section.searchedLocation.rawValue:
            cell.iconImageView.isHidden = false
            cell.iconImageView.image = UIImage.yep_iconPin

            let placemark = searchedMapItems[indexPath.row].placemark
            cell.locationLabel.text = placemark.name

            cell.checkImageView.isHidden = true

        case Section.foursquareVenue.rawValue:
            cell.iconImageView.isHidden = false
            cell.iconImageView.image = UIImage.yep_iconPin

            let foursquareVenue = foursquareVenues[indexPath.row]
            cell.locationLabel.text = foursquareVenue.name

            cell.checkImageView.isHidden = true

        default:
            break
        }

        if let pickLocationIndexPath = selectedLocationIndexPath {
            cell.checkImageView.isHidden = !(pickLocationIndexPath == indexPath)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        if let selectedLocationIndexPath = selectedLocationIndexPath {
            if let cell = tableView.cellForRow(at: selectedLocationIndexPath) as? PickLocationCell {
                cell.checkImageView.isHidden = true
            }

        } else {
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.currentLocation.rawValue)) as? PickLocationCell {
                cell.checkImageView.isHidden = true
            }
        }

        if let cell = tableView.cellForRow(at: indexPath) as? PickLocationCell {
            cell.checkImageView.isHidden = false
        }

        selectedLocationIndexPath = indexPath

        switch indexPath.section {

        case Section.currentLocation.rawValue:
            if let _location = mapView.userLocation.location {
                location = .selected(info: PickLocationViewControllerLocation.Info(coordinate: _location.coordinate, name: userLocationPlacemarks.first?.yep_autoName ?? String.trans_titleMyCurrentLocation))
            }

        case Section.userPickedLocation.rawValue:
            break

        case Section.userLocationPlacemarks.rawValue:
            let placemark = userLocationPlacemarks[indexPath.row]
            guard let _location = placemark.location else {
                break
            }
            location = .selected(info: PickLocationViewControllerLocation.Info(coordinate: _location.coordinate, name: placemark.name))

        case Section.searchedLocation.rawValue:
            let placemark = self.searchedMapItems[indexPath.row].placemark
            guard let _location = placemark.location else {
                break
            }
            location = .selected(info: PickLocationViewControllerLocation.Info(coordinate: _location.coordinate, name: placemark.name))
            mapView.setCenter(_location.coordinate, animated: true)

        case Section.foursquareVenue.rawValue:
            let foursquareVenue = foursquareVenues[indexPath.row]
            let coordinate = foursquareVenue.coordinate.yep_applyChinaLocationShift
            location = .selected(info: PickLocationViewControllerLocation.Info(coordinate: coordinate, name: foursquareVenue.name))
            mapView.setCenter(coordinate, animated: true)

        default:
            break
        }
    }
}


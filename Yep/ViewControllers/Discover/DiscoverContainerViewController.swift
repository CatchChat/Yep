//
//  DiscoverContainerViewController.swift
//  Yep
//
//  Created by NIX on 16/5/26.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

class DiscoverContainerViewController: UIViewController {

    enum Option: Int {
        case MeetGenius
        case FindAll

        var title: String {
            switch self {
            case .MeetGenius:
                return NSLocalizedString("Meet Genius", comment: "")
            case .FindAll:
                return NSLocalizedString("Find All", comment: "")
            }
        }
    }
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.removeAllSegments()
            (0..<2).forEach({
                let option = Option(rawValue: $0)
                segmentedControl.insertSegmentWithTitle(option?.title, atIndex: $0, animated: false)
            })
        }
    }

    @IBOutlet weak var geniusesContainerView: UIView!
    @IBOutlet weak var discoveredUsersContainerView: UIView!

    private weak var discoverViewController: DiscoverViewController?
    private var discoveredUsersLayoutMode: DiscoverFlowLayout.Mode = .Card {
        didSet {
            switch discoveredUsersLayoutMode {

            case .Card:
                view.backgroundColor = UIColor.yepBackgroundColor()
                discoveredUsersLayoutModeButtonItem.image = UIImage(named: "icon_list")

            case .Normal:
                view.backgroundColor = UIColor.whiteColor()
                discoveredUsersLayoutModeButtonItem.image = UIImage(named: "icon_minicard")
            }
        }
    }
    lazy var discoveredUsersLayoutModeButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: UIImage(named:"icon_list"),
            style: .Plain,
            target: self,
            action: #selector(DiscoverContainerViewController.tapDiscoveredUsersLayoutModeButtonItem(_:))
        )
        return item
    }()
    private var discoveredUserSortStyle: DiscoveredUserSortStyle = .Default {
        didSet {
            discoveredUsersFilterButtonItem.title = discoveredUserSortStyle.nameWithArrow
        }
    }
    lazy var discoveredUsersFilterButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            title: "NIX",
            style: .Plain,
            target: self,
            action: #selector(DiscoverContainerViewController.tapDiscoveredUsersFilterButtonItem(_:))
        )
        return item
    }()

    var currentOption: Option = .MeetGenius {
        didSet {
            switch currentOption {

            case .MeetGenius:
                geniusesContainerView.hidden = false
                discoveredUsersContainerView.hidden = true

                navigationItem.leftBarButtonItem = nil
                navigationItem.rightBarButtonItem = nil

            case .FindAll:
                geniusesContainerView.hidden = true
                discoveredUsersContainerView.hidden = false

                //navigationItem.leftBarButtonItem = discoveredUsersLayoutModeButtonItem
                navigationItem.rightBarButtonItem = discoveredUsersFilterButtonItem
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //navigationItem.titleView = nil
        //navigationItem.title = NSLocalizedString("Discover", comment: "")

        currentOption = .MeetGenius

        segmentedControl.selectedSegmentIndex = currentOption.rawValue
        segmentedControl.addTarget(self, action: #selector(DiscoverContainerViewController.chooseOption(_:)), forControlEvents: .ValueChanged)

        if let
            value = YepUserDefaults.discoveredUserSortStyle.value,
            _discoveredUserSortStyle = DiscoveredUserSortStyle(rawValue: value) {

            discoveredUserSortStyle = _discoveredUserSortStyle

        } else {
            discoveredUserSortStyle = .Default
        }

        if traitCollection.forceTouchCapability == .Available {
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
    }

    // MARK: - Actions

    @objc private func chooseOption(sender: UISegmentedControl) {

        guard let option = Option(rawValue: sender.selectedSegmentIndex) else {
            return
        }

        currentOption = option
    }

    @objc private func tapDiscoveredUsersLayoutModeButtonItem(sender: UIBarButtonItem) {

        discoverViewController?.changeLayoutMode()
    }

    @objc private func tapDiscoveredUsersFilterButtonItem(sender: UIBarButtonItem) {

        discoverViewController?.showFilters()
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "embedMeetGenius":

            let vc = segue.destinationViewController as! MeetGeniusViewController

            vc.tapBannerAction = { [weak self] url in
                self?.yep_openURL(url)
            }

            vc.showGeniusInterviewAction = { geniusInterview in
                SafeDispatch.async { [weak self] in
                    self?.performSegueWithIdentifier("showGeniusInterview", sender: Box<GeniusInterview>(geniusInterview))
                }
            }

        case "embedDiscover":

            let vc = segue.destinationViewController as! DiscoverViewController

            vc.showProfileOfDiscoveredUserAction = { discoveredUser in
                SafeDispatch.async { [weak self] in
                    self?.performSegueWithIdentifier("showProfile", sender: Box<DiscoveredUser>(discoveredUser))
                }
            }

            discoverViewController = vc

            vc.didChangeLayoutModeAction = { [weak self] layoutMode in
                self?.discoveredUsersLayoutMode = layoutMode
            }

            vc.didChangeSortStyleAction = { [weak self] sortStyle in
                self?.discoveredUserSortStyle = sortStyle
            }

        case "showProfile":

            let vc = segue.destinationViewController as! ProfileViewController
            let discoveredUser = (sender as! Box<DiscoveredUser>).value
            vc.prepare(withDiscoveredUser: discoveredUser)

        case "showGeniusInterview":

            let vc = segue.destinationViewController as! GeniusInterviewViewController

            let geniusInterview = (sender as! Box<GeniusInterview>).value
            vc.geniusInterview = geniusInterview

        default:
            break
        }
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension DiscoverContainerViewController: UIViewControllerPreviewingDelegate {

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard case .FindAll = currentOption else {
            return nil
        }

        guard let discoveredUsersCollectionView = discoverViewController?.discoveredUsersCollectionView else {
            return nil
        }

        let fixedLocation = view.convertPoint(location, toView: discoveredUsersCollectionView)

        guard let indexPath = discoveredUsersCollectionView.indexPathForItemAtPoint(fixedLocation), cell = discoveredUsersCollectionView.cellForItemAtIndexPath(indexPath) else {
            return nil
        }

        previewingContext.sourceRect = cell.frame

        let vc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("ProfileViewController") as! ProfileViewController

        guard let discoveredUser = discoverViewController?.discoveredUsers[indexPath.row] else {
            return nil
        }

        vc.prepare(withDiscoveredUser: discoveredUser)

        return vc
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {

        showViewController(viewControllerToCommit, sender: self)
    }
}


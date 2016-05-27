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

                navigationItem.rightBarButtonItem = nil

            case .FindAll:
                geniusesContainerView.hidden = true
                discoveredUsersContainerView.hidden = false

                navigationItem.rightBarButtonItem = discoveredUsersFilterButtonItem
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
    }

    // MARK: - Actions

    @objc private func chooseOption(sender: UISegmentedControl) {

        guard let option = Option(rawValue: sender.selectedSegmentIndex) else {
            return
        }

        currentOption = option
    }

    @objc private func tapDiscoveredUsersFilterButtonItem(sender: UIBarButtonItem) {

        discoverViewController?.showFilters(sender)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "embedDiscover":

            let vc = segue.destinationViewController as! DiscoverViewController

            vc.showProfileOfDiscoveredUserAction = { discoveredUser in
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.performSegueWithIdentifier("showProfile", sender: Box<DiscoveredUser>(discoveredUser))
                }
            }

            discoverViewController = vc

        case "showProfile":

            let discoveredUser = (sender as! Box<DiscoveredUser>).value

            let vc = segue.destinationViewController as! ProfileViewController

            if discoveredUser.id != YepUserDefaults.userID.value {
                vc.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
            }

            vc.setBackButtonWithTitle()

            vc.hidesBottomBarWhenPushed = true

        default:
            break
        }
    }
}


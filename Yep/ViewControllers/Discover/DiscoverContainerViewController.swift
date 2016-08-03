//
//  DiscoverContainerViewController.swift
//  Yep
//
//  Created by NIX on 16/5/26.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RxSwift
import RxCocoa

class DiscoverContainerViewController: UIPageViewController {

    private lazy var disposeBag = DisposeBag()

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

    private lazy var meetGeniusViewController: MeetGeniusViewController = {

        let vc = UIStoryboard(name: "Discover", bundle: nil).instantiateViewControllerWithIdentifier("MeetGeniusViewController") as! MeetGeniusViewController

        vc.tapBannerAction = { [weak self] banner in
            SafeDispatch.async { [weak self] in
                self?.performSegueWithIdentifier("showGeniusInterviewWithBanner", sender: Box<GeniusInterviewBanner>(banner))
            }
        }

        vc.showGeniusInterviewAction = { geniusInterview in
            SafeDispatch.async { [weak self] in
                self?.performSegueWithIdentifier("showGeniusInterview", sender: Box<GeniusInterview>(geniusInterview))
            }
        }

        return vc
    }()

    private lazy var discoverViewController: DiscoverViewController = {

        let vc = UIStoryboard(name: "Discover", bundle: nil).instantiateViewControllerWithIdentifier("DiscoverViewController") as! DiscoverViewController

        vc.showProfileOfDiscoveredUserAction = { discoveredUser in
            SafeDispatch.async { [weak self] in
                self?.performSegueWithIdentifier("showProfile", sender: Box<DiscoveredUser>(discoveredUser))
            }
        }

        vc.didChangeLayoutModeAction = { [weak self] layoutMode in
            self?.discoveredUsersLayoutMode = layoutMode
        }

        vc.didChangeSortStyleAction = { [weak self] sortStyle in
            self?.discoveredUserSortStyle = sortStyle
        }

        return vc
    }()

    private lazy var discoveredUsersLayoutModeButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem()
        item.image = UIImage(named:"icon_list")
        item.rx_tap
            .subscribeNext({ [weak self] in self?.discoverViewController.changeLayoutMode() })
            .addDisposableTo(self.disposeBag)
        return item
    }()

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

    private lazy var discoveredUsersFilterButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem()
        item.rx_tap
            .subscribeNext({ [weak self] in self?.discoverViewController.showFilters() })
            .addDisposableTo(self.disposeBag)
        return item
    }()

    private var discoveredUserSortStyle: DiscoveredUserSortStyle = .Default {
        willSet {
            SafeDispatch.async {
                UIView.performWithoutAnimation { [weak self] in
                    self?.discoveredUsersFilterButtonItem.title = newValue.nameWithArrow
                }
            }
        }
    }

    var currentOption: Option = .MeetGenius {
        didSet {
            switch currentOption {

            case .MeetGenius:
                //geniusesContainerView.hidden = false
                //discoveredUsersContainerView.hidden = true
                setViewControllers([meetGeniusViewController], direction: .Reverse, animated: true, completion: nil)

                navigationItem.leftBarButtonItem = nil
                navigationItem.rightBarButtonItem = nil

            case .FindAll:
                //geniusesContainerView.hidden = true
                //discoveredUsersContainerView.hidden = false
                setViewControllers([discoverViewController], direction: .Forward, animated: true, completion: nil)

                //navigationItem.leftBarButtonItem = discoveredUsersLayoutModeButtonItem
                navigationItem.rightBarButtonItem = discoveredUsersFilterButtonItem
            }
        }
    }

//    func setViewControllerForIndex(index: Int) {
//        let viewControllers = [index == 0 ? meetGeniusViewController : discoverViewController]
//        setViewControllers(viewControllers, direction: .Forward, animated: true, completion: nil)
//    }

    override func viewDidLoad() {
        super.viewDidLoad()

        currentOption = .MeetGenius

        segmentedControl.selectedSegmentIndex = currentOption.rawValue

        segmentedControl.rx_value
            .map({ Option(rawValue: $0) })
            .subscribeNext({ [weak self] in self?.currentOption = $0 ?? .MeetGenius })
            .addDisposableTo(disposeBag)

        if let
            value = YepUserDefaults.discoveredUserSortStyle.value,
            _discoveredUserSortStyle = DiscoveredUserSortStyle(rawValue: value) {

            discoveredUserSortStyle = _discoveredUserSortStyle

        } else {
            discoveredUserSortStyle = .Default
        }

        self.dataSource = self

        if traitCollection.forceTouchCapability == .Available {
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

            /*
        case "embedMeetGenius":

            let vc = segue.destinationViewController as! MeetGeniusViewController

            self.meetGeniusViewController = vc

            vc.tapBannerAction = { [weak self] banner in
                SafeDispatch.async { [weak self] in
                    self?.performSegueWithIdentifier("showGeniusInterviewWithBanner", sender: Box<GeniusInterviewBanner>(banner))
                }
            }

            vc.showGeniusInterviewAction = { geniusInterview in
                SafeDispatch.async { [weak self] in
                    self?.performSegueWithIdentifier("showGeniusInterview", sender: Box<GeniusInterview>(geniusInterview))
                }
            }

        case "embedDiscover":

            let vc = segue.destinationViewController as! DiscoverViewController

            self.discoverViewController = vc

            vc.showProfileOfDiscoveredUserAction = { discoveredUser in
                SafeDispatch.async { [weak self] in
                    self?.performSegueWithIdentifier("showProfile", sender: Box<DiscoveredUser>(discoveredUser))
                }
            }

            vc.didChangeLayoutModeAction = { [weak self] layoutMode in
                self?.discoveredUsersLayoutMode = layoutMode
            }

            vc.didChangeSortStyleAction = { [weak self] sortStyle in
                self?.discoveredUserSortStyle = sortStyle
            }
             */

        case "showProfile":

            let vc = segue.destinationViewController as! ProfileViewController
            let discoveredUser = (sender as! Box<DiscoveredUser>).value
            vc.prepare(withDiscoveredUser: discoveredUser)

        case "showGeniusInterview":

            let vc = segue.destinationViewController as! GeniusInterviewViewController

            let geniusInterview = (sender as! Box<GeniusInterview>).value
            vc.interview = geniusInterview

        case "showGeniusInterviewWithBanner":

            let vc = segue.destinationViewController as! GeniusInterviewViewController

            let banner = (sender as! Box<GeniusInterviewBanner>).value
            vc.interview = banner

        default:
            break
        }
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension DiscoverContainerViewController: UIPageViewControllerDataSource {

    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {

        if viewController == discoverViewController {
            return meetGeniusViewController
        }

        return nil
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {

        if viewController == meetGeniusViewController {
            return discoverViewController
        }
        
        return nil
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension DiscoverContainerViewController: UIViewControllerPreviewingDelegate {

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        switch currentOption {

        case .MeetGenius:

            guard let tableView = meetGeniusViewController.tableView else {
                return nil
            }

            let fixedLocation = view.convertPoint(location, toView: tableView)

            guard let indexPath = tableView.indexPathForRowAtPoint(fixedLocation), cell = tableView.cellForRowAtIndexPath(indexPath) else {
                return nil
            }

            previewingContext.sourceRect = cell.frame

            let vc = UIStoryboard(name: "GeniusInterview", bundle: nil).instantiateViewControllerWithIdentifier("GeniusInterviewViewController") as! GeniusInterviewViewController

            let geniusInterview = meetGeniusViewController.geniusInterviews[indexPath.row]
            vc.interview = geniusInterview

            return vc

        case .FindAll:

            guard let discoveredUsersCollectionView = discoverViewController.discoveredUsersCollectionView else {
                return nil
            }

            let fixedLocation = view.convertPoint(location, toView: discoveredUsersCollectionView)

            guard let indexPath = discoveredUsersCollectionView.indexPathForItemAtPoint(fixedLocation), cell = discoveredUsersCollectionView.cellForItemAtIndexPath(indexPath) else {
                return nil
            }

            previewingContext.sourceRect = cell.frame

            let vc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("ProfileViewController") as! ProfileViewController

            let discoveredUser = discoverViewController.discoveredUsers[indexPath.item]
            vc.prepare(withDiscoveredUser: discoveredUser)

            return vc
        }
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {

        showViewController(viewControllerToCommit, sender: self)
    }
}


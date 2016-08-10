//
//  DiscoverContainerViewController.swift
//  Yep
//
//  Created by NIX on 16/5/26.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Ruler
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

            let font = UIFont.systemFontOfSize(Ruler.iPhoneHorizontal(13, 14, 15).value)
            let padding: CGFloat = Ruler.iPhoneHorizontal(6, 11, 12).value
            segmentedControl.yep_setTitleFont(font, withPadding: padding)
        }
    }

    private lazy var meetGeniusViewController: MeetGeniusViewController = {

        let vc = UIStoryboard.Scene.meetGenius

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

        let vc = UIStoryboard.Scene.discover

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
        item.image = UIImage.yep_iconList
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
                discoveredUsersLayoutModeButtonItem.image = UIImage.yep_iconList

            case .Normal:
                view.backgroundColor = UIColor.whiteColor()
                discoveredUsersLayoutModeButtonItem.image = UIImage.yep_iconMinicard
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
                setViewControllers([meetGeniusViewController], direction: .Reverse, animated: true, completion: nil)

                navigationItem.leftBarButtonItem = nil
                navigationItem.rightBarButtonItem = nil

            case .FindAll:
                setViewControllers([discoverViewController], direction: .Forward, animated: true, completion: nil)

                //navigationItem.leftBarButtonItem = discoveredUsersLayoutModeButtonItem
                navigationItem.rightBarButtonItem = discoveredUsersFilterButtonItem
            }
        }
    }

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
        self.delegate = self

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

// MARK: - UIPageViewControllerDelegate

extension DiscoverContainerViewController: UIPageViewControllerDelegate {

    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

        guard completed else {
            return
        }

        if previousViewControllers.first == meetGeniusViewController {
            currentOption = .FindAll
        } else if previousViewControllers.first == discoverViewController {
            currentOption = .MeetGenius
        }
        segmentedControl.selectedSegmentIndex = currentOption.rawValue
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

            let vc = UIStoryboard.Scene.geniusInterview
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

            let vc = UIStoryboard.Scene.profile

            let discoveredUser = discoverViewController.discoveredUsers[indexPath.item]
            vc.prepare(withDiscoveredUser: discoveredUser)

            return vc
        }
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {

        showViewController(viewControllerToCommit, sender: self)
    }
}


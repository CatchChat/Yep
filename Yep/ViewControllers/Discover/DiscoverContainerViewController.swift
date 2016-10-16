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

class DiscoverContainerViewController: UIPageViewController, CanScrollsToTop {

    // CanScrollsToTop
    var scrollView: UIScrollView? {
        return (viewControllers?.first as? CanScrollsToTop)?.scrollView
    }

    fileprivate lazy var disposeBag = DisposeBag()

    enum Option: Int {
        case meetGenius
        case findAll

        static let count = 2

        var title: String {
            switch self {
            case .meetGenius:
                return String.trans_titleMeetGeniuses
            case .findAll:
                return String.trans_titleFindAll
            }
        }
    }
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.removeAllSegments()
            (0..<Option.count).forEach({
                let option = Option(rawValue: $0)
                segmentedControl.insertSegment(withTitle: option?.title, at: $0, animated: false)
            })

            let font = UIFont.systemFont(ofSize: Ruler.iPhoneHorizontal(13, 14, 15).value)
            let padding: CGFloat = Ruler.iPhoneHorizontal(8, 11, 12).value
            segmentedControl.yep_setTitleFont(font, withPadding: padding)
        }
    }

    fileprivate lazy var meetGeniusViewController: MeetGeniusViewController = {

        let vc = UIStoryboard.Scene.meetGenius

        vc.tapBannerAction = { banner in
            SafeDispatch.async { [weak self] in
                self?.performSegue(withIdentifier: "showGeniusInterviewWithBanner", sender: banner)
            }
        }

        vc.showGeniusInterviewAction = { geniusInterview in
            SafeDispatch.async { [weak self] in
                self?.performSegue(withIdentifier: "showGeniusInterview", sender: geniusInterview)
            }
        }

        return vc
    }()

    fileprivate lazy var discoverViewController: DiscoverViewController = {

        let vc = UIStoryboard.Scene.discover

        vc.showProfileOfDiscoveredUserAction = { discoveredUser in
            SafeDispatch.async { [weak self] in
                self?.performSegue(withIdentifier: "showProfile", sender: discoveredUser)
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

    fileprivate lazy var discoveredUsersLayoutModeButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem()
        item.image = UIImage.yep_iconList
        item.rx.tap
            .subscribe(onNext: { [weak self] in self?.discoverViewController.changeLayoutMode() })
            .addDisposableTo(self.disposeBag)
        return item
    }()

    fileprivate var discoveredUsersLayoutMode: DiscoverFlowLayout.Mode = .card {
        didSet {
            switch discoveredUsersLayoutMode {

            case .card:
                view.backgroundColor = UIColor.yepBackgroundColor()
                discoveredUsersLayoutModeButtonItem.image = UIImage.yep_iconList

            case .normal:
                view.backgroundColor = UIColor.white
                discoveredUsersLayoutModeButtonItem.image = UIImage.yep_iconMinicard
            }
        }
    }

    fileprivate lazy var discoveredUsersFilterButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem()
        item.rx.tap
            .subscribe(onNext: { [weak self] in self?.discoverViewController.showFilters() })
            .addDisposableTo(self.disposeBag)
        return item
    }()

    fileprivate var discoveredUserSortStyle: DiscoveredUserSortStyle = .default {
        willSet {
            SafeDispatch.async {
                UIView.performWithoutAnimation { [weak self] in
                    self?.discoveredUsersFilterButtonItem.title = newValue.nameWithArrow
                }
            }
        }
    }

    var currentOption: Option = .meetGenius {
        didSet {
            switch currentOption {

            case .meetGenius:
                setViewControllers([meetGeniusViewController], direction: .reverse, animated: true, completion: nil)

                navigationItem.leftBarButtonItem = nil
                navigationItem.rightBarButtonItem = nil

            case .findAll:
                setViewControllers([discoverViewController], direction: .forward, animated: true, completion: nil)

                //navigationItem.leftBarButtonItem = discoveredUsersLayoutModeButtonItem
                navigationItem.rightBarButtonItem = discoveredUsersFilterButtonItem
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        currentOption = .meetGenius
        segmentedControl.selectedSegmentIndex = currentOption.rawValue

        segmentedControl.rx.value
            .map({ Option(rawValue: $0) })
            .subscribe(onNext: { [weak self] in self?.currentOption = $0 ?? .meetGenius })
            .addDisposableTo(disposeBag)

        if let
            value = YepUserDefaults.discoveredUserSortStyle.value,
            let _discoveredUserSortStyle = DiscoveredUserSortStyle(rawValue: value) {

            discoveredUserSortStyle = _discoveredUserSortStyle

        } else {
            discoveredUserSortStyle = .default
        }

        self.dataSource = self
        self.delegate = self

        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showProfile":

            let vc = segue.destination as! ProfileViewController
            let discoveredUser = sender as! DiscoveredUser
            vc.prepare(with: discoveredUser)

        case "showGeniusInterview":

            let vc = segue.destination as! GeniusInterviewViewController
            let geniusInterview = sender as! GeniusInterview
            vc.interview = geniusInterview

        case "showGeniusInterviewWithBanner":

            let vc = segue.destination as! GeniusInterviewViewController
            let banner = sender as! GeniusInterviewBanner
            vc.interview = banner

        default:
            break
        }
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension DiscoverContainerViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

        if viewController == discoverViewController {
            return meetGeniusViewController
        }

        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {

        if viewController == meetGeniusViewController {
            return discoverViewController
        }
        
        return nil
    }
}

// MARK: - UIPageViewControllerDelegate

extension DiscoverContainerViewController: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

        guard completed else {
            return
        }

        if previousViewControllers.first == meetGeniusViewController {
            currentOption = .findAll
        } else if previousViewControllers.first == discoverViewController {
            currentOption = .meetGenius
        }
        segmentedControl.selectedSegmentIndex = currentOption.rawValue
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension DiscoverContainerViewController: UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        switch currentOption {

        case .meetGenius:

            let tableView = meetGeniusViewController.interviewsTableView

            let fixedLocation = view.convert(location, to: tableView)

            guard let indexPath = tableView.indexPathForRow(at: fixedLocation), let cell = tableView.cellForRow(at: indexPath) else {
                return nil
            }

            previewingContext.sourceRect = cell.frame

            let vc = UIStoryboard.Scene.geniusInterview
            let geniusInterview = meetGeniusViewController.geniusInterviewAtIndexPath(indexPath)
            vc.interview = geniusInterview

            return vc

        case .findAll:

            let collectionView = discoverViewController.collectionView

            let fixedLocation = view.convert(location, to: collectionView)

            guard let indexPath = collectionView.indexPathForItem(at: fixedLocation), let cell = collectionView.cellForItem(at: indexPath) else {
                return nil
            }

            previewingContext.sourceRect = cell.frame

            let vc = UIStoryboard.Scene.profile

            let discoveredUser = discoverViewController.discoveredUserAtIndexPath(indexPath)
            vc.prepare(with: discoveredUser)

            return vc
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {

        show(viewControllerToCommit, sender: self)
    }
}


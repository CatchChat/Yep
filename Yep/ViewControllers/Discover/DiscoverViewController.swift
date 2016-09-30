//
//  DiscoverViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import YepKit

var skillSizeCache = [String: CGRect]()

final class DiscoverViewController: BaseViewController, CanScrollsToTop {

    var showProfileOfDiscoveredUserAction: ((_ discoveredUser: DiscoveredUser) -> Void)?
    var didChangeLayoutModeAction: ((_ layoutMode: DiscoverFlowLayout.Mode) -> Void)?
    var didChangeSortStyleAction: ((_ sortStyle: DiscoveredUserSortStyle) -> Void)?

    @IBOutlet fileprivate weak var discoveredUsersCollectionView: DiscoverCollectionView!

    var collectionView: UICollectionView {
        return discoveredUsersCollectionView
    }

    // CanScrollsToTop
    var scrollView: UIScrollView? {
        return discoveredUsersCollectionView
    }

    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

    fileprivate var layoutMode: DiscoverFlowLayout.Mode = .card {
        didSet {
            didChangeLayoutModeAction?(layoutMode)

            layout.mode = layoutMode
            SafeDispatch.async { [weak self] in
                self?.discoveredUsersCollectionView.reloadData()
            }
        }
    }
    
    fileprivate let layout = DiscoverFlowLayout()
    
    fileprivate let refreshControl = UIRefreshControl()

    fileprivate var discoveredUserSortStyle: DiscoveredUserSortStyle = .Default {
        didSet {
            didChangeSortStyleAction?(discoveredUserSortStyle)

            discoveredUsers = []
            SafeDispatch.async { [weak self] in
                self?.discoveredUsersCollectionView.reloadData()
            }

            updateDiscoverUsers(mode: .static)

            // save discoveredUserSortStyle
            YepUserDefaults.discoveredUserSortStyle.value = discoveredUserSortStyle.rawValue
        }
    }

    fileprivate var discoveredUsers = [DiscoveredUser]()

    func discoveredUserAtIndexPath(_ indexPath: IndexPath) -> DiscoveredUser {
        return discoveredUsers[indexPath.item]
    }

    fileprivate lazy var filterStyles: [DiscoveredUserSortStyle] = [
        .Distance,
        .LastSignIn,
        .Default,
    ]

    fileprivate func filterItemWithSortStyle(_ sortStyle: DiscoveredUserSortStyle, currentSortStyle: DiscoveredUserSortStyle) -> ActionSheetView.Item {
        return .check(
            title: sortStyle.name,
            titleColor: UIColor.yepTintColor(),
            checked: sortStyle == currentSortStyle,
            action: { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.discoveredUserSortStyle = sortStyle
                strongSelf.filterView.items = strongSelf.filterItemsWithCurrentSortStyle(strongSelf.discoveredUserSortStyle)
                strongSelf.filterView.refreshItems()
            }
        )
    }

    fileprivate func filterItemsWithCurrentSortStyle(_ currentSortStyle: DiscoveredUserSortStyle) -> [ActionSheetView.Item] {
        var items = filterStyles.map({
           filterItemWithSortStyle($0, currentSortStyle: currentSortStyle)
        })
        items.append(.cancel)
        return items
    }

    fileprivate lazy var filterView: ActionSheetView = {
        let view = ActionSheetView(items: self.filterItemsWithCurrentSortStyle(self.discoveredUserSortStyle))
        return view
    }()

    #if DEBUG
    private lazy var discoverFPSLabel: FPSLabel = {
        let label = FPSLabel()
        return label
    }()
    #endif

    deinit {
        println("deinit Discover")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshControl.endRefreshing()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleDiscover

        view.backgroundColor = UIColor.white

        // recover discoveredUserSortStyle if can

        if let
            value = YepUserDefaults.discoveredUserSortStyle.value,
            let _discoveredUserSortStyle = DiscoveredUserSortStyle(rawValue: value) {

                discoveredUserSortStyle = _discoveredUserSortStyle

        } else {
            discoveredUserSortStyle = .Default
        }

        discoveredUsersCollectionView.backgroundColor = UIColor.clear
        discoveredUsersCollectionView.setCollectionViewLayout(layout, animated: false)
        discoveredUsersCollectionView.delegate = self
        discoveredUsersCollectionView.dataSource = self

        discoveredUsersCollectionView.registerNibOf(DiscoverNormalUserCell.self)
        discoveredUsersCollectionView.registerNibOf(DiscoverCardUserCell.self)
        discoveredUsersCollectionView.registerNibOf(LoadMoreCollectionViewCell.self)

        layoutMode = .card

        if let realm = try? Realm(), let offlineJSON = OfflineJSON.withName(.discoveredUsers, inRealm: realm) {
            if let JSON = offlineJSON.JSON, let discoveredUsers = parseDiscoveredUsers(JSON) {
                self.discoveredUsers = discoveredUsers
                activityIndicator.stopAnimating()
            }
        }

        refreshControl.tintColor = UIColor.lightGray
        refreshControl.addTarget(self, action: #selector(DiscoverViewController.refresh(_:)), for: .valueChanged)
        refreshControl.layer.zPosition = -1 // Make Sure Indicator below the Cells
        discoveredUsersCollectionView.addSubview(refreshControl)

        #if DEBUG
            //view.addSubview(discoverFPSLabel)
        #endif
    }

    // MARK: Actions

    @objc fileprivate func refresh(_ sender: UIRefreshControl) {

        updateDiscoverUsers(mode: .topRefresh) {
            SafeDispatch.async {
                sender.endRefreshing()
            }
        }
    }

    func changeLayoutMode() {

        switch layoutMode {
            
        case .card:
            layoutMode = .normal

        case .normal:
            layoutMode = .card
        }
    }

    func showFilters() {

        if let window = view.window {
            filterView.showInView(window)
        }
    }

    fileprivate var currentPageIndex = 1
    fileprivate var isFetching = false
    fileprivate enum UpdateMode {
        case `static`
        case topRefresh
        case loadMore
    }
    fileprivate func updateDiscoverUsers(mode: UpdateMode, finish: (() -> Void)? = nil) {

        if isFetching {
            return
        }

        isFetching = true
        
        if case .static = mode {
            activityIndicator.startAnimating()
            view.bringSubview(toFront: activityIndicator)
        }

        if case .loadMore = mode {
            currentPageIndex += 1

        } else {
            currentPageIndex = 1
        }

        discoverUsers(masterSkillIDs: [], learningSkillIDs: [], discoveredUserSortStyle: discoveredUserSortStyle, inPage: currentPageIndex, withPerPage: 21, failureHandler: { (reason, errorMessage) in

            SafeDispatch.async { [weak self] in
                self?.activityIndicator.stopAnimating()
                self?.isFetching = false

                finish?()
            }

        }, completion: { discoveredUsers in

            for user in discoveredUsers {

                for skill in user.masterSkills {

                    let skillLocalName = skill.localName

                    let skillID =  skill.id

                    if let _ = skillSizeCache[skillID] {

                    } else {
                        let rect = skillLocalName.boundingRect(with: CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: skillTextAttributes, context: nil)

                        skillSizeCache[skillID] = rect
                    }
                }
            }

            SafeDispatch.async { [weak self] in

                guard let strongSelf = self else {
                    return
                }

                var wayToUpdate: UICollectionView.WayToUpdate = .none

                if case .loadMore = mode {
                    let oldDiscoveredUsersCount = strongSelf.discoveredUsers.count
                    strongSelf.discoveredUsers += discoveredUsers
                    let newDiscoveredUsersCount = strongSelf.discoveredUsers.count

                    let indexPaths = Array(oldDiscoveredUsersCount..<newDiscoveredUsersCount).map({ IndexPath(item: $0, section: Section.user.rawValue) })
                    if !indexPaths.isEmpty {
                        wayToUpdate = .insert(indexPaths)
                    }

                } else {
                    let oldDiscoveredUsers = strongSelf.discoveredUsers
                    let newDiscoveredUsers = discoveredUsers

                    strongSelf.discoveredUsers = newDiscoveredUsers

                    if Set(oldDiscoveredUsers.map({ $0.id })) == Set(newDiscoveredUsers.map({ $0.id })) {
                        wayToUpdate = .none

                    } else {
                        wayToUpdate = .reloadData
                    }
                }

                strongSelf.activityIndicator.stopAnimating()
                strongSelf.isFetching = false

                finish?()

                wayToUpdate.performWithCollectionView(strongSelf.discoveredUsersCollectionView)
            }
        })
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate

extension DiscoverViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    fileprivate enum Section: Int {
        case user
        case loadMore
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {

        case .user:
            return discoveredUsers.count

        case .loadMore:
            return discoveredUsers.isEmpty ? 0 : 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .user:

            switch layoutMode {

            case .normal:
                let cell: DiscoverNormalUserCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                return cell
                
            case .card:
                let cell: DiscoverCardUserCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                return cell
            }

        case .loadMore:
            let cell: LoadMoreCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .user:

            let discoveredUser = discoveredUsers[indexPath.row]

            switch layoutMode {

            case .normal:
                let cell = cell as! DiscoverNormalUserCell
                cell.configureWithDiscoveredUser(discoveredUser, collectionView: collectionView, indexPath: indexPath)
                
            case .card:
                let cell = cell as! DiscoverCardUserCell
                cell.configureWithDiscoveredUser(discoveredUser, collectionView: collectionView, indexPath: indexPath)
            }

        case .loadMore:
            if let cell = cell as? LoadMoreCollectionViewCell {

                println("load more discovered users")

                if !cell.loadingActivityIndicator.isAnimating {
                    cell.loadingActivityIndicator.startAnimating()
                }

                updateDiscoverUsers(mode: .loadMore, finish: { [weak cell] in
                    cell?.loadingActivityIndicator.stopAnimating()
                })
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .user:

            switch layoutMode {

            case .normal:
                return CGSize(width: UIScreen.main.bounds.width, height: 80)

            case .card:
                return CGSize(width: (UIScreen.main.bounds.width - (10 + 10 + 10)) * 0.5, height: 280)
            }

        case .loadMore:
            return CGSize(width: UIScreen.main.bounds.width, height: 80)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {

        case .user:

            switch layoutMode {

            case .normal:
                return UIEdgeInsets.zero
                
            case .card:
                return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            }

        case .loadMore:
            return UIEdgeInsets.zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let discoveredUser = discoveredUsers[indexPath.row]
        showProfileOfDiscoveredUserAction?(discoveredUser)
    }
}


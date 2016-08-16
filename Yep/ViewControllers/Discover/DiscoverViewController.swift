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
import YepNetworking

var skillSizeCache = [String: CGRect]()

final class DiscoverViewController: BaseViewController {

    var showProfileOfDiscoveredUserAction: ((discoveredUser: DiscoveredUser) -> Void)?
    var didChangeLayoutModeAction: ((layoutMode: DiscoverFlowLayout.Mode) -> Void)?
    var didChangeSortStyleAction: ((sortStyle: DiscoveredUserSortStyle) -> Void)?

    @IBOutlet weak var discoveredUsersCollectionView: DiscoverCollectionView!
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private var layoutMode: DiscoverFlowLayout.Mode = .Card {
        didSet {
            didChangeLayoutModeAction?(layoutMode: layoutMode)

            layout.mode = layoutMode
            SafeDispatch.async { [weak self] in
                self?.discoveredUsersCollectionView.reloadData()
            }
        }
    }
    
    private let layout = DiscoverFlowLayout()
    
    private let refreshControl = UIRefreshControl()

    private var discoveredUserSortStyle: DiscoveredUserSortStyle = .Default {
        didSet {
            didChangeSortStyleAction?(sortStyle: discoveredUserSortStyle)

            discoveredUsers = []
            SafeDispatch.async { [weak self] in
                self?.discoveredUsersCollectionView.reloadData()
            }

            updateDiscoverUsers(mode: .Static)

            // save discoveredUserSortStyle
            YepUserDefaults.discoveredUserSortStyle.value = discoveredUserSortStyle.rawValue
        }
    }

    var discoveredUsers = [DiscoveredUser]()

    private lazy var filterStyles: [DiscoveredUserSortStyle] = [
        .Distance,
        .LastSignIn,
        .Default,
    ]

    private func filterItemWithSortStyle(sortStyle: DiscoveredUserSortStyle, currentSortStyle: DiscoveredUserSortStyle) -> ActionSheetView.Item {
        return .Check(
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

    private func filterItemsWithCurrentSortStyle(currentSortStyle: DiscoveredUserSortStyle) -> [ActionSheetView.Item] {
        var items = filterStyles.map({
           filterItemWithSortStyle($0, currentSortStyle: currentSortStyle)
        })
        items.append(.Cancel)
        return items
    }

    private lazy var filterView: ActionSheetView = {
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        refreshControl.endRefreshing()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Discover", comment: "")

        view.backgroundColor = UIColor.whiteColor()

        // recover discoveredUserSortStyle if can

        if let
            value = YepUserDefaults.discoveredUserSortStyle.value,
            _discoveredUserSortStyle = DiscoveredUserSortStyle(rawValue: value) {

                discoveredUserSortStyle = _discoveredUserSortStyle

        } else {
            discoveredUserSortStyle = .Default
        }

        discoveredUsersCollectionView.backgroundColor = UIColor.clearColor()
        discoveredUsersCollectionView.setCollectionViewLayout(layout, animated: false)
        discoveredUsersCollectionView.delegate = self
        discoveredUsersCollectionView.dataSource = self

        discoveredUsersCollectionView.registerNibOf(DiscoverNormalUserCell)
        discoveredUsersCollectionView.registerNibOf(DiscoverCardUserCell)
        discoveredUsersCollectionView.registerNibOf(LoadMoreCollectionViewCell)

        layoutMode = .Card

        if let realm = try? Realm(), offlineJSON = OfflineJSON.withName(.DiscoveredUsers, inRealm: realm) {
            if let JSON = offlineJSON.JSON, discoveredUsers = parseDiscoveredUsers(JSON) {
                self.discoveredUsers = discoveredUsers
                activityIndicator.stopAnimating()
            }
        }

        refreshControl.tintColor = UIColor.lightGrayColor()
        refreshControl.addTarget(self, action: #selector(DiscoverViewController.refresh(_:)), forControlEvents: .ValueChanged)
        refreshControl.layer.zPosition = -1 // Make Sure Indicator below the Cells
        discoveredUsersCollectionView.addSubview(refreshControl)

        #if DEBUG
            //view.addSubview(discoverFPSLabel)
        #endif
    }

    // MARK: Actions

    @objc private func refresh(sender: UIRefreshControl) {

        updateDiscoverUsers(mode: .TopRefresh) {
            SafeDispatch.async {
                sender.endRefreshing()
            }
        }
    }

    func changeLayoutMode() {

        switch layoutMode {
            
        case .Card:
            layoutMode = .Normal

        case .Normal:
            layoutMode = .Card
        }
    }

    func showFilters() {

        if let window = view.window {
            filterView.showInView(window)
        }
    }

    private var currentPageIndex = 1
    private var isFetching = false
    private enum UpdateMode {
        case Static
        case TopRefresh
        case LoadMore
    }
    private func updateDiscoverUsers(mode mode: UpdateMode, finish: (() -> Void)? = nil) {

        if isFetching {
            return
        }

        isFetching = true
        
        if case .Static = mode {
            activityIndicator.startAnimating()
            view.bringSubviewToFront(activityIndicator)
        }

        if case .LoadMore = mode {
            currentPageIndex += 1

        } else {
            currentPageIndex = 1
        }

        discoverUsers(masterSkillIDs: [], learningSkillIDs: [], discoveredUserSortStyle: discoveredUserSortStyle, inPage: currentPageIndex, withPerPage: 21, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            SafeDispatch.async { [weak self] in
                self?.activityIndicator.stopAnimating()
                self?.isFetching = false

                finish?()
            }

        }, completion: { discoveredUsers in

            for user in discoveredUsers {

                for skill in user.masterSkills {

                    let skillLocalName = skill.localName ?? ""

                    let skillID =  skill.id

                    if let _ = skillSizeCache[skillID] {

                    } else {
                        let rect = skillLocalName.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: skillTextAttributes, context: nil)

                        skillSizeCache[skillID] = rect
                    }
                }
            }

            SafeDispatch.async { [weak self] in

                guard let strongSelf = self else {
                    return
                }

                var wayToUpdate: UICollectionView.WayToUpdate = .None

                if case .LoadMore = mode {
                    let oldDiscoveredUsersCount = strongSelf.discoveredUsers.count
                    strongSelf.discoveredUsers += discoveredUsers
                    let newDiscoveredUsersCount = strongSelf.discoveredUsers.count

                    let indexPaths = Array(oldDiscoveredUsersCount..<newDiscoveredUsersCount).map({ NSIndexPath(forItem: $0, inSection: Section.User.rawValue) })
                    if !indexPaths.isEmpty {
                        wayToUpdate = .Insert(indexPaths)
                    }

                } else {
                    strongSelf.discoveredUsers = discoveredUsers
                    wayToUpdate = .ReloadData
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

    private enum Section: Int {
        case User
        case LoadMore
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {

        case .User:
            return discoveredUsers.count

        case .LoadMore:
            return discoveredUsers.isEmpty ? 0 : 1
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .User:

            switch layoutMode {

            case .Normal:
                let cell: DiscoverNormalUserCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                return cell
                
            case .Card:
                let cell: DiscoverCardUserCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                return cell
            }

        case .LoadMore:
            let cell: LoadMoreCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .User:

            let discoveredUser = discoveredUsers[indexPath.row]

            switch layoutMode {

            case .Normal:
                let cell = cell as! DiscoverNormalUserCell
                cell.configureWithDiscoveredUser(discoveredUser, collectionView: collectionView, indexPath: indexPath)
                
            case .Card:
                let cell = cell as! DiscoverCardUserCell
                cell.configureWithDiscoveredUser(discoveredUser, collectionView: collectionView, indexPath: indexPath)
            }

        case .LoadMore:
            if let cell = cell as? LoadMoreCollectionViewCell {

                println("load more discovered users")

                if !cell.loadingActivityIndicator.isAnimating() {
                    cell.loadingActivityIndicator.startAnimating()
                }

                updateDiscoverUsers(mode: .LoadMore, finish: { [weak cell] in
                    cell?.loadingActivityIndicator.stopAnimating()
                })
            }
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .User:

            switch layoutMode {

            case .Normal:
                return CGSize(width: UIScreen.mainScreen().bounds.width, height: 80)

            case .Card:
                return CGSize(width: (UIScreen.mainScreen().bounds.width - (10 + 10 + 10)) * 0.5, height: 280)
            }

        case .LoadMore:
            return CGSize(width: UIScreen.mainScreen().bounds.width, height: 80)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {

        case .User:

            switch layoutMode {

            case .Normal:
                return UIEdgeInsetsZero
                
            case .Card:
                return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            }

        case .LoadMore:
            return UIEdgeInsetsZero
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)

        let discoveredUser = discoveredUsers[indexPath.row]
        showProfileOfDiscoveredUserAction?(discoveredUser: discoveredUser)
    }
}


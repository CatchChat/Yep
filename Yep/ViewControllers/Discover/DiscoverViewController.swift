//
//  DiscoverViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

enum DiscoverUserMode: Int {
    case Normal = 0
    case Card
}

var skillSizeCache = [String: CGRect]()

class DiscoverViewController: BaseViewController {

    @IBOutlet weak var discoveredUsersCollectionView: DiscoverCollectionView!
    
    @IBOutlet private weak var filterButtonItem: UIBarButtonItem!
    
    @IBOutlet private weak var modeButtonItem: UIBarButtonItem!

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private let NormalUserIdentifier = "DiscoverNormalUserCell"
    private let CardUserIdentifier = "DiscoverCardUserCell"
    private let loadMoreCollectionViewCellID = "LoadMoreCollectionViewCell"
    
    private var userMode: DiscoverUserMode = .Card {
        didSet {
            switch userMode {

            case .Card:
                view.backgroundColor = UIColor.yepBackgroundColor()
                modeButtonItem.image = UIImage(named: "icon_list")

            case .Normal:
                view.backgroundColor = UIColor.whiteColor()
                modeButtonItem.image = UIImage(named: "icon_minicard")
            }

            layout.userMode = userMode
            discoveredUsersCollectionView.reloadData()
        }
    }
    
    private let layout = DiscoverFlowLayout()

    private var discoveredUserSortStyle: DiscoveredUserSortStyle = .Default {
        didSet {
            discoveredUsers = []
            discoveredUsersCollectionView.reloadData()
            
            filterButtonItem.title = discoveredUserSortStyle.nameWithArrow

            updateDiscoverUsers(mode: .Static)

            // save discoveredUserSortStyle

            YepUserDefaults.discoveredUserSortStyle.value = discoveredUserSortStyle.rawValue
        }
    }

    private var discoveredUsers = [DiscoveredUser]()

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
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
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

        discoveredUsersCollectionView.registerNib(UINib(nibName: NormalUserIdentifier, bundle: nil), forCellWithReuseIdentifier: NormalUserIdentifier)
        discoveredUsersCollectionView.registerNib(UINib(nibName: CardUserIdentifier, bundle: nil), forCellWithReuseIdentifier: CardUserIdentifier)
        discoveredUsersCollectionView.registerNib(UINib(nibName: loadMoreCollectionViewCellID, bundle: nil), forCellWithReuseIdentifier: loadMoreCollectionViewCellID)

        userMode = .Card

        if let realm = try? Realm(), offlineJSON = OfflineJSON.withName(.DiscoveredUsers, inRealm: realm) {
            if let JSON = offlineJSON.JSON, discoveredUsers = parseDiscoveredUsers(JSON) {
                self.discoveredUsers = discoveredUsers
                activityIndicator.stopAnimating()
            }
        }

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.lightGrayColor()
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        discoveredUsersCollectionView.addSubview(refreshControl)

        #if DEBUG
            //view.addSubview(discoverFPSLabel)
        #endif
    }

    // MARK: Actions

    @objc private func refresh(sender: UIRefreshControl) {

        updateDiscoverUsers(mode: .TopRefresh) {
            dispatch_async(dispatch_get_main_queue()) {
                sender.endRefreshing()
            }
        }
    }

    @IBAction private func changeMode(sender: AnyObject) {

        switch userMode {
            
        case .Card:
            userMode = .Normal

        case .Normal:
            userMode = .Card
        }
    }

    @IBAction private func showFilters(sender: UIBarButtonItem) {

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
            currentPageIndex++

        } else {
            currentPageIndex = 1
        }

        discoverUsers(masterSkillIDs: [], learningSkillIDs: [], discoveredUserSortStyle: discoveredUserSortStyle, inPage: currentPageIndex, withPerPage: 21, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            dispatch_async(dispatch_get_main_queue()) { [weak self] in
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

            dispatch_async(dispatch_get_main_queue()) { [weak self] in

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

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showProfile" {
            if let indexPath = sender as? NSIndexPath {
                let discoveredUser = discoveredUsers[indexPath.row]

                let vc = segue.destinationViewController as! ProfileViewController

                if discoveredUser.id != YepUserDefaults.userID.value {
                    vc.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
                }
                
                vc.setBackButtonWithTitle()

                vc.hidesBottomBarWhenPushed = true
            }
        }
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

        switch section {

        case Section.User.rawValue:
            return discoveredUsers.count

        case Section.LoadMore.rawValue:
            return discoveredUsers.isEmpty ? 0 : 1

        default:
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        switch indexPath.section {

        case Section.User.rawValue:
            switch userMode {

            case .Normal:
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(NormalUserIdentifier, forIndexPath: indexPath) as! DiscoverNormalUserCell
                return cell
                
            case .Card:
               let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CardUserIdentifier, forIndexPath: indexPath) as! DiscoverCardUserCell
                return cell
            }

        case Section.LoadMore.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(loadMoreCollectionViewCellID, forIndexPath: indexPath) as! LoadMoreCollectionViewCell
            return cell

        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        switch indexPath.section {

        case Section.User.rawValue:

            let discoveredUser = discoveredUsers[indexPath.row]

            switch userMode {

            case .Normal:
                let cell = cell as! DiscoverNormalUserCell
                cell.configureWithDiscoveredUser(discoveredUser, collectionView: collectionView, indexPath: indexPath)
                
            case .Card:
                let cell = cell as! DiscoverCardUserCell
                cell.configureWithDiscoveredUser(discoveredUser, collectionView: collectionView, indexPath: indexPath)
            }

        case Section.LoadMore.rawValue:
            if let cell = cell as? LoadMoreCollectionViewCell {

                println("load more discovered users")

                if !cell.loadingActivityIndicator.isAnimating() {
                    cell.loadingActivityIndicator.startAnimating()
                }

                updateDiscoverUsers(mode: .LoadMore, finish: { [weak cell] in
                    cell?.loadingActivityIndicator.stopAnimating()
                })
            }

        default:
            break
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        switch indexPath.section {

        case Section.User.rawValue:

            switch userMode {

            case .Normal:
                return CGSize(width: UIScreen.mainScreen().bounds.width, height: 80)

            case .Card:
                return CGSize(width: (UIScreen.mainScreen().bounds.width - (10 + 10 + 10)) * 0.5, height: 280)
            }

        case Section.LoadMore.rawValue:
            return CGSize(width: UIScreen.mainScreen().bounds.width, height: 80)

        default:
            return CGSizeZero
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        switch section {

        case Section.User.rawValue:

            switch userMode {

            case .Normal:
                return UIEdgeInsetsZero
                
            case .Card:
                return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            }

        case Section.LoadMore.rawValue:
            return UIEdgeInsetsZero

        default:
            return UIEdgeInsetsZero
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        
        performSegueWithIdentifier("showProfile", sender: indexPath)
    }
}


//
//  DiscoverViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

enum DiscoverUserMode: Int {
    case Normal = 0
    case Card
}

var skillSizeCache = [String: CGRect]()

class DiscoverViewController: BaseViewController {

    @IBOutlet weak var discoverCollectionView: UICollectionView!
    
    @IBOutlet weak var filterButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var modeButtonItem: UIBarButtonItem!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let NormalUserIdentifier = "DiscoverNormalUserCell"
    let CardUserIdentifier = "DiscoverCardUserCell"
    let loadMoreCollectionViewCellID = "LoadMoreCollectionViewCell"
    
    var userMode: DiscoverUserMode = .Card {
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
            discoverCollectionView.reloadData()
        }
    }
    
    let layout = DiscoverFlowLayout()

    var discoveredUserSortStyle: DiscoveredUserSortStyle = .Default {
        didSet {
            discoveredUsers = []
            discoverCollectionView.reloadData()
            
            filterButtonItem.title = discoveredUserSortStyle.nameWithArrow

            updateDiscoverUsers()

            // save discoveredUserSortStyle

            YepUserDefaults.discoveredUserSortStyle.value = discoveredUserSortStyle.rawValue
        }
    }

    var discoveredUsers = [DiscoveredUser]()

    lazy var filterView: DiscoverFilterView = DiscoverFilterView()

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

        discoverCollectionView.backgroundColor = UIColor.clearColor()
        discoverCollectionView.setCollectionViewLayout(layout, animated: false)
        discoverCollectionView.delegate = self
        discoverCollectionView.dataSource = self

        discoverCollectionView.registerNib(UINib(nibName: NormalUserIdentifier, bundle: nil), forCellWithReuseIdentifier: NormalUserIdentifier)
        discoverCollectionView.registerNib(UINib(nibName: CardUserIdentifier, bundle: nil), forCellWithReuseIdentifier: CardUserIdentifier)
        discoverCollectionView.registerNib(UINib(nibName: loadMoreCollectionViewCellID, bundle: nil), forCellWithReuseIdentifier: loadMoreCollectionViewCellID)

        userMode = .Card
    }

    // MARK: Actions
    
    @IBAction func changeMode(sender: AnyObject) {

        switch userMode {
            
        case .Card:
            userMode = .Normal

        case .Normal:
            userMode = .Card
        }
    }

    @IBAction func showFilters(sender: UIBarButtonItem) {

        filterView.currentDiscoveredUserSortStyle = discoveredUserSortStyle
        
        filterView.filterAction = { discoveredUserSortStyle in
            self.discoveredUserSortStyle = discoveredUserSortStyle
        }

        if let window = view.window {
            filterView.showInView(window)
        }
    }

    var currentPageIndex = 1
    var isFetching = false
    func updateDiscoverUsers(isLoadMore isLoadMore: Bool = false, finish: (() -> Void)? = nil) {

        if isFetching {
            return
        }

        isFetching = true
        
        if !isLoadMore {
            activityIndicator.startAnimating()
            view.bringSubviewToFront(activityIndicator)
        }

        if isLoadMore {
            currentPageIndex++

        } else {
            currentPageIndex = 1
        }

        discoverUsers(masterSkillIDs: [], learningSkillIDs: [], discoveredUserSortStyle: discoveredUserSortStyle, inPage: currentPageIndex, withPerPage: 30, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage: errorMessage)

            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.activityIndicator.stopAnimating()
                self?.isFetching = false

                finish?()
            }

        }, completion: { discoveredUsers in

            for user in discoveredUsers {

                for skill in  user.masterSkills {

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

                if isLoadMore {
                    self?.discoveredUsers += discoveredUsers

                } else {
                    self?.discoveredUsers = discoveredUsers
                }

                self?.activityIndicator.stopAnimating()
                self?.isFetching = false

                finish?()
                
                if !discoveredUsers.isEmpty {
                    self?.discoverCollectionView.reloadData()
                }
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

    enum Section: Int {
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

                updateDiscoverUsers(isLoadMore: true, finish: { [weak cell] in
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


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
    
    var userMode: DiscoverUserMode = .Card {
        didSet {
            layout.userMode = userMode
            
            switch userMode {

            case .Card:
                view.backgroundColor = UIColor.yepBackgroundColor()
                modeButtonItem.image = UIImage(named: "icon_list")

            case .Normal:
                view.backgroundColor = UIColor.whiteColor()
                modeButtonItem.image = UIImage(named: "icon_minicard")
            }
        }
    }
    
    let layout = DiscoverFlowLayout()

    var discoveredUserSortStyle: DiscoveredUserSortStyle = .Default {
        didSet {
            filterButtonItem.title = discoveredUserSortStyle.nameWithArrow

            activityIndicator.startAnimating()
            
            view.bringSubviewToFront(activityIndicator)

            discoverUsers(masterSkillIDs: [], learningSkillIDs: [], discoveredUserSortStyle: discoveredUserSortStyle, failureHandler: { (reason, errorMessage) in
                defaultFailureHandler(reason, errorMessage: errorMessage)

                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.activityIndicator.stopAnimating()
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
                    self?.discoveredUsers = discoveredUsers
                    self?.activityIndicator.stopAnimating()
                }
            })

            // save discoveredUserSortStyle

            YepUserDefaults.discoveredUserSortStyle.value = discoveredUserSortStyle.rawValue
        }
    }

    var discoveredUsers = [DiscoveredUser]() {
        willSet {
            if newValue.count == 0 {
//                discoverCollectionView.tableFooterView = InfoView(NSLocalizedString("No discovered users.", comment: ""))
            }
        }
        didSet {
            updateDiscoverTableView()
        }
    }

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
        
        discoverCollectionView.reloadData()
        
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

    func updateDiscoverTableView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.discoverCollectionView.reloadData()
//            self.discoverCollectionView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
        }
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
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return discoveredUsers.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        switch userMode {

        case .Normal:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(NormalUserIdentifier, forIndexPath: indexPath) as! DiscoverNormalUserCell
            return cell
            
        case .Card:
           let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CardUserIdentifier, forIndexPath: indexPath) as! DiscoverCardUserCell
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let discoveredUser = discoveredUsers[indexPath.row]
        
        switch userMode {

        case .Normal:
            let cell = cell as! DiscoverNormalUserCell
            cell.configureWithDiscoveredUser(discoveredUser, collectionView: collectionView, indexPath: indexPath)
            
        case .Card:
            let cell = cell as! DiscoverCardUserCell
            cell.configureWithDiscoveredUser(discoveredUser, collectionView: collectionView, indexPath: indexPath)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        switch userMode {

        case .Normal:
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
        case .Card:
            return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        
        performSegueWithIdentifier("showProfile", sender: indexPath)
    }
}


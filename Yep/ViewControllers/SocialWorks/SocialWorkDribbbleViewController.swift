//
//  SocialWorkDribbbleViewController.swift
//  Yep
//
//  Created by NIX on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Kingfisher

class SocialWorkDribbbleViewController: UIViewController {

    var socialAccount: SocialAccount?
    var profileUser: ProfileUser?
    var dribbbleWork: DribbbleWork?

    var afterGetDribbbleWork: (DribbbleWork -> Void)?


    lazy var shareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "share")
        return button
        }()
    
    @IBOutlet weak var dribbbleCollectionView: UICollectionView!

    let dribbbleShotCellIdentifier = "DribbbleShotCell"

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.dribbbleCollectionView.bounds)
        }()

    var dribbbleShots = Array<DribbbleWork.Shot>() {
        didSet {
            updateDribbbleCollectionView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let socialAccount = socialAccount {
            let accountImageView = UIImageView(image: UIImage(named: socialAccount.iconName)!)
            accountImageView.tintColor = socialAccount.tintColor
            navigationItem.titleView = accountImageView

        } else {
            title = "Dribbble"
        }

        shareButton.enabled = false
        navigationItem.rightBarButtonItem = shareButton
        

        dribbbleCollectionView.registerNib(UINib(nibName: dribbbleShotCellIdentifier, bundle: nil), forCellWithReuseIdentifier: dribbbleShotCellIdentifier)


        // 获取 Dribbble Work，如果必要的话

        if let dribbbleWork = dribbbleWork {
            dribbbleShots = dribbbleWork.shots

        } else {
            var userID: String?

            if let profileUser = profileUser {
                switch profileUser {
                case .DiscoveredUserType(let discoveredUser):
                    userID = discoveredUser.id
                case .UserType(let user):
                    userID = user.userID
                }

            } else {
                userID = YepUserDefaults.userID.value
            }

            if let userID = userID {

                dribbbleWorkOfUserWithUserID(userID, failureHandler: { (reason, errorMessage) -> Void in
                    defaultFailureHandler(reason, errorMessage)

                }, completion: { dribbbleWork in
                    println("dribbbleWork: \(dribbbleWork.shots.count)")

                    dispatch_async(dispatch_get_main_queue()) {
                        self.dribbbleShots = dribbbleWork.shots

                        self.afterGetDribbbleWork?(dribbbleWork)
                    }
                })
            }
        }
    }

    // MARK: Actions

    func updateDribbbleCollectionView() {
        dribbbleCollectionView.reloadData()
    }

    func share() {
        // TODO: share
    }

}

extension SocialWorkDribbbleViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dribbbleShots.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(dribbbleShotCellIdentifier, forIndexPath: indexPath) as! DribbbleShotCell

        let shot = dribbbleShots[indexPath.item]

        cell.imageView.kf_setImageWithURL(NSURL(string: shot.images.normal)!)

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        let width = collectionViewWidth * 0.5
        let height = width

        return CGSizeMake(width, height)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let shot = dribbbleShots[indexPath.item]
        
        UIApplication.sharedApplication().openURL(NSURL(string: shot.htmlURLString)!)
    }
}

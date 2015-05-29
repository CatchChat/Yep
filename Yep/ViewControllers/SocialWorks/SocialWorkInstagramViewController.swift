//
//  SocialWorkInstagramViewController.swift
//  Yep
//
//  Created by NIX on 15/5/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SocialWorkInstagramViewController: BaseViewController {

    var socialAccount: SocialAccount?
    var profileUser: ProfileUser?
    var instagramWork: InstagramWork?

    var afterGetInstagramWork: (InstagramWork -> Void)?


    lazy var shareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "share")
        return button
        }()

    @IBOutlet weak var instagramCollectionView: UICollectionView!

    let instagramMediaCellIdentifier = "InstagramMediaCell"

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.instagramCollectionView.bounds)
        }()

    var instagramMedias = Array<InstagramWork.Media>() {
        didSet {
            updateInstagramCollectionView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        animatedOnNavigationBar = false

        if let socialAccount = socialAccount {
            let accountImageView = UIImageView(image: UIImage(named: socialAccount.iconName)!)
            accountImageView.tintColor = socialAccount.tintColor
            navigationItem.titleView = accountImageView

        } else {
            title = "Instagram"
        }

        shareButton.enabled = false
        navigationItem.rightBarButtonItem = shareButton

        instagramCollectionView.registerNib(UINib(nibName: instagramMediaCellIdentifier, bundle: nil), forCellWithReuseIdentifier: instagramMediaCellIdentifier)


        // 获取 Instagram Work，如果必要的话

        if let instagramWork = instagramWork {
            self.instagramMedias = instagramWork.medias
            
        } else {
            var userID: String?

            if let profileUser = profileUser {
                switch profileUser {
                case .DiscoveredUserType(let discoveredUser):
                    userID = discoveredUser.id
                case .UserType(let user):
                    userID = user.userID
                }
            }
//            else {
//                userID = YepUserDefaults.userID.value
//            }

            if let userID = userID {

                instagramWorkOfUserWithUserID(userID, failureHandler: { (reason, errorMessage) -> Void in
                    defaultFailureHandler(reason, errorMessage)

                }, completion: { instagramWork in
                    println("instagramWork: \(instagramWork.medias.count)")

                    dispatch_async(dispatch_get_main_queue()) {
                        self.instagramMedias = instagramWork.medias

                        self.afterGetInstagramWork?(instagramWork)
                    }
                })
            }
        }
    }

    // MARK: Actions

    func updateInstagramCollectionView() {
        instagramCollectionView.reloadData()
    }

    func share() {
        // TODO: share
    }

}

extension SocialWorkInstagramViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return instagramMedias.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(instagramMediaCellIdentifier, forIndexPath: indexPath) as! InstagramMediaCell

        let media = instagramMedias[indexPath.item]

        cell.configureWithInstagramMedia(media)

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        let width = collectionViewWidth * 0.5
        let height = width

        return CGSizeMake(width, height)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let media = instagramMedias[indexPath.item]

        UIApplication.sharedApplication().openURL(NSURL(string: media.linkURLString)!)
    }
}
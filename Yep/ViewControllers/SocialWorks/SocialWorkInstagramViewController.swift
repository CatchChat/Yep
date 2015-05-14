//
//  SocialWorkInstagramViewController.swift
//  Yep
//
//  Created by NIX on 15/5/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SocialWorkInstagramViewController: UIViewController {

    var socialAccount: SocialAccount?
    var profileUser: ProfileUser?


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

        instagramCollectionView.registerNib(UINib(nibName: instagramMediaCellIdentifier, bundle: nil), forCellWithReuseIdentifier: instagramMediaCellIdentifier)


        // 获取 Instagram Work

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

            instagramWorkOfUserWithUserID(userID, failureHandler: { (reason, errorMessage) -> Void in
                defaultFailureHandler(reason, errorMessage)

            }, completion: { instagramWork in
                println("instagramWork: \(instagramWork.medias.count)")

                dispatch_async(dispatch_get_main_queue()) {
                    self.instagramMedias = instagramWork.medias
                }
            })
        }

    }

    // MARK: Actions

    func updateInstagramCollectionView() {
        instagramCollectionView.reloadData()
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

        cell.imageView.kf_setImageWithURL(NSURL(string: media.images.lowResolution)!)

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        let width = collectionViewWidth * 0.5
        let height = width

        return CGSizeMake(width, height)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

    }
}
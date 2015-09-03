//
//  SocialWorkDribbbleViewController.swift
//  Yep
//
//  Created by NIX on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Kingfisher

class SocialWorkDribbbleViewController: BaseViewController {

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

        animatedOnNavigationBar = false
        
        if let socialAccount = socialAccount {
            let accountImageView = UIImageView(image: UIImage(named: socialAccount.iconName)!)
            accountImageView.tintColor = socialAccount.tintColor
            navigationItem.titleView = accountImageView

        } else {
            title = "Dribbble"
        }

        navigationItem.rightBarButtonItem = shareButton
        

        dribbbleCollectionView.registerNib(UINib(nibName: dribbbleShotCellIdentifier, bundle: nil), forCellWithReuseIdentifier: dribbbleShotCellIdentifier)

        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKindOfClass(UIScreenEdgePanGestureRecognizer) {
                    dribbbleCollectionView.panGestureRecognizer.requireGestureRecognizerToFail(recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }

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
            }

            if let userID = userID {

                dribbbleWorkOfUserWithUserID(userID, failureHandler: { [weak self] (reason, errorMessage) -> Void in
                    defaultFailureHandler(reason, errorMessage)

                    YepAlert.alertSorry(message: NSLocalizedString("Network is not good!", comment: ""), inViewController: self)

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
        dispatch_async(dispatch_get_main_queue()) {
            self.dribbbleCollectionView.reloadData()
        }
    }

    func share() {

        if let dribbbleWork = dribbbleWork, profileURL = NSURL(string: dribbbleWork.userURLString) {

            let activityViewController = UIActivityViewController(activityItems: [profileURL], applicationActivities: nil)

            presentViewController(activityViewController, animated: true, completion: nil)
        }
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

        cell.configureWithDribbbleShot(shot)

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

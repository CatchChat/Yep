//
//  SocialWorkDribbbleViewController.swift
//  Yep
//
//  Created by NIX on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Kingfisher
import MonkeyKing

class SocialWorkDribbbleViewController: BaseViewController {

    var socialAccount: SocialAccount?
    var profileUser: ProfileUser?
    var dribbbleWork: DribbbleWork?

    var afterGetDribbbleWork: (DribbbleWork -> Void)?


    private lazy var shareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "share:")
        return button
        }()
    
    @IBOutlet private weak var dribbbleCollectionView: UICollectionView!

    private let dribbbleShotCellIdentifier = "DribbbleShotCell"

    private lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.dribbbleCollectionView.bounds)
    }()

    private var dribbbleShots = Array<DribbbleWork.Shot>() {
        didSet {
            updateDribbbleCollectionView()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        animatedOnNavigationBar = false
        
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

                dribbbleWorkOfUserWithUserID(userID, failureHandler: { [weak self] reason, errorMessage in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    YepAlert.alertSorry(message: NSLocalizedString("Network is not good!", comment: ""), inViewController: self)

                }, completion: { dribbbleWork in
                    println("dribbbleWork: \(dribbbleWork.shots.count)")

                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        self?.dribbbleWork = dribbbleWork
                        self?.dribbbleShots = dribbbleWork.shots

                        self?.afterGetDribbbleWork?(dribbbleWork)
                    }
                })
            }
        }
    }

    // MARK: Actions

    private func updateDribbbleCollectionView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.dribbbleCollectionView.reloadData()
        }
    }

    @objc private func share(sender: AnyObject) {

        if let dribbbleWork = dribbbleWork, profileURL = NSURL(string: dribbbleWork.userURLString) {

            let title = String(format: NSLocalizedString("%@'s Dribbble", comment: ""), dribbbleWork.username)

            var thumbnail: UIImage?
            if let socialAccount = socialAccount {
                thumbnail = UIImage(named: socialAccount.iconName)
            }

            let info = MonkeyKing.Info(
                title: title,
                description: nil,
                thumbnail: thumbnail,
                media: .URL(profileURL)
            )

            let sessionMessage = MonkeyKing.Message.WeChat(.Session(info: info))

            let weChatSessionActivity = WeChatActivity(
                type: .Session,
                message: sessionMessage,
                finish: { success in
                    println("share Dribbble to WeChat Session success: \(success)")
                }
            )

            let timelineMessage = MonkeyKing.Message.WeChat(.Timeline(info: info))

            let weChatTimelineActivity = WeChatActivity(
                type: .Timeline,
                message: timelineMessage,
                finish: { success in
                    println("share Dribbble to WeChat Timeline success: \(success)")
                }
            )
            
            let activityViewController = UIActivityViewController(activityItems: [profileURL], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])

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

        if let URL = NSURL(string: shot.htmlURLString) {
            yep_openURL(URL)
        }
    }
}

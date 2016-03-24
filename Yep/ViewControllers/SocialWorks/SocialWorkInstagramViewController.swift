//
//  SocialWorkInstagramViewController.swift
//  Yep
//
//  Created by NIX on 15/5/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import MonkeyKing

class SocialWorkInstagramViewController: BaseViewController {

    var socialAccount: SocialAccount?
    var profileUser: ProfileUser?
    var instagramWork: InstagramWork?

    var afterGetInstagramWork: (InstagramWork -> Void)?


    private lazy var shareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "share:")
        return button
        }()

    @IBOutlet private weak var instagramCollectionView: UICollectionView!

    private let instagramMediaCellIdentifier = "InstagramMediaCell"

    private lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.instagramCollectionView.bounds)
    }()

    private var instagramMedias = Array<InstagramWork.Media>() {
        didSet {
            updateInstagramCollectionView()

            if let _ = instagramMedias.first {
                shareButton.enabled = true
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
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

        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKindOfClass(UIScreenEdgePanGestureRecognizer) {
                    instagramCollectionView.panGestureRecognizer.requireGestureRecognizerToFail(recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }

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

            if let userID = userID {

                instagramWorkOfUserWithUserID(userID, failureHandler: { [weak self] (reason, errorMessage) -> Void in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    YepAlert.alertSorry(message: NSLocalizedString("Network is not good!", comment: ""), inViewController: self)

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

    private func updateInstagramCollectionView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.instagramCollectionView.reloadData()
        }
    }

    @objc private func share(sender: AnyObject) {

        if let firstMedia = instagramMedias.first {

            let profileURLString = "https://instagram.com/" + firstMedia.username

            if let profileURL = NSURL(string: profileURLString) {

                let title = String(format: NSLocalizedString("%@'s Instagram", comment: ""), firstMedia.username)

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
                        println("share Instagram to WeChat Session success: \(success)")
                    }
                )

                let timelineMessage = MonkeyKing.Message.WeChat(.Timeline(info: info))

                let weChatTimelineActivity = WeChatActivity(
                    type: .Timeline,
                    message: timelineMessage,
                    finish: { success in
                        println("share Instagram to WeChat Timeline success: \(success)")
                    }
                )

                let activityViewController = UIActivityViewController(activityItems: [profileURL], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])

                presentViewController(activityViewController, animated: true, completion: nil)
            }
        }
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

        let application = UIApplication.sharedApplication()

        if let instagramMediaURL = NSURL(string: "instagram://media?id=\(media.ID)") where application.canOpenURL(instagramMediaURL) {
            application.openURL(instagramMediaURL)

        } else {
            if let URL = NSURL(string: media.linkURLString) {
                yep_openURL(URL)
            }
        }
    }
}


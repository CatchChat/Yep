//
//  SocialWorkInstagramViewController.swift
//  Yep
//
//  Created by NIX on 15/5/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import MonkeyKing

final class SocialWorkInstagramViewController: BaseViewController {

    var socialAccount: SocialAccount?
    var profileUser: ProfileUser?
    var instagramWork: InstagramWork?

    var afterGetInstagramWork: (InstagramWork -> Void)?


    private lazy var shareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(SocialWorkInstagramViewController.share(_:)))
        return button
        }()

    @IBOutlet private weak var instagramCollectionView: UICollectionView!

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

        instagramCollectionView.registerNibOf(InstagramMediaCell)

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
            if let userID = profileUser?.userID {

                instagramWorkOfUserWithUserID(userID, failureHandler: { [weak self] (reason, errorMessage) -> Void in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    let message = errorMessage ?? String.trans_promptNetworkConnectionIsNotGood
                    YepAlert.alertSorry(message: message, inViewController: self)

                }, completion: { instagramWork in
                    //println("instagramWork: \(instagramWork.medias.count)")

                    SafeDispatch.async { [weak self] in
                        self?.instagramMedias = instagramWork.medias

                        self?.afterGetInstagramWork?(instagramWork)
                    }
                })
            }
        }
    }

    // MARK: Actions

    private func updateInstagramCollectionView() {

        SafeDispatch.async { [weak self] in
            self?.instagramCollectionView.reloadData()
        }
    }

    @objc private func share(sender: AnyObject) {

        guard let firstMedia = instagramMedias.first else { return}
        let profileURLString = "https://instagram.com/" + firstMedia.username
        guard let profileURL = NSURL(string: profileURLString) else { return }

        let title = String(format: NSLocalizedString("whosInstagram%@", comment: ""), firstMedia.username)

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
        self.yep_share(info: info, defaultActivityItem: profileURL)
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

        let cell: InstagramMediaCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

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


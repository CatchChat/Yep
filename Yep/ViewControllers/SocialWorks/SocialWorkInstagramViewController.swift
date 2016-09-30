//
//  SocialWorkInstagramViewController.swift
//  Yep
//
//  Created by NIX on 15/5/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import MonkeyKing

final class SocialWorkInstagramViewController: BaseViewController {

    var socialAccount: SocialAccount?
    var profileUser: ProfileUser?
    var instagramWork: InstagramWork?

    var afterGetInstagramWork: ((InstagramWork) -> Void)?

    fileprivate lazy var shareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(SocialWorkInstagramViewController.share(_:)))
        return button
    }()

    @IBOutlet fileprivate weak var instagramCollectionView: UICollectionView!

    fileprivate lazy var collectionViewWidth: CGFloat = {
        return self.instagramCollectionView.bounds.width
    }()

    fileprivate var instagramMedias = Array<InstagramWork.Media>() {
        didSet {
            updateInstagramCollectionView()

            if let _ = instagramMedias.first {
                shareButton.isEnabled = true
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

        shareButton.isEnabled = false
        navigationItem.rightBarButtonItem = shareButton

        instagramCollectionView.registerNibOf(InstagramMediaCell.self)

        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) {
                    instagramCollectionView.panGestureRecognizer.require(toFail: recognizer as! UIScreenEdgePanGestureRecognizer)
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

                instagramWorkOfUserWithUserID(userID, failureHandler: { [weak self] (reason, errorMessage) in
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

    fileprivate func updateInstagramCollectionView() {

        SafeDispatch.async { [weak self] in
            self?.instagramCollectionView.reloadData()
        }
    }

    @objc fileprivate func share(_ sender: AnyObject) {

        guard let firstMedia = instagramMedias.first else { return}
        let profileURLString = "https://instagram.com/" + firstMedia.username
        guard let profileURL = URL(string: profileURLString) else { return }

        let title = String(format: NSLocalizedString("whosInstagram%@", comment: ""), firstMedia.username)

        var thumbnail: UIImage?
        if let socialAccount = socialAccount {
            thumbnail = UIImage(named: socialAccount.iconName)
        }

        let info = MonkeyKing.Info(
            title: title,
            description: nil,
            thumbnail: thumbnail,
            media: .url(profileURL)
        )
        self.yep_share(info: info, defaultActivityItem: profileURL)
    }
}

extension SocialWorkInstagramViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return instagramMedias.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell: InstagramMediaCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

        let media = instagramMedias[indexPath.item]

        cell.configureWithInstagramMedia(media)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: IndexPath!) -> CGSize {

        let width = collectionViewWidth * 0.5
        let height = width

        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let media = instagramMedias[indexPath.item]

        let application = UIApplication.shared

        if let instagramMediaURL = URL(string: "instagram://media?id=\(media.ID)"), application.canOpenURL(instagramMediaURL) {
            application.openURL(instagramMediaURL)

        } else {
            if let URL = URL(string: media.linkURLString) {
                yep_openURL(URL)
            }
        }
    }
}


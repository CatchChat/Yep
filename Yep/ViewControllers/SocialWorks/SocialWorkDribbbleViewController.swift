//
//  SocialWorkDribbbleViewController.swift
//  Yep
//
//  Created by NIX on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import Kingfisher
import MonkeyKing

final class SocialWorkDribbbleViewController: BaseViewController {

    var socialAccount: SocialAccount?
    var profileUser: ProfileUser?
    var dribbbleWork: DribbbleWork?

    var afterGetDribbbleWork: (DribbbleWork -> Void)?


    private lazy var shareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(SocialWorkDribbbleViewController.share(_:)))
        return button
    }()
    
    @IBOutlet private weak var dribbbleCollectionView: UICollectionView!

    private lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.dribbbleCollectionView.bounds)
    }()

    private var dribbbleShots = Array<DribbbleWork.Shot>() {
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

        navigationItem.rightBarButtonItem = shareButton
        
        dribbbleCollectionView.registerNibOf(DribbbleShotCell)

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
            if let userID = profileUser?.userID {

                dribbbleWorkOfUserWithUserID(userID, failureHandler: { [weak self] reason, errorMessage in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    let message = errorMessage ?? String.trans_promptNetworkConnectionIsNotGood
                    YepAlert.alertSorry(message: message, inViewController: self)

                }, completion: { dribbbleWork in
                    //println("dribbbleWork: \(dribbbleWork.shots.count)")

                    SafeDispatch.async { [weak self] in
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
        
        SafeDispatch.async { [weak self] in
            self?.dribbbleCollectionView.reloadData()
        }
    }

    @objc private func share(sender: AnyObject) {

        guard let dribbbleWork = dribbbleWork else { return }
        guard let profileURL = NSURL(string: dribbbleWork.userURLString) else { return }

        let title = String(format: NSLocalizedString("whosDribbble%@", comment: ""), dribbbleWork.username)

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

extension SocialWorkDribbbleViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dribbbleShots.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell: DribbbleShotCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

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

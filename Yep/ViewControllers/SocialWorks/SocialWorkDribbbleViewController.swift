//
//  SocialWorkDribbbleViewController.swift
//  Yep
//
//  Created by NIX on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SocialWorkDribbbleViewController: UIViewController {

    var socialAccount: SocialAccount?

    
    @IBOutlet weak var dribbbleCollectionView: UICollectionView!

    let dribbbleShotCellIdentifier = "DribbbleShotCell"

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.dribbbleCollectionView.bounds)
        }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let socialAccount = socialAccount {
            let accountImageView = UIImageView(image: UIImage(named: socialAccount.iconName)!)
            accountImageView.tintColor = socialAccount.tintColor
            navigationItem.titleView = accountImageView

        } else {
            title = "Dribbble"
        }

        let gotoButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "gotoUserDribbbleHome")
        navigationItem.rightBarButtonItem = gotoButton
        

        dribbbleCollectionView.registerNib(UINib(nibName: dribbbleShotCellIdentifier, bundle: nil), forCellWithReuseIdentifier: dribbbleShotCellIdentifier)


        // 获取 Dribbble Work

        if let userID = YepUserDefaults.userID.value {
            dribbbleWorkOfUserWithUserID(userID, failureHandler: { (reason, errorMessage) -> Void in
                defaultFailureHandler(reason, errorMessage)

            }, completion: { dribbbleWork in
                println("dribbbleWork: \(dribbbleWork.shots.count)")
            })
        }
    }

    // MARK: Actions

    func gotoUserDribbbleHome() {
        // TODO: gotoUserDribbbleHome
    }

}

extension SocialWorkDribbbleViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(dribbbleShotCellIdentifier, forIndexPath: indexPath) as! DribbbleShotCell

        cell.imageView.image = UIImage(named: "Cover3")

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        let width = collectionViewWidth * 0.5
        let height = width

        return CGSizeMake(width, height)
    }
}

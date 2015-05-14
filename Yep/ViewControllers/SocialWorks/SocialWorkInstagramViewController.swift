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

    var dribbbleShots = Array<DribbbleWork.Shot>() {
        didSet {
            updateInstagramCollectionView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        instagramCollectionView.registerNib(UINib(nibName: instagramMediaCellIdentifier, bundle: nil), forCellWithReuseIdentifier: instagramMediaCellIdentifier)

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
        return 30
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(instagramMediaCellIdentifier, forIndexPath: indexPath) as! InstagramMediaCell

        cell.imageView.image = UIImage(named: "Cover3")!

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
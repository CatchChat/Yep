//
//  FeedsViewController.swift
//  Yep
//
//  Created by nixzhu on 15/9/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedsViewController: UIViewController {

    @IBOutlet weak var feedsCollectionView: UICollectionView!

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.feedsCollectionView.bounds)
        }()

    let feedCellID = "FeedCell"

    struct FakeFeed {
        let mediaCount: Int
        let message: String
    }
    let fakeFeeds: [FakeFeed] = [
        FakeFeed(mediaCount: 1, message: "My name is NIX."),
        FakeFeed(mediaCount: 0, message: "My name is NIX.\nHow are you?"),
        FakeFeed(mediaCount: 3, message: "My name is NIX.\nHow are you?\nWhould you like to go to China buy iPhone?"),
        FakeFeed(mediaCount: 0, message: "My name is NIX.\nHow are you?\nWhould you like to go to China buy iPhone?"),
        FakeFeed(mediaCount: 4, message: "Whould you like to go to China buy iPhone?"),
        FakeFeed(mediaCount: 5, message: "998"),
    ]

    private func heightOfFeed(feed: FakeFeed) -> CGFloat {

        let rect = feed.message.boundingRectWithSize(CGSize(width: FeedCell.messageLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.ChatCell.textAttributes, context: nil)

        let height: CGFloat
        if feed.mediaCount > 0 {
            height = ceil(rect.height) + 10 + 40 + 4 + 10 + 80 + 10 + 20.5 + 10
        } else {
            height = ceil(rect.height) + 10 + 40 + 4 + 10 + 20.5 + 10
        }

        return ceil(height)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Feeds", comment: "")

        feedsCollectionView.backgroundColor = UIColor.whiteColor()
        feedsCollectionView.registerNib(UINib(nibName: feedCellID, bundle: nil), forCellWithReuseIdentifier: feedCellID)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
}

extension FeedsViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fakeFeeds.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(feedCellID, forIndexPath: indexPath) as! FeedCell

        let feed = fakeFeeds[indexPath.item]

        cell.configureWithFeed(feed)

        cell.backgroundColor = indexPath.item % 2 == 0 ? UIColor.yellowColor() : UIColor.purpleColor()

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        let feed = fakeFeeds[indexPath.item]

        return CGSize(width: collectionViewWidth, height: heightOfFeed(feed))
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }
}


//
//  FeedsViewController.swift
//  Yep
//
//  Created by nixzhu on 15/9/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

class FeedsViewController: UIViewController {

    @IBOutlet weak var feedsTableView: UITableView!

    lazy var pullToRefreshView: PullToRefreshView = {

        let pullToRefreshView = PullToRefreshView()
        pullToRefreshView.delegate = self

        self.feedsTableView.insertSubview(pullToRefreshView, atIndex: 0)

        pullToRefreshView.translatesAutoresizingMaskIntoConstraints = false

        let viewsDictionary = [
            "pullToRefreshView": pullToRefreshView,
            "view": self.view,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(-200)-[pullToRefreshView(200)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        // 非常奇怪，若直接用 "H:|[pullToRefreshView]|" 得到的实际宽度为 0
        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[pullToRefreshView(==view)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)
        
        return pullToRefreshView
        }()

    let feedCellID = "FeedCell"

    lazy var noFeedsFooterView: InfoView = InfoView(NSLocalizedString("No Feeds.", comment: ""))

    var feeds = [DiscoveredFeed]() {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.feedsTableView.reloadData()

                if let strongSelf = self {
                    strongSelf.feedsTableView.tableFooterView = strongSelf.feeds.isEmpty ? strongSelf.noFeedsFooterView : UIView()
                }
            }
        }
    }

    private var feedHeightHash = [String: CGFloat]()

    private func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let key = feed.id

        if let height = feedHeightHash[key] {
            return height
        } else {
            let height = FeedCell.heightOfFeed(feed)

            if !key.isEmpty {
                feedHeightHash[key] = height
            }

            return height
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Feeds", comment: "")

        feedsTableView.backgroundColor = UIColor.whiteColor()
        feedsTableView.registerNib(UINib(nibName: feedCellID, bundle: nil), forCellReuseIdentifier: feedCellID)
        feedsTableView.tableFooterView = UIView()
        feedsTableView.separatorColor = UIColor.yepCellSeparatorColor()

        updateFeeds()
    }

    // MARK: - Actions

    func updateFeeds() {

        discoverFeedsWithSortStyle(.Time, pageIndex: 1, perPage: 100, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason, errorMessage: errorMessage)

        }, completion: { [weak self] feeds in
            self?.feeds = feeds
            println("discoverFeeds.count: \(feeds.count)")
        })
    }

    @IBAction func showNewFeed(sender: AnyObject) {

        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("NewFeedViewController") as! NewFeedViewController

        vc.afterCreatedFeedAction = { [weak self] feed in
            self?.feeds.insert(feed, atIndex: 0)
        }

        let navi = UINavigationController(rootViewController: vc)

        self.presentViewController(navi, animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showConversation" {

            guard let
                index = sender as? Int,
                feedData = feeds[safe: index],
                realm = try? Realm() else {
                    return
            }
            
            let vc = segue.destinationViewController as! ConversationViewController
            
            let groupID = feedData.groupID
            var group = groupWithGroupID(groupID, inRealm: realm)

            if group == nil {

                let newGroup = Group()
                newGroup.groupID = groupID

                realm.write {
                    realm.add(newGroup)
                }

                group = newGroup
            }

            guard let feedGroup = group else {
                return
            }

            if feedGroup.conversation == nil {

                let newConversation = Conversation()

                newConversation.type = ConversationType.Group.rawValue
                newConversation.withGroup = feedGroup

                realm.write {
                    realm.add(newConversation)
                }
            }

            guard let feedConversation = feedGroup.conversation else {
                return
            }

            vc.conversation = feedConversation
            
            if let group = group {
                saveFeedWithFeedData(feedData, group: group, inRealm: realm)
            }

            vc.conversationFeed = ConversationFeed.DiscoveredFeedType(feedData)
        }
    }
}

extension FeedsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return feeds.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier(feedCellID) as! FeedCell

        let feed = feeds[indexPath.item]

        cell.configureWithFeed(feed)

        return cell
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        let feed = feeds[indexPath.item]

        return heightOfFeed(feed)
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        performSegueWithIdentifier("showConversation", sender: indexPath.item)
    }

    // MARK: UIScrollViewDelegate

    func scrollViewDidScroll(scrollView: UIScrollView) {

        pullToRefreshView.scrollViewDidScroll(scrollView)
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        pullToRefreshView.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
}

// MARK: PullToRefreshViewDelegate

extension FeedsViewController: PullToRefreshViewDelegate {

    func pulllToRefreshViewDidRefresh(pulllToRefreshView: PullToRefreshView) {

        delay(0.5) {
            pulllToRefreshView.endRefreshingAndDoFurtherAction() { [weak self] in
                self?.updateFeeds()
            }
        }
    }
    
    func scrollView() -> UIScrollView {
        return feedsTableView
    }
}


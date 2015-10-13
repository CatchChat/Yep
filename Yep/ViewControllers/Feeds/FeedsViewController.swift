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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

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

    var feeds = [DiscoveredFeed]()

    private func updateFeedsTableViewOrInsertWithIndexPaths(indexPaths: [NSIndexPath]?) {

        dispatch_async(dispatch_get_main_queue()) { [weak self] in

            if let indexPaths = indexPaths {
                self?.feedsTableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)

            } else {
                self?.feedsTableView.reloadData()
            }

            if let strongSelf = self {
                strongSelf.feedsTableView.tableFooterView = strongSelf.feeds.isEmpty ? strongSelf.noFeedsFooterView : UIView()
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

    var navigationControllerDelegate: ConversationMessagePreviewNavigationControllerDelegate?
    var originalNavigationControllerDelegate: UINavigationControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Feeds", comment: "")

        feedsTableView.backgroundColor = UIColor.whiteColor()
        feedsTableView.registerNib(UINib(nibName: feedCellID, bundle: nil), forCellReuseIdentifier: feedCellID)
        feedsTableView.tableFooterView = UIView()
        feedsTableView.separatorColor = UIColor.yepCellSeparatorColor()

        updateFeeds()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // 尝试恢复原始的 NavigationControllerDelegate，如果自定义 push 了才需要
        if let delegate = originalNavigationControllerDelegate {
            navigationController?.delegate = delegate
        }

        navigationController?.setNavigationBarHidden(false, animated: false)
        tabBarController?.tabBar.hidden = false
    }

    // MARK: - Actions

    func updateFeeds(finish: (() -> Void)? = nil) {

        activityIndicator.startAnimating()

        discoverFeedsWithSortStyle(.Time, pageIndex: 1, perPage: 100, failureHandler: { reason, errorMessage in

            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.activityIndicator.stopAnimating()

                finish?()
            }

            defaultFailureHandler(reason, errorMessage: errorMessage)

        }, completion: { [weak self] feeds in

            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.activityIndicator.stopAnimating()

                finish?()
            }

            if let strongSelf = self {

                let oldFeedSet = Set(strongSelf.feeds)
                let newFeedSet = Set(feeds)

                let unionFeedSet = oldFeedSet.union(newFeedSet)
                let allNewFeedSet = newFeedSet.subtract(oldFeedSet)

                let allFeeds = Array(unionFeedSet).sort({ $0.createdUnixTime > $1.createdUnixTime })

                let newIndexPaths = allNewFeedSet.map({ allFeeds.indexOf($0) }).flatMap({ $0 }).map({ NSIndexPath(forRow: $0, inSection: 0) })

                dispatch_async(dispatch_get_main_queue()) {

                    strongSelf.feeds = allFeeds

                    if newIndexPaths.count == allNewFeedSet.count {
                        strongSelf.updateFeedsTableViewOrInsertWithIndexPaths(newIndexPaths)

                    } else {
                        strongSelf.updateFeedsTableViewOrInsertWithIndexPaths(nil)
                    }
                }
            }
        })
    }

    @IBAction func showNewFeed(sender: AnyObject) {

        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("NewFeedViewController") as! NewFeedViewController

        vc.afterCreatedFeedAction = { [weak self] feed in

            dispatch_async(dispatch_get_main_queue()) {

                if let strongSelf = self {

                    strongSelf.feeds.insert(feed, atIndex: 0)

                    let indexPath = NSIndexPath(forRow: 0, inSection: 0)
                    strongSelf.updateFeedsTableViewOrInsertWithIndexPaths([indexPath])
                }
            }
        }

        let navi = UINavigationController(rootViewController: vc)

        self.presentViewController(navi, animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showProfile":

            let vc = segue.destinationViewController as! ProfileViewController

            if let indexPath = sender as? NSIndexPath {
                let discoveredUser = feeds[indexPath.row].creator
                vc.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
            }

            vc.fromType = .None
            vc.setBackButtonWithTitle()

        case "showConversation":

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

        case "showFeedMedia":

            let info = sender as! [String: AnyObject]

            let vc = segue.destinationViewController as! MessageMediaViewController
            vc.previewMedia = PreviewMedia.AttachmentType(imageURL: info["imageURL"] as! NSURL )

            let transitionView = info["transitionView"] as! UIImageView

            let delegate = ConversationMessagePreviewNavigationControllerDelegate()
            delegate.isFeedMedia = true
            delegate.snapshot = UIScreen.mainScreen().snapshotViewAfterScreenUpdates(false)

            var frame = transitionView.convertRect(transitionView.frame, toView: view)
            delegate.frame = frame
            if let image = transitionView.image {
                let width = image.size.width
                let height = image.size.height
                if width > height {
                    let newWidth = frame.width * (width / height)
                    frame.origin.x -= (newWidth - frame.width) / 2
                    frame.size.width = newWidth
                } else {
                    let newHeight = frame.height * (height / width)
                    frame.origin.y -= (newHeight - frame.height) / 2
                    frame.size.height = newHeight
                }
                delegate.thumbnailImage = image
            }
            delegate.thumbnailFrame = frame

            delegate.transitionView = transitionView

            navigationControllerDelegate = delegate

            // 在自定义 push 之前，记录原始的 NavigationControllerDelegate 以便 pop 后恢复
            originalNavigationControllerDelegate = navigationController!.delegate

            navigationController?.delegate = delegate
            
            break

        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

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

        cell.tapAvatarAction = { [weak self] in
            self?.performSegueWithIdentifier("showProfile", sender: indexPath)
        }

        cell.tapMediaAction = { [weak self] transitionView, imageURL in
            let info = [
                "transitionView": transitionView,
                "imageURL": imageURL,
            ]
            self?.performSegueWithIdentifier("showFeedMedia", sender: info)
        }

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

        activityIndicator.alpha = 0

        updateFeeds { [weak self] in
            pulllToRefreshView.endRefreshingAndDoFurtherAction() {}

            self?.activityIndicator.alpha = 1
        }
    }
    
    func scrollView() -> UIScrollView {
        return feedsTableView
    }
}


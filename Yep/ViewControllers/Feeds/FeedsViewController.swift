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

    private func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let rect = feed.body.boundingRectWithSize(CGSize(width: FeedCell.messageLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.ChatCell.textAttributes, context: nil)

        let height: CGFloat
        if feed.attachments.isEmpty {
            height = ceil(rect.height) + 10 + 40 + 4 + 15 + 17 + 15
        } else {
            height = ceil(rect.height) + 10 + 40 + 4 + 15 + 80 + 15 + 17 + 15
        }

        return ceil(height)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Feeds", comment: "")

        feedsTableView.backgroundColor = UIColor.whiteColor()
        feedsTableView.registerNib(UINib(nibName: feedCellID, bundle: nil), forCellReuseIdentifier: feedCellID)
        feedsTableView.tableFooterView = UIView()

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

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showNewFeed" {

            let vc = segue.destinationViewController as! NewFeedViewController
            
            vc.afterCreatedFeedAction = { [weak self] in
                self?.updateFeeds()
            }
        }

        if segue.identifier == "showConversation" {

            guard let
                index = sender as? Int,
                feed = feeds[safe: index],
                realm = try? Realm() else {
                    return
            }

            let vc = segue.destinationViewController as! ConversationViewController

            let groupID = feed.groupID
            var group = groupWithGroupID(groupID, inRealm: realm)

            if group == nil {

                let newGroup = Group()
                newGroup.groupID = groupID

                // TOOD: newGroup of Feed
                /*
                if let groupInfo = messageInfo["circle"] as? JSONDictionary {
                    if let groupName = groupInfo["name"] as? String {
                        newGroup.groupName = groupName
                    }
                }
                */

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
            vc.feed = feed
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
}


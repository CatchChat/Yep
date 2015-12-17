//
//  FeedsViewController.swift
//  Yep
//
//  Created by nixzhu on 15/9/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import AVFoundation
import MapKit

class FeedsViewController: BaseViewController {

    var skill: Skill?

    var profileUser: ProfileUser?
    var preparedFeedsCount = 0
    
    var hideRightBarItem: Bool = false

    var feeds = [DiscoveredFeed]()

    @IBOutlet weak var feedsTableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private var filterBarItem: UIBarButtonItem?
    
    private lazy var filterView: DiscoverFilterView = DiscoverFilterView()
    
    private lazy var newFeedTypesView: NewFeedTypesView = {
        let view = NewFeedTypesView()

        view.createTextAndPhotosFeedAction = { [weak self] in
            self?.performSegueWithIdentifier("presentNewFeed", sender: nil)
        }

        view.createVoiceFeedAction = { [weak self] in
            self?.performSegueWithIdentifier("presentNewFeedVoiceRecord", sender: nil)
        }

        view.createShortMovieFeedAction = { [weak self] in
        }

        view.createLocationFeedAction = { [weak self] in
            self?.performSegueWithIdentifier("presentPickLocation", sender: nil)
        }

        return view
    }()
    
    private lazy var skillTitleView: UIView = {

        let titleLabel = UILabel()

        let textAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: UIFont.skillHomeTextLargeFont()
        ]

        let titleAttr = NSMutableAttributedString(string: self.skill?.localName ?? "", attributes:textAttributes)

        titleLabel.attributedText = titleAttr
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.backgroundColor = UIColor.yepTintColor()
        titleLabel.sizeToFit()

        titleLabel.bounds = CGRectInset(titleLabel.frame, -25.0, -4.0)

        titleLabel.layer.cornerRadius = titleLabel.frame.size.height/2.0
        titleLabel.layer.masksToBounds = true

        return titleLabel
    }()

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

    #if DEBUG
    private lazy var feedsFPSLabel: FPSLabel = {
        let label = FPSLabel()
        return label
    }()
    #endif

    private let feedSkillUsersCellID = "FeedSkillUsersCell"
    private let feedBasicCellID = "FeedBasicCell"
    private let feedCellID = "FeedCell"
    private let feedBiggerImageCellID = "FeedBiggerImageCell"
    private let feedNormalImagesCellID = "FeedNormalImagesCell"
    private let feedSocialWorkCellID = "FeedSocialWorkCell"
    private let loadMoreTableViewCellID = "LoadMoreTableViewCell"

    private lazy var noFeedsFooterView: InfoView = InfoView(NSLocalizedString("No Feeds.", comment: ""))

    private var audioPlayedDurations = [String: NSTimeInterval]()

    private func audioPlayedDurationOfFeedAudio(feedAudio: FeedAudio) -> NSTimeInterval {
        let key = feedAudio.feedID

        if !key.isEmpty {
            if let playedDuration = audioPlayedDurations[key] {
                return playedDuration
            }
        }

        return 0
    }

    private func setAudioPlayedDuration(audioPlayedDuration: NSTimeInterval, ofFeedAudio feedAudio: FeedAudio) {
        let key = feedAudio.feedID
        if !key.isEmpty {
            audioPlayedDurations[key] = audioPlayedDuration
        }

        // recover audio cells' UI

        if audioPlayedDuration == 0 {

            let feedID = feedAudio.feedID

            for index in 0..<feeds.count {
                let feed = feeds[index]
                if feed.id == feedID {

                    let indexPath = NSIndexPath(forRow: index, inSection: Section.Feed.rawValue)

                    if let cell = feedsTableView.cellForRowAtIndexPath(indexPath) as? FeedSocialWorkCell {
                        cell.audioPlayedDuration = 0
                    }

                    break
                }
            }
        }
    }

    private func updateFeedsTableViewOrInsertWithIndexPaths(indexPaths: [NSIndexPath]?) {

        // refresh skillUsers

        let skillUsersIndexPath = NSIndexPath(forRow: 0, inSection: Section.SkillUsers.rawValue)
        if let cell = feedsTableView.cellForRowAtIndexPath(skillUsersIndexPath) as? FeedSkillUsersCell {
            cell.configureWithFeeds(feeds)
        }

        if let indexPaths = indexPaths where feeds.count > 1 {
            // insert
            feedsTableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)

        } else {
            // or reload
            feedsTableView.reloadData()
        }

        feedsTableView.tableFooterView = feeds.isEmpty ? noFeedsFooterView : UIView()
    }

    private var feedHeightHash = [String: CGFloat]()

    private func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let key = feed.id

        if let height = feedHeightHash[key] {
            return height

        } else {
            let height: CGFloat

            switch feed.kind {

            case .Text:
                height = FeedBasicCell.heightOfFeed(feed)

            case .Image:
                if feed.imageAttachmentsCount == 1 {
                    height = FeedBiggerImageCell.heightOfFeed(feed)

                } else if feed.imageAttachmentsCount <= 3 {
                    height = FeedNormalImagesCell.heightOfFeed(feed)

                } else {
                    height = FeedCell.heightOfFeed(feed)
                }

            case .GithubRepo, .DribbbleShot, .Audio, .Location:
                height = FeedSocialWorkCell.heightOfFeed(feed)

            default:
                height = FeedBasicCell.heightOfFeed(feed)
            }

            if !key.isEmpty {
                feedHeightHash[key] = height
            }

            return height
        }
    }
    
    private var feedSortStyle: FeedSortStyle = .Match {
        didSet {
            feeds = []
            feedsTableView.reloadData()

            filterBarItem?.title = feedSortStyle.nameWithArrow

            updateFeeds()

            YepUserDefaults.feedSortStyle.value = feedSortStyle.rawValue
        }
    }

    //var navigationControllerDelegate: ConversationMessagePreviewNavigationControllerDelegate?
    //var originalNavigationControllerDelegate: UINavigationControllerDelegate?
    
    deinit {

        feedsTableView?.delegate = nil

        print("Deinit FeedsViewControler")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 优先处理侧滑，而不是 scrollView 的上下滚动，避免出现你想侧滑返回的时候，结果触发了 scrollView 的上下滚动
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKindOfClass(UIScreenEdgePanGestureRecognizer) {
                    feedsTableView.panGestureRecognizer.requireGestureRecognizerToFail(recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }

        title = NSLocalizedString("Feeds", comment: "")

        if skill != nil {
            navigationItem.titleView = skillTitleView
            // Add to Me
            
            if let skillID = skill?.id {
                if let
                    myUserID = YepUserDefaults.userID.value,
                    realm = try? Realm(),
                    me = userWithUserID(myUserID, inRealm: realm) {
                        
                        let predicate = NSPredicate(format: "skillID = %@", skillID)
                        
                        if me.masterSkills.filter(predicate).count == 0
                            && me.learningSkills.filter(predicate).count == 0 {
                                let addSkillToMeButton = UIBarButtonItem(title: NSLocalizedString("Add to Me", comment: ""), style: .Plain, target: self, action: "addSkillToMe:")
                                navigationItem.rightBarButtonItem = addSkillToMeButton
                        }
                }
            }

        } else if profileUser != nil {
            // do nothing

        } else {
            filterBarItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: "showFilter:")
            navigationItem.leftBarButtonItem = filterBarItem
        }

        feedsTableView.backgroundColor = UIColor.whiteColor()
        feedsTableView.tableFooterView = UIView()
        feedsTableView.separatorColor = UIColor.yepCellSeparatorColor()

        feedsTableView.registerNib(UINib(nibName: feedSkillUsersCellID, bundle: nil), forCellReuseIdentifier: feedSkillUsersCellID)

        feedsTableView.registerClass(FeedBasicCell.self, forCellReuseIdentifier: feedBasicCellID)
        feedsTableView.registerClass(FeedCell.self, forCellReuseIdentifier: feedCellID)
        feedsTableView.registerClass(FeedBiggerImageCell.self, forCellReuseIdentifier: feedBiggerImageCellID)
        feedsTableView.registerClass(FeedNormalImagesCell.self, forCellReuseIdentifier: feedNormalImagesCellID)
        feedsTableView.registerClass(FeedSocialWorkCell.self, forCellReuseIdentifier: feedSocialWorkCellID)

        feedsTableView.registerNib(UINib(nibName: loadMoreTableViewCellID, bundle: nil), forCellReuseIdentifier: loadMoreTableViewCellID)


        if hideRightBarItem {
             navigationItem.rightBarButtonItem = nil
        }
        
        if preparedFeedsCount > 0 {
            currentPageIndex = 2
        }

        // 没有 profileUser 才设置 feedSortStyle 以请求服务器
        if profileUser == nil {

            if let
                value = YepUserDefaults.feedSortStyle.value,
                _feedSortStyle = FeedSortStyle(rawValue: value) {
                    feedSortStyle = _feedSortStyle
                    
            } else {
                feedSortStyle = .Match
            }

            if skill == nil {
                if let realm = try? Realm(), offlineJSON = OfflineJSON.withName(.Feeds, inRealm: realm) {
                    if let JSON = offlineJSON.JSON, feeds = parseFeeds(JSON) {
                        self.feeds = feeds
                        activityIndicator.stopAnimating()
                    }
                }
            }
        }

        #if DEBUG
            view.addSubview(feedsFPSLabel)
        #endif
    }

    // MARK: Actions
    
    @objc private func addSkillToMe(sender: AnyObject) {
        println("addSkillToMe")
        
        if let skillID = skill?.id, skillLocalName = skill?.localName {
            
            let doAddSkillToSkillSet: SkillSet -> Void = { skillSet in
                
                addSkillWithSkillID(skillID, toSkillSet: skillSet, failureHandler: { reason, errorMessage in
                    defaultFailureHandler(reason, errorMessage: errorMessage)
                    
                }, completion: { [weak self] _ in
                    
                    YepAlert.alert(title: NSLocalizedString("Success", comment: ""), message: String(format: NSLocalizedString("Added %@ to %@ successfully!", comment: ""), skillLocalName, skillSet.name), dismissTitle: NSLocalizedString("OK", comment: ""), inViewController: self, withDismissAction: nil)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self?.navigationItem.rightBarButtonItem = nil
                    }
                    
                    syncMyInfoAndDoFurtherAction {
                    }
                })
            }
            
            let alertController = UIAlertController(title: NSLocalizedString("Choose skill set", comment: ""), message: String(format: NSLocalizedString("Which skill set do you want %@ to be?", comment: ""), skillLocalName), preferredStyle: .Alert)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel) { action in
            }
            alertController.addAction(cancelAction)
            
            let learningAction: UIAlertAction = UIAlertAction(title: SkillSet.Learning.name, style: .Default) { action in
                doAddSkillToSkillSet(.Learning)
            }
            alertController.addAction(learningAction)
            
            let masterAction: UIAlertAction = UIAlertAction(title: SkillSet.Master.name, style: .Default) { action in
                doAddSkillToSkillSet(.Master)
            }
            alertController.addAction(masterAction)
            
            presentViewController(alertController, animated: true, completion: nil)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        /*
        // 尝试恢复原始的 NavigationControllerDelegate，如果自定义 push 了才需要
        if let delegate = originalNavigationControllerDelegate {
            navigationController?.delegate = delegate
            navigationControllerDelegate = nil
        }
        */

        navigationController?.setNavigationBarHidden(false, animated: false)

        //tabBarController?.tabBar.hidden = (skill == nil && profileUser == nil) ? false : true
    }

    // MARK: - Actions

    @IBAction private func showFilter(sender: AnyObject) {
        
        if feedSortStyle != .Time {
            filterView.currentDiscoveredUserSortStyle = DiscoveredUserSortStyle(rawValue: feedSortStyle.rawValue)!
        } else {
            filterView.currentDiscoveredUserSortStyle = .LastSignIn
        }
        
        filterView.filterAction = { [weak self] discoveredUserSortStyle in
            
            if discoveredUserSortStyle != .LastSignIn {
                self?.feedSortStyle = FeedSortStyle(rawValue: discoveredUserSortStyle.rawValue)!
            } else {
                self?.feedSortStyle = .Time
            }
        }
        
        if let window = view.window {
            filterView.showInView(window)
        }
    }

    private var currentPageIndex = 1
    private var isFetchingFeeds = false
    private func updateFeeds(isLoadMore isLoadMore: Bool = false, finish: (() -> Void)? = nil) {

        if isFetchingFeeds {
            finish?()
            return
        }

        isFetchingFeeds = true

        if !isLoadMore && feeds.isEmpty {
            activityIndicator.startAnimating()
        }

        if isLoadMore {
            currentPageIndex++

        } else {
            currentPageIndex = 1
        }

        let failureHandler: (Reason, String?) -> Void = { reason, errorMessage in

            dispatch_async(dispatch_get_main_queue()) { [weak self] in

                self?.isFetchingFeeds = false

                self?.activityIndicator.stopAnimating()

                finish?()
            }

            defaultFailureHandler(reason, errorMessage: errorMessage)
        }

        let completion: [DiscoveredFeed] -> Void = { feeds in

            dispatch_async(dispatch_get_main_queue()) { [weak self] in

                self?.isFetchingFeeds = false

                self?.activityIndicator.stopAnimating()

                finish?()
            }

            dispatch_async(dispatch_get_main_queue()) { [weak self] in

                if let strongSelf = self {

                    let newFeeds = feeds
                    let oldFeeds = strongSelf.feeds

                    var wayToUpdate: UITableView.WayToUpdate = .None

                    if strongSelf.feeds.isEmpty {
                        wayToUpdate = .ReloadData
                    }

                    if isLoadMore {
                        let oldFeedsCount = strongSelf.feeds.count
                        strongSelf.feeds += newFeeds
                        let newFeedsCount = strongSelf.feeds.count

                        let indexPaths = Array(oldFeedsCount..<newFeedsCount).map({ NSIndexPath(forRow: $0, inSection: Section.Feed.rawValue) })
                        if !indexPaths.isEmpty {
                            wayToUpdate = .Insert(indexPaths)
                        }

                    } else {
                        strongSelf.feeds = newFeeds
                    }

                    if !wayToUpdate.needsLabor && !newFeeds.isEmpty {

                        if newFeeds.count == oldFeeds.count {

                            var index = 0
                            while index < newFeeds.count {
                                let newFeed = newFeeds[index]
                                let oldFeed = oldFeeds[index]

                                if newFeed.id != oldFeed.id {
                                    wayToUpdate = .ReloadData
                                    break
                                }

                                index += 1
                            }

                        } else {
                            wayToUpdate = .ReloadData
                        }
                    }

                    wayToUpdate.performWithTableView(strongSelf.feedsTableView)
                }
            }
        }

        let perPage = 20

        if let profileUser = profileUser {
            feedsOfUser(profileUser.userID, pageIndex: currentPageIndex, perPage: (preparedFeedsCount > 0) ? preparedFeedsCount : perPage, failureHandler: failureHandler, completion: completion)

        } else {

            var feedSortStyle = self.feedSortStyle
            if skill != nil {
                feedSortStyle = .Time
            }

            let maxFeedID = (isLoadMore && (feedSortStyle == FeedSortStyle.Time)) ? feeds.last?.id : nil

            discoverFeedsWithSortStyle(feedSortStyle, skill: skill, pageIndex: currentPageIndex, perPage: perPage, maxFeedID: maxFeedID, failureHandler:failureHandler, completion: completion)
        }
    }

    @IBAction private func createNewFeed(sender: AnyObject) {

        if let window = view.window {
            newFeedTypesView.showInView(window)
        }
    }

    @objc private func updateAudioPlaybackProgress(timer: NSTimer) {

        func updateCellOfFeedAudio(feedAudio: FeedAudio, withCurrentTime currentTime: NSTimeInterval) {

            let feedID = feedAudio.feedID

            for index in 0..<feeds.count {
                let feed = feeds[index]
                if feed.id == feedID {

                    let indexPath = NSIndexPath(forRow: index, inSection: Section.Feed.rawValue)

                    if let cell = feedsTableView.cellForRowAtIndexPath(indexPath) as? FeedSocialWorkCell {
                        cell.audioPlayedDuration = currentTime
                    }

                    break
                }
            }
        }

        if let audioPlayer = YepAudioService.sharedManager.audioPlayer {

            if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio {

                let currentTime = audioPlayer.currentTime

                setAudioPlayedDuration(currentTime, ofFeedAudio: playingFeedAudio )
                
                updateCellOfFeedAudio(playingFeedAudio, withCurrentTime: currentTime)
            }
        }
    }

    // MARK: - Navigation

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {

        guard navigationController?.topViewController == self else {
            return false
        }

        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        let afterCreatedFeedAction: DiscoveredFeed -> Void = { [weak self] feed in

            dispatch_async(dispatch_get_main_queue()) {

                if let strongSelf = self {

                    strongSelf.feeds.insert(feed, atIndex: 0)

                    let indexPath = NSIndexPath(forRow: 0, inSection: Section.Feed.rawValue)
                    strongSelf.updateFeedsTableViewOrInsertWithIndexPaths([indexPath])
                }
            }

            joinGroup(groupID: feed.groupID, failureHandler: nil, completion: {
            })
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

            vc.hidesBottomBarWhenPushed = true

        case "showSkillHome":

            let vc = segue.destinationViewController as! SkillHomeViewController

            if let skill = skill {
                vc.skill = SkillCell.Skill(ID: skill.id, localName: skill.localName, coverURLString: skill.coverURLString, category: nil)
            }

            vc.hidesBottomBarWhenPushed = true

        case "showFeedsWithSkill":

            let vc = segue.destinationViewController as! FeedsViewController

            if let indexPath = sender as? NSIndexPath {
                vc.skill = feeds[indexPath.row].skill
            }

            vc.hidesBottomBarWhenPushed = true

        case "showConversation":

            let vc = segue.destinationViewController as! ConversationViewController

            guard let
                indexPath = sender as? NSIndexPath,
                feed = feeds[safe: indexPath.row],
                realm = try? Realm() else {
                    return
            }

            realm.beginWrite()
            let feedConversation = vc.prepareConversationForFeed(feed, inRealm: realm)
            let _ = try? realm.commitWrite()

            vc.conversation = feedConversation
            vc.conversationFeed = ConversationFeed.DiscoveredFeedType(feed)
            vc.afterDeletedFeedAction = { [weak self] in
                self?.updateFeeds()
            }

        case "presentNewFeed":

            guard let
                nvc = segue.destinationViewController as? UINavigationController,
                vc = nvc.topViewController as? NewFeedViewController
            else {
                return
            }

            vc.preparedSkill = skill

            vc.afterCreatedFeedAction = afterCreatedFeedAction

        case "presentNewFeedVoiceRecord":

            guard let
                nvc = segue.destinationViewController as? UINavigationController,
                vc = nvc.topViewController as? NewFeedVoiceRecordViewController
            else {
                return
            }

            vc.preparedSkill = skill

            vc.afterCreatedFeedAction = afterCreatedFeedAction

        case "presentPickLocation":

            guard let
                nvc = segue.destinationViewController as? UINavigationController,
                vc = nvc.topViewController as? PickLocationViewController
            else {
                return
            }

            vc.purpose = .Feed

            vc.preparedSkill = skill

            vc.afterCreatedFeedAction = afterCreatedFeedAction

        /*
        case "showFeedMedia":

            let info = sender as! [String: AnyObject]

            let vc = segue.destinationViewController as! MessageMediaViewController

            if let box = info["attachments"] as? Box<[DiscoveredAttachment]> {
                let attachments = box.value
                vc.previewMedias = attachments.map({ PreviewMedia.AttachmentType(attachment: $0) })
            }

            if let index = info["index"] as? Int {
                vc.startIndex = index
            }

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
        */
        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension FeedsViewController: UITableViewDataSource, UITableViewDelegate {

    private enum Section: Int {
        case SkillUsers
        case Feed
        case LoadMore
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 3
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch section {
        case Section.SkillUsers.rawValue:
            return (skill == nil) ? 0 : 1
        case Section.Feed.rawValue:
            return feeds.count
        case Section.LoadMore.rawValue:
            return feeds.isEmpty ? 0 : 1
        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        switch indexPath.section {

        case Section.SkillUsers.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(feedSkillUsersCellID) as! FeedSkillUsersCell
            return cell

        case Section.Feed.rawValue:
            let feed = feeds[indexPath.row]

            switch feed.kind {

            case .Text:
                let cell = tableView.dequeueReusableCellWithIdentifier(feedBasicCellID) as! FeedBasicCell
                return cell

            case .Image:
                if feed.imageAttachmentsCount == 1 {
                    let cell = tableView.dequeueReusableCellWithIdentifier(feedBiggerImageCellID) as! FeedBiggerImageCell
                    return cell

                } else if feed.imageAttachmentsCount <= 3 {
                    let cell = tableView.dequeueReusableCellWithIdentifier(feedNormalImagesCellID) as! FeedNormalImagesCell
                    return cell

                } else {
                    let cell = tableView.dequeueReusableCellWithIdentifier(feedCellID) as! FeedCell
                    return cell
                }

            case .GithubRepo, .DribbbleShot, .Audio, .Location:
                let cell = tableView.dequeueReusableCellWithIdentifier(feedSocialWorkCellID) as! FeedSocialWorkCell
                return cell

            default:
                let cell = tableView.dequeueReusableCellWithIdentifier(feedBasicCellID) as! FeedBasicCell
                return cell
            }

        case Section.LoadMore.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(loadMoreTableViewCellID) as! LoadMoreTableViewCell
            return cell

        default:
            return UITableViewCell()
        }
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        switch indexPath.section {

        case Section.SkillUsers.rawValue:

            guard let cell = cell as? FeedSkillUsersCell else {
                break
            }

            cell.configureWithFeeds(feeds)

        case Section.Feed.rawValue:

            let feed = feeds[indexPath.row]

            guard let cell = cell as? FeedBasicCell else {
                break
            }

            cell.tapAvatarAction = { [weak self] cell in
                if let indexPath = tableView.indexPathForCell(cell) { // 不直接捕捉 indexPath
                    self?.performSegueWithIdentifier("showProfile", sender: indexPath)
                }
            }

            cell.tapSkillAction = { [weak self] cell in
                if let indexPath = tableView.indexPathForCell(cell) { // 不直接捕捉 indexPath
                    self?.performSegueWithIdentifier("showFeedsWithSkill", sender: indexPath)
                }
            }

            // simulate select effects when tap on messageTextView or cell.mediaCollectionView's space part
            // 不能直接捕捉 indexPath，不然新插入后，之前捕捉的 indexPath 不能代表 cell 的新位置，模拟点击会错位到其它 cell
            cell.touchesBeganAction = { [weak self] cell in
                guard let indexPath = tableView.indexPathForCell(cell) else {
                    return
                }
                self?.tableView(tableView, willSelectRowAtIndexPath: indexPath)
                tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
            }
            cell.touchesEndedAction = { [weak self] cell in
                guard let indexPath = tableView.indexPathForCell(cell) else {
                    return
                }
                delay(0.03) { [weak self] in
                    self?.tableView(tableView, didSelectRowAtIndexPath: indexPath)
                }
            }
            cell.touchesCancelledAction = { cell in
                guard let indexPath = tableView.indexPathForCell(cell) else {
                    return
                }
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }

            switch feed.kind {

            case .Text:

                cell.configureWithFeed(feed, needShowSkill: (skill == nil) ? true : false)

            case .Image:

                let tapMediaAction: FeedTapMediaAction = { [weak self] transitionView, image, attachments, index in

                    guard image != nil else {
                        return
                    }

                    let vc = UIStoryboard(name: "MediaPreview", bundle: nil).instantiateViewControllerWithIdentifier("MediaPreviewViewController") as! MediaPreviewViewController

                    vc.previewMedias = attachments.map({ PreviewMedia.AttachmentType(attachment: $0) })
                    vc.startIndex = index

                    let transitionView = transitionView
                    let frame = transitionView.convertRect(transitionView.bounds, toView: self?.view)
                    vc.previewImageViewInitalFrame = frame
                    vc.bottomPreviewImage = image

                    vc.transitionView = transitionView

                    delay(0) {
                        transitionView.alpha = 0 // 放到下一个 Runloop 避免太快消失产生闪烁
                    }
                    vc.afterDismissAction = { [weak self] in
                        transitionView.alpha = 1
                        self?.view.window?.makeKeyAndVisible()
                    }

                    mediaPreviewWindow.rootViewController = vc
                    mediaPreviewWindow.windowLevel = UIWindowLevelAlert - 1
                    mediaPreviewWindow.makeKeyAndVisible()
                }

                if feed.imageAttachmentsCount == 1 {
                    guard let cell = cell as? FeedBiggerImageCell else {
                        break
                    }

                    cell.configureWithFeed(feed, needShowSkill: (skill == nil) ? true : false)

                    cell.tapMediaAction = tapMediaAction

                } else if feed.imageAttachmentsCount <= 3 {

                    guard let cell = cell as? FeedNormalImagesCell else {
                        break
                    }

                    cell.configureWithFeed(feed, needShowSkill: (skill == nil) ? true : false)

                    cell.tapMediaAction = tapMediaAction

                } else {
                    guard let cell = cell as? FeedCell else {
                        break
                    }

                    cell.configureWithFeed(feed, needShowSkill: (skill == nil) ? true : false)

                    cell.tapMediaAction = tapMediaAction
                }

            case .GithubRepo, .DribbbleShot, .Audio, .Location:

                guard let cell = cell as? FeedSocialWorkCell else {
                    break
                }

                cell.configureWithFeed(feed, needShowSkill: (skill == nil) ? true : false)

                cell.tapGithubRepoLinkAction = { [weak self] URL in
                    self?.yep_openURL(URL)
                }

                cell.tapDribbbleShotLinkAction = { [weak self] URL in
                    self?.yep_openURL(URL)
                }

                cell.tapDribbbleShotMediaAction = { [weak self] transitionView, image, imageURL, linkURL in

                    guard image != nil else {
                        return
                    }

                    let vc = UIStoryboard(name: "MediaPreview", bundle: nil).instantiateViewControllerWithIdentifier("MediaPreviewViewController") as! MediaPreviewViewController

                    vc.previewMedias = [PreviewMedia.WebImage(imageURL: imageURL, linkURL: linkURL)]
                    vc.startIndex = 0

                    let transitionView = transitionView
                    let frame = transitionView.convertRect(transitionView.bounds, toView: self?.view)
                    vc.previewImageViewInitalFrame = frame
                    vc.bottomPreviewImage = image

                    delay(0) {
                        transitionView.alpha = 0 // 放到下一个 Runloop 避免太快消失产生闪烁
                    }
                    vc.afterDismissAction = { [weak self] in
                        transitionView.alpha = 1
                        self?.view.window?.makeKeyAndVisible()
                    }

                    mediaPreviewWindow.rootViewController = vc
                    mediaPreviewWindow.windowLevel = UIWindowLevelAlert - 1
                    mediaPreviewWindow.makeKeyAndVisible()
                }

                cell.playOrPauseAudioAction = { [weak self] cell in

                    guard let realm = try? Realm(), feedAudio = FeedAudio.feedAudioWithFeedID(feed.id, inRealm: realm) else {
                        return
                    }

                    let play: () -> Void = { [weak self] in

                        if let strongSelf = self {

                            let audioPlayedDuration = strongSelf.audioPlayedDurationOfFeedAudio(feedAudio)
                            YepAudioService.sharedManager.playAudioWithFeedAudio(feedAudio, beginFromTime: audioPlayedDuration, delegate: strongSelf, success: {
                                println("playAudioWithFeedAudio success!")

                                let playbackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: strongSelf, selector: "updateAudioPlaybackProgress:", userInfo: nil, repeats: true)
                                YepAudioService.sharedManager.playbackTimer = playbackTimer

                                cell.audioPlaying = true
                            })
                        }
                    }

                    if let strongSelf = self {

                        // 如果在播放，就暂停
                        if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio, audioPlayer = YepAudioService.sharedManager.audioPlayer where audioPlayer.playing {

                            audioPlayer.pause()

                            if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
                                playbackTimer.invalidate()
                            }

                            let feedID = playingFeedAudio.feedID
                            for index in 0..<strongSelf.feeds.count {
                                let feed = strongSelf.feeds[index]
                                if feed.id == feedID {

                                    let indexPath = NSIndexPath(forRow: index, inSection: Section.Feed.rawValue)

                                    if let cell = strongSelf.feedsTableView.cellForRowAtIndexPath(indexPath) as? FeedSocialWorkCell {
                                        cell.audioPlaying = false
                                    }

                                    break
                                }
                            }

                            if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio where playingFeedAudio.feedID == feed.id {
                            } else {
                                // 暂停的是别人，咱开始播放
                                play()
                            }
                            
                        } else {
                            // 直接播放
                            play()
                        }
                    }
                }

                cell.tapLocationAction = { locationName, locationCoordinate in

                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                    mapItem.name = locationName

                    mapItem.openInMapsWithLaunchOptions(nil)
                }

            default:
                break
            }

        case Section.LoadMore.rawValue:

            guard let cell = cell as? LoadMoreTableViewCell else {
                break
            }

            println("load more feeds")

            if !cell.loadingActivityIndicator.isAnimating() {
                cell.loadingActivityIndicator.startAnimating()
            }

            updateFeeds(isLoadMore: true, finish: { [weak cell] in
                cell?.loadingActivityIndicator.stopAnimating()
            })

        default:
            break
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        switch indexPath.section {

        case Section.SkillUsers.rawValue:
            return 70

        case Section.Feed.rawValue:
            let feed = feeds[indexPath.row]
            return heightOfFeed(feed)

        case Section.LoadMore.rawValue:
            return 60

        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return indexPath
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        switch indexPath.section {

        case Section.SkillUsers.rawValue:
            performSegueWithIdentifier("showSkillHome", sender: nil)

        case Section.Feed.rawValue:
            performSegueWithIdentifier("showConversation", sender: indexPath)

        default:
            break
        }
    }


    // Report
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {

        switch indexPath.section {

        case Section.SkillUsers.rawValue:
            return false

        case Section.Feed.rawValue:
            let feed = feeds[indexPath.item]
            if feed.creator.id == YepUserDefaults.userID.value {
                return false
            } else {
                return true
            }

        default:
            return false
        }
    }
    
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return NSLocalizedString("Report", comment: "")
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            
            let feed = feeds[indexPath.item]
            report(.Feed(feed))

            tableView.setEditing(false, animated: true)
        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewDidScroll(scrollView: UIScrollView) {

        pullToRefreshView.scrollViewDidScroll(scrollView)
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        pullToRefreshView.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {

        pullToRefreshView.scrollViewDidEndScrollingAnimation(scrollView)
    }
}

// MARK: PullToRefreshViewDelegate

extension FeedsViewController: PullToRefreshViewDelegate {

    func pulllToRefreshViewDidRefresh(pulllToRefreshView: PullToRefreshView) {

        activityIndicator.alpha = 0

        let finish: () -> Void = { [weak self] in
            pulllToRefreshView.endRefreshingAndDoFurtherAction() {}

            self?.activityIndicator.alpha = 1
        }

        pullToRefreshView.refreshTimeoutAction = finish

        updateFeeds(finish: finish)
    }

    func scrollView() -> UIScrollView {
        return feedsTableView
    }
}

// MARK: AVAudioPlayerDelegate

extension FeedsViewController: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {

        println("audioPlayerDidFinishPlaying \(flag)")

        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
            playbackTimer.invalidate()
        }

        if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio {
            setAudioPlayedDuration(0, ofFeedAudio: playingFeedAudio)
            println("setAudioPlayedDuration to 0")
        }
    }
}



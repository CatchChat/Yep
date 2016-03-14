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
    var needShowSkill: Bool {
        return (skill == nil) ? true : false
    }

    var profileUser: ProfileUser?
    var preparedFeedsCount = 0
    
    var hideRightBarItem: Bool = false

    var uploadingFeeds = [DiscoveredFeed]()
    func handleUploadingErrorMessage(message: String) {
        if !uploadingFeeds.isEmpty {
            uploadingFeeds[0].uploadingErrorMessage = message
            feedsTableView.reloadSections(NSIndexSet(index: Section.UploadingFeed.rawValue), withRowAnimation: .None)

            println("handleUploadingErrorMessage: \(message)")
        }
    }
    var feeds = [DiscoveredFeed]()

    @IBOutlet weak var feedsTableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private var selectedIndexPathForMenu: NSIndexPath?

    private var filterBarItem: UIBarButtonItem?
    
    private lazy var filterStyles: [FeedSortStyle] = [
        .Distance,
        .Time,
        .Match,
    ]

    private func filterItemWithSortStyle(sortStyle: FeedSortStyle, currentSortStyle: FeedSortStyle) -> ActionSheetView.Item {
        return .Check(
            title: sortStyle.name,
            titleColor: UIColor.yepTintColor(),
            checked: sortStyle == currentSortStyle,
            action: { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.feedSortStyle = sortStyle
                strongSelf.filterView.items = strongSelf.filterItemsWithCurrentSortStyle(strongSelf.feedSortStyle)
                strongSelf.filterView.refreshItems()
            }
        )
    }

    private func filterItemsWithCurrentSortStyle(currentSortStyle: FeedSortStyle) -> [ActionSheetView.Item] {
        var items = filterStyles.map({
            filterItemWithSortStyle($0, currentSortStyle: currentSortStyle)
        })
        items.append(.Cancel)
        return items
    }

    private lazy var filterView: ActionSheetView = {
        let view = ActionSheetView(items: self.filterItemsWithCurrentSortStyle(self.feedSortStyle))
        return view
    }()

    private lazy var newFeedTypesView: ActionSheetView = {
        let view = ActionSheetView(items: [
            .Default(
                title: NSLocalizedString("Text & Photos", comment: ""),
                titleColor: UIColor.yepTintColor(),
                action: { [weak self] in
                    self?.performSegueWithIdentifier("presentNewFeed", sender: nil)
                    return true
                }
            ),
            .Default(
                title: NSLocalizedString("Voice", comment: ""),
                titleColor: UIColor.yepTintColor(),
                action: { [weak self] in
                    self?.performSegueWithIdentifier("presentNewFeedVoiceRecord", sender: nil)
                    return true
                }
            ),
            .Default(
                title: NSLocalizedString("Location", comment: ""),
                titleColor: UIColor.yepTintColor(),
                action: { [weak self] in
                    self?.performSegueWithIdentifier("presentPickLocation", sender: nil)
                    return true
                }
            ),
            .Cancel,
            ]
        )
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

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(-200)-[pullToRefreshView(200)]", options: [], metrics: nil, views: viewsDictionary)

        // 非常奇怪，若直接用 "H:|[pullToRefreshView]|" 得到的实际宽度为 0
        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[pullToRefreshView(==view)]|", options: [], metrics: nil, views: viewsDictionary)

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
    private let feedBiggerImageCellID = "FeedBiggerImageCell"
    private let feedNormalImagesCellID = "FeedNormalImagesCell"
    private let feedAnyImagesCellID = "FeedAnyImagesCell"
    private let feedGithubRepoCellID = "FeedGithubRepoCell"
    private let feedDribbbleShotCellID = "FeedDribbbleShotCell"
    private let feedVoiceCellID = "FeedVoiceCell"
    private let feedLocationCellID = "FeedLocationCell"
    private let feedURLCellID = "FeedURLCell"
    private let loadMoreTableViewCellID = "LoadMoreTableViewCell"

    private lazy var noFeedsFooterView: InfoView = InfoView(NSLocalizedString("No Feeds.", comment: ""))

    private var audioPlayedDurations = [String: NSTimeInterval]()

    private weak var feedAudioPlaybackTimer: NSTimer?

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

                    if let cell = feedsTableView.cellForRowAtIndexPath(indexPath) as? FeedVoiceCell {
                        cell.audioPlayedDuration = 0
                    }

                    break
                }
            }
        }
    }

    private func updateFeedsTableViewOrInsertWithIndexPaths(indexPaths: [NSIndexPath]?, animation: UITableViewRowAnimation? = nil) {

        // refresh skillUsers

        let skillUsersIndexPath = NSIndexPath(forRow: 0, inSection: Section.SkillUsers.rawValue)
        if let cell = feedsTableView.cellForRowAtIndexPath(skillUsersIndexPath) as? FeedSkillUsersCell {
            cell.configureWithFeeds(feeds)
        }

        if let indexPaths = indexPaths where feeds.count > 1 {
            // insert
            feedsTableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: animation ?? .Automatic)

        } else {
            // or reload
            feedsTableView.reloadData()
        }

        feedsTableView.tableFooterView = feeds.isEmpty ? noFeedsFooterView : UIView()
    }

    private struct LayoutPool {

        private var feedCellLayoutHash = [String: FeedCellLayout]()

        private func feedCellLayoutOfFeed(feed: DiscoveredFeed) -> FeedCellLayout? {
            let key = feed.id

            return feedCellLayoutHash[key]
        }

        private mutating func updateFeedCellLayout(layout: FeedCellLayout, forFeed feed: DiscoveredFeed) {

            let key = feed.id

            if !key.isEmpty {
                feedCellLayoutHash[key] = layout
            }

            //println("feedCellLayoutHash.count: \(feedCellLayoutHash.count)")
        }

        private mutating func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

            if let layout = feedCellLayoutOfFeed(feed) {
                return layout.height

            } else {
                let layout = FeedCellLayout(feed: feed)
                updateFeedCellLayout(layout, forFeed: feed)
                return layout.height
            }
        }
    }
    private static var layoutPool = LayoutPool()

    private var needShowDistance: Bool = false
    private var feedSortStyle: FeedSortStyle = .Match {
        didSet {
            needShowDistance = (feedSortStyle == .Distance)

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
        NSNotificationCenter.defaultCenter().removeObserver(self)
        feedsTableView?.delegate = nil

        print("deinit FeedsViewControler")
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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didRecieveMenuWillShowNotification:", name: UIMenuControllerWillShowMenuNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didRecieveMenuWillHideNotification:", name: UIMenuControllerWillHideMenuNotification, object: nil)

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
        feedsTableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine

        feedsTableView.registerNib(UINib(nibName: feedSkillUsersCellID, bundle: nil), forCellReuseIdentifier: feedSkillUsersCellID)

        feedsTableView.registerClass(FeedBasicCell.self, forCellReuseIdentifier: feedBasicCellID)
        feedsTableView.registerClass(FeedBiggerImageCell.self, forCellReuseIdentifier: feedBiggerImageCellID)
        feedsTableView.registerClass(FeedNormalImagesCell.self, forCellReuseIdentifier: feedNormalImagesCellID)
        feedsTableView.registerClass(FeedAnyImagesCell.self, forCellReuseIdentifier: feedAnyImagesCellID)
        feedsTableView.registerClass(FeedGithubRepoCell.self, forCellReuseIdentifier: feedGithubRepoCellID)
        feedsTableView.registerClass(FeedDribbbleShotCell.self, forCellReuseIdentifier: feedDribbbleShotCellID)
        feedsTableView.registerClass(FeedVoiceCell.self, forCellReuseIdentifier: feedVoiceCellID)
        feedsTableView.registerClass(FeedLocationCell.self, forCellReuseIdentifier: feedLocationCellID)
        feedsTableView.registerClass(FeedURLCell.self, forCellReuseIdentifier: feedURLCellID)

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
//            view.addSubview(feedsFPSLabel)
        #endif
    }

    // MARK: Actions
    
    @objc private func addSkillToMe(sender: AnyObject) {
        println("addSkillToMe")
        
        if let skillID = skill?.id, skillLocalName = skill?.localName {
            
            let doAddSkillToSkillSet: SkillSet -> Void = { skillSet in
                
                addSkillWithSkillID(skillID, toSkillSet: skillSet, failureHandler: { reason, errorMessage in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)
                    
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
        
        if let window = view.window {
            filterView.showInView(window)
        }
    }

    private var currentPageIndex = 1
    private var isFetchingFeeds = false
    enum UpdateFeedsMode {
        case Top
        case LoadMore
        case Static
    }
    private func updateFeeds(mode mode: UpdateFeedsMode = .Top, finish: (() -> Void)? = nil) {

        if isFetchingFeeds {
            finish?()
            return
        }

        isFetchingFeeds = true

        if mode == .Top && feeds.isEmpty {
            activityIndicator.startAnimating()
        }

        switch mode {
        case .Top:
            currentPageIndex = 1
        case .LoadMore:
            currentPageIndex++
        case .Static:
            break
        }

        let failureHandler: FailureHandler = { reason, errorMessage in

            dispatch_async(dispatch_get_main_queue()) { [weak self] in

                self?.isFetchingFeeds = false

                self?.activityIndicator.stopAnimating()

                finish?()
            }

            defaultFailureHandler(reason: reason, errorMessage: errorMessage)
        }

        let completion: [DiscoveredFeed] -> Void = { feeds in

            dispatch_async(dispatch_get_main_queue()) { [weak self] in

                self?.isFetchingFeeds = false

                self?.activityIndicator.stopAnimating()

                finish?()
            }

            dispatch_async(dispatch_get_main_queue()) { [weak self] in

                if let strongSelf = self {

                    var newFeeds = feeds
                    let oldFeeds = strongSelf.feeds

                    var wayToUpdate: UITableView.WayToUpdate = .None

                    if strongSelf.feeds.isEmpty {
                        wayToUpdate = .ReloadData
                    }

                    switch mode {

                    case .Top:
                        strongSelf.feeds = newFeeds

                    case .LoadMore:
                        let oldFeedsCount = strongSelf.feeds.count

                        let oldFeedIDSet = Set<String>(strongSelf.feeds.map({ $0.id }))
                        var realNewFeeds = [DiscoveredFeed]()
                        for feed in newFeeds {
                            if !oldFeedIDSet.contains(feed.id) {
                                realNewFeeds.append(feed)
                            }
                        }
                        strongSelf.feeds += realNewFeeds

                        let newFeedsCount = strongSelf.feeds.count

                        let indexPaths = Array(oldFeedsCount..<newFeedsCount).map({ NSIndexPath(forRow: $0, inSection: Section.Feed.rawValue) })
                        if !indexPaths.isEmpty {
                            wayToUpdate = .Insert(indexPaths)
                        }

                        newFeeds = realNewFeeds // 后面还要使用 newFeeds

                    case .Static:
                        var indexesOfMessagesCountUpdated = [Int]()
                        newFeeds.forEach({ feed in
                            if let index = strongSelf.feeds.indexOf(feed) {
                                if strongSelf.feeds[index].messagesCount != feed.messagesCount {
                                    strongSelf.feeds[index].messagesCount = feed.messagesCount
                                    indexesOfMessagesCountUpdated.append(index)
                                }
                            }
                        })

                        let indexPaths = indexesOfMessagesCountUpdated.map({ NSIndexPath(forRow: $0, inSection: Section.Feed.rawValue) })

                        wayToUpdate = .ReloadIndexPaths(indexPaths)
                    }

                    if !wayToUpdate.needsLabor && !newFeeds.isEmpty {

                        var indexesOfMessagesCountUpdated = [Int]()

                        if newFeeds.count == oldFeeds.count {

                            var index = 0
                            while index < newFeeds.count {
                                let newFeed = newFeeds[index]
                                let oldFeed = oldFeeds[index]

                                if newFeed.id != oldFeed.id {
                                    wayToUpdate = .ReloadData
                                    break
                                } else if newFeed.messagesCount != oldFeed.messagesCount {
                                    indexesOfMessagesCountUpdated.append(index)
                                }

                                index += 1
                            }

                        } else {
                            wayToUpdate = .ReloadData
                        }

                        if !wayToUpdate.needsLabor {
                            let indexPaths = indexesOfMessagesCountUpdated.map({ NSIndexPath(forRow: $0, inSection: Section.Feed.rawValue) })

                            wayToUpdate = .ReloadIndexPaths(indexPaths)
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

            let maxFeedID = (mode == .LoadMore && (feedSortStyle == .Time)) ? feeds.last?.id : nil

            discoverFeedsWithSortStyle(feedSortStyle, skill: skill, pageIndex: currentPageIndex, perPage: perPage, maxFeedID: maxFeedID, failureHandler:failureHandler, completion: completion)
        }
    }

    @IBAction private func createNewFeed(sender: AnyObject) {

        if let window = view.window {
            newFeedTypesView.showInView(window)
        }
    }

    /*
    @objc private func updateAudioPlaybackProgress(timer: NSTimer) {

        func updateCellOfFeedAudio(feedAudio: FeedAudio, withCurrentTime currentTime: NSTimeInterval) {

            let feedID = feedAudio.feedID

            for index in 0..<feeds.count {
                let feed = feeds[index]
                if feed.id == feedID {

                    let indexPath = NSIndexPath(forRow: index, inSection: Section.Feed.rawValue)

                    if let cell = feedsTableView.cellForRowAtIndexPath(indexPath) as? FeedVoiceCell {
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
    */

    private func updateCellOfFeedAudio(feedAudio: FeedAudio, withCurrentTime currentTime: NSTimeInterval) {

        let feedID = feedAudio.feedID

        for index in 0..<feeds.count {
            let feed = feeds[index]
            if feed.id == feedID {

                let indexPath = NSIndexPath(forRow: index, inSection: Section.Feed.rawValue)

                if let cell = feedsTableView.cellForRowAtIndexPath(indexPath) as? FeedVoiceCell {
                    cell.audioPlayedDuration = currentTime
                }

                break
            }
        }
    }

    @objc private func updateAudioPlaybackProgress(timer: NSTimer) {

        guard let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio else {
            return
        }

        let currentTime = YepAudioService.sharedManager.audioPlayCurrentTime
        setAudioPlayedDuration(currentTime, ofFeedAudio: playingFeedAudio )
        updateCellOfFeedAudio(playingFeedAudio, withCurrentTime: currentTime)
    }

    @objc private func updateOnlineAudioPlaybackProgress(timer: NSTimer) {

        guard let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio else {
            return
        }

        let currentTime = YepAudioService.sharedManager.aduioOnlinePlayCurrentTime.seconds
        setAudioPlayedDuration(currentTime, ofFeedAudio: playingFeedAudio )
        updateCellOfFeedAudio(playingFeedAudio, withCurrentTime: currentTime)
    }

    // MARK: - Navigation

    private var newFeedViewController: NewFeedViewController?

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        let beforeUploadingFeedAction: (DiscoveredFeed, NewFeedViewController) -> Void = { [weak self] feed, newFeedViewController in

            self?.newFeedViewController = newFeedViewController

            dispatch_async(dispatch_get_main_queue()) {

                if let strongSelf = self {

                    strongSelf.uploadingFeeds.insert(feed, atIndex: 0)

                    let indexPath = NSIndexPath(forRow: 0, inSection: Section.UploadingFeed.rawValue)
                    strongSelf.feedsTableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            }
        }

        let afterCreatedFeedAction: DiscoveredFeed -> Void = { [weak self] feed in

            self?.newFeedViewController = nil

            dispatch_async(dispatch_get_main_queue()) {

                if let strongSelf = self {

                    strongSelf.feedsTableView.beginUpdates()

                    var animation: UITableViewRowAnimation = .Automatic

                    if !strongSelf.uploadingFeeds.isEmpty {

                        strongSelf.uploadingFeeds = []
                        strongSelf.feedsTableView.reloadSections(NSIndexSet(index: Section.UploadingFeed.rawValue), withRowAnimation: .None)

                        animation = .None
                    }

                    strongSelf.feeds.insert(feed, atIndex: 0)
                    let indexPath = NSIndexPath(forRow: 0, inSection: Section.Feed.rawValue)
                    strongSelf.updateFeedsTableViewOrInsertWithIndexPaths([indexPath], animation: animation)
                    
                    strongSelf.feedsTableView.endUpdates()
                }
            }

            joinGroup(groupID: feed.groupID, failureHandler: nil, completion: {
            })
        }

        let getFeedsViewController: () -> FeedsViewController? = { [weak self] in
            return self
        }

        switch identifier {

        case "showProfile":

            let vc = segue.destinationViewController as! ProfileViewController

            if let indexPath = sender as? NSIndexPath, section = Section(rawValue: indexPath.section) {

                switch section {
                case .SkillUsers:
                    break
                case .UploadingFeed:
                    let discoveredUser = uploadingFeeds[indexPath.row].creator
                    vc.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
                case .Feed:
                    let discoveredUser = feeds[indexPath.row].creator
                    vc.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
                case .LoadMore:
                    break
                }
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

            if let indexPath = sender as? NSIndexPath, section = Section(rawValue: indexPath.section) {

                switch section {
                case .SkillUsers:
                    break
                case .UploadingFeed:
                    vc.skill = uploadingFeeds[indexPath.row].skill
                case .Feed:
                    vc.skill = feeds[indexPath.row].skill
                case .LoadMore:
                    break
                }
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

            vc.afterDeletedFeedAction = { feedID in
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    if let strongSelf = self {
                        var deletedFeed: DiscoveredFeed?
                        for feed in strongSelf.feeds {
                            if feed.id == feedID {
                                deletedFeed = feed
                                break
                            }
                        }

                        if let deletedFeed = deletedFeed, index = strongSelf.feeds.indexOf(deletedFeed) {
                            strongSelf.feeds.removeAtIndex(index)

                            let indexPath = NSIndexPath(forRow: index, inSection: Section.Feed.rawValue)
                            strongSelf.feedsTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .None)

                            return
                        }
                    }

                    // 若不能单项删除，给点时间给服务器，防止请求回来的 feeds 包含被删除的
                    delay(0.5) {
                        self?.updateFeeds()
                    }
                }
            }

            vc.conversationDirtyAction = { [weak self] in
                self?.updateFeeds(mode: .Static)
            }

            /*
            vc.syncPlayFeedAudioAction = { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.feedAudioPlaybackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: strongSelf, selector: "updateAudioPlaybackProgress:", userInfo: nil, repeats: true)
            }
            */

            vc.syncPlayFeedAudioAction = { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.feedAudioPlaybackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: strongSelf, selector: "updateOnlineAudioPlaybackProgress:", userInfo: nil, repeats: true)
            }

        case "presentNewFeed":

            guard let
                nvc = segue.destinationViewController as? UINavigationController,
                vc = nvc.topViewController as? NewFeedViewController
            else {
                return
            }

            vc.preparedSkill = skill

            vc.beforeUploadingFeedAction = beforeUploadingFeedAction
            vc.afterCreatedFeedAction = afterCreatedFeedAction
            vc.getFeedsViewController = getFeedsViewController

        case "presentNewFeedVoiceRecord":

            guard let
                nvc = segue.destinationViewController as? UINavigationController,
                vc = nvc.topViewController as? NewFeedVoiceRecordViewController
            else {
                return
            }

            vc.preparedSkill = skill

            vc.beforeUploadingFeedAction = beforeUploadingFeedAction
            vc.afterCreatedFeedAction = afterCreatedFeedAction
            vc.getFeedsViewController = getFeedsViewController

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

        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension FeedsViewController: UITableViewDataSource, UITableViewDelegate {

    private enum Section: Int {
        case SkillUsers
        case UploadingFeed
        case Feed
        case LoadMore
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 4
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            return 0
        }

        switch section {
        case .SkillUsers:
            return (skill == nil) ? 0 : 1
        case .UploadingFeed:
            return uploadingFeeds.count
        case .Feed:
            return feeds.count
        case .LoadMore:
            return feeds.isEmpty ? 0 : 1
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        func cellForFeed(feed: DiscoveredFeed) -> UITableViewCell {

            switch feed.kind {

            case .Text:
                let cell = tableView.dequeueReusableCellWithIdentifier(feedBasicCellID) as! FeedBasicCell
                return cell

            case .URL:
                let cell = tableView.dequeueReusableCellWithIdentifier(feedURLCellID) as! FeedURLCell
                return cell

            case .Image:
                if feed.imageAttachmentsCount == 1 {
                    let cell = tableView.dequeueReusableCellWithIdentifier(feedBiggerImageCellID) as! FeedBiggerImageCell
                    return cell

                } else if feed.imageAttachmentsCount <= 3 {
                    let cell = tableView.dequeueReusableCellWithIdentifier(feedNormalImagesCellID) as! FeedNormalImagesCell
                    return cell

                } else {
                    let cell = tableView.dequeueReusableCellWithIdentifier(feedAnyImagesCellID) as! FeedAnyImagesCell
                    return cell
                }

            case .GithubRepo:
                let cell = tableView.dequeueReusableCellWithIdentifier(feedGithubRepoCellID) as! FeedGithubRepoCell
                return cell

            case .DribbbleShot:
                let cell = tableView.dequeueReusableCellWithIdentifier(feedDribbbleShotCellID) as! FeedDribbbleShotCell
                return cell

            case .Audio:
                let cell = tableView.dequeueReusableCellWithIdentifier(feedVoiceCellID) as! FeedVoiceCell
                return cell

            case .Location:
                let cell = tableView.dequeueReusableCellWithIdentifier(feedLocationCellID) as! FeedLocationCell
                return cell

            default:
                let cell = tableView.dequeueReusableCellWithIdentifier(feedBasicCellID) as! FeedBasicCell
                return cell
            }
        }

        switch section {

        case .SkillUsers:

            let cell = tableView.dequeueReusableCellWithIdentifier(feedSkillUsersCellID) as! FeedSkillUsersCell
            return cell

        case .UploadingFeed:

            let feed = uploadingFeeds[indexPath.row]
            return cellForFeed(feed)

        case .Feed:

            let feed = feeds[indexPath.row]
            return cellForFeed(feed)

        case .LoadMore:

            let cell = tableView.dequeueReusableCellWithIdentifier(loadMoreTableViewCellID) as! LoadMoreTableViewCell
            return cell
        }
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            return
        }

        func configureFeedCell(cell: UITableViewCell, withFeed feed: DiscoveredFeed) {

            guard let cell = cell as? FeedBasicCell else {
                return
            }

            cell.needShowDistance = needShowDistance

            cell.tapAvatarAction = { [weak self] cell in
                if let indexPath = tableView.indexPathForCell(cell) { // 不直接捕捉 indexPath
                    println("tapAvatarAction indexPath: \(indexPath.section), \(indexPath.row)")
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

            let layout = FeedsViewController.layoutPool.feedCellLayoutOfFeed(feed)
            let update: FeedCellLayout.Update = { newLayout in
                FeedsViewController.layoutPool.updateFeedCellLayout(newLayout, forFeed: feed)
            }
            let layoutCache = (layout: layout, update: update)

            switch feed.kind {

            case .Text:

                cell.configureWithFeed(feed, layoutCache: layoutCache, needShowSkill: needShowSkill)

            case .URL:

                guard let cell = cell as? FeedURLCell else {
                    break
                }

                cell.configureWithFeed(feed, layoutCache: layoutCache, needShowSkill: needShowSkill)

                cell.tapURLInfoAction = { [weak self] URL in
                    println("tapURLInfoAction URL: \(URL)")
                    self?.yep_openURL(URL)
                }

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

                    cell.configureWithFeed(feed, layoutCache: layoutCache, needShowSkill: needShowSkill)

                    cell.tapMediaAction = tapMediaAction

                } else if feed.imageAttachmentsCount <= 3 {

                    guard let cell = cell as? FeedNormalImagesCell else {
                        break
                    }

                    cell.configureWithFeed(feed, layoutCache: layoutCache, needShowSkill: needShowSkill)

                    cell.tapMediaAction = tapMediaAction

                } else {
                    guard let cell = cell as? FeedAnyImagesCell else {
                        break
                    }

                    cell.configureWithFeed(feed, layoutCache: layoutCache, needShowSkill: needShowSkill)

                    cell.tapMediaAction = tapMediaAction
                }

            case .GithubRepo:

                guard let cell = cell as? FeedGithubRepoCell else {
                    break
                }

                cell.configureWithFeed(feed, layoutCache: layoutCache, needShowSkill: needShowSkill)

                cell.tapGithubRepoLinkAction = { [weak self] URL in
                    self?.yep_openURL(URL)
                }

            case .DribbbleShot:

                guard let cell = cell as? FeedDribbbleShotCell else {
                    break
                }

                cell.configureWithFeed(feed, layoutCache: layoutCache, needShowSkill: needShowSkill)

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

            case .Audio:

                guard let cell = cell as? FeedVoiceCell else {
                    break
                }

                cell.configureWithFeed(feed, layoutCache: layoutCache, needShowSkill: needShowSkill)

                /*
                cell.playOrPauseAudioAction = { [weak self] cell in

                    guard let realm = try? Realm(), feedAudio = FeedAudio.feedAudioWithFeedID(feed.id, inRealm: realm) else {
                        return
                    }

                    let play: () -> Void = { [weak self] in

                        if let strongSelf = self {

                            let audioPlayedDuration = strongSelf.audioPlayedDurationOfFeedAudio(feedAudio)
                            YepAudioService.sharedManager.playAudioWithFeedAudio(feedAudio, beginFromTime: audioPlayedDuration, delegate: strongSelf, success: {
                                println("playAudioWithFeedAudio success!")

                                strongSelf.feedAudioPlaybackTimer?.invalidate()

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

                                    if let cell = strongSelf.feedsTableView.cellForRowAtIndexPath(indexPath) as? FeedVoiceCell {
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
                */

                cell.playOrPauseAudioAction = { [weak self] cell in

                    guard let realm = try? Realm(), feedAudio = FeedAudio.feedAudioWithFeedID(feed.id, inRealm: realm) else {
                        return
                    }

                    let play: () -> Void = { [weak self] in

                        if let strongSelf = self {

                            NSNotificationCenter.defaultCenter().addObserver(strongSelf, selector: "feedAudioDidFinishPlaying:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)

                            let audioPlayedDuration = strongSelf.audioPlayedDurationOfFeedAudio(feedAudio)
                            YepAudioService.sharedManager.playOnlineAudioWithFeedAudio(feedAudio, beginFromTime: audioPlayedDuration, delegate: strongSelf, success: {
                                println("playOnlineAudioWithFeedAudio success!")

                                strongSelf.feedAudioPlaybackTimer?.invalidate()

                                let playbackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: strongSelf, selector: "updateOnlineAudioPlaybackProgress:", userInfo: nil, repeats: true)
                                YepAudioService.sharedManager.playbackTimer = playbackTimer

                                cell.audioPlaying = true
                            })
                        }
                    }

                    if let strongSelf = self {

                        // 如果在播放，就暂停
                        if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio, onlineAudioPlayer = YepAudioService.sharedManager.onlineAudioPlayer where onlineAudioPlayer.yep_playing {

                            onlineAudioPlayer.pause()

                            if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
                                playbackTimer.invalidate()
                            }

                            let feedID = playingFeedAudio.feedID
                            for index in 0..<strongSelf.feeds.count {
                                let feed = strongSelf.feeds[index]
                                if feed.id == feedID {

                                    let indexPath = NSIndexPath(forRow: index, inSection: Section.Feed.rawValue)

                                    if let cell = strongSelf.feedsTableView.cellForRowAtIndexPath(indexPath) as? FeedVoiceCell {
                                        cell.audioPlaying = false
                                    }

                                    break
                                }
                            }

                            if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio where playingFeedAudio.feedID == feed.id {
                                YepAudioService.sharedManager.tryNotifyOthersOnDeactivation()

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

            case .Location:

                guard let cell = cell as? FeedLocationCell else {
                    break
                }

                cell.configureWithFeed(feed, layoutCache: layoutCache, needShowSkill: needShowSkill)

                cell.tapLocationAction = { locationName, locationCoordinate in

                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                    mapItem.name = locationName

                    mapItem.openInMapsWithLaunchOptions(nil)
                }

            default:
                break
            }
        }

        switch section {

        case .SkillUsers:

            guard let cell = cell as? FeedSkillUsersCell else {
                break
            }

            cell.configureWithFeeds(feeds)

        case .UploadingFeed:

            let feed = uploadingFeeds[indexPath.row]
            configureFeedCell(cell, withFeed: feed)

            if let cell = cell as? FeedBasicCell {

                cell.retryUploadingFeedAction = { [weak self] cell in

                    self?.newFeedViewController?.post(again: true)

                    if let indexPath = self?.feedsTableView.indexPathForCell(cell) {
                        self?.uploadingFeeds[indexPath.row].uploadingErrorMessage = nil
                        cell.hasUploadingErrorMessage = false
                    }
                }

                cell.deleteUploadingFeedAction = { [weak self] cell in

                    if let indexPath = self?.feedsTableView.indexPathForCell(cell) {
                        self?.uploadingFeeds.removeAtIndex(indexPath.row)
                        self?.feedsTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

                        self?.newFeedViewController = nil
                    }
                }
            }

        case .Feed:

            let feed = feeds[indexPath.row]
            configureFeedCell(cell, withFeed: feed)

        case .LoadMore:

            guard let cell = cell as? LoadMoreTableViewCell else {
                break
            }

            println("load more feeds")

            if !cell.loadingActivityIndicator.isAnimating() {
                cell.loadingActivityIndicator.startAnimating()
            }

            updateFeeds(mode: .LoadMore, finish: { [weak cell] in
                cell?.loadingActivityIndicator.stopAnimating()
            })
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        guard let section = Section(rawValue: indexPath.section) else {
            return 0
        }

        switch section {

        case .SkillUsers:
            return 70

        case .UploadingFeed:
            let feed = uploadingFeeds[indexPath.row]
            return FeedsViewController.layoutPool.heightOfFeed(feed)

        case .Feed:
            let feed = feeds[indexPath.row]
            return FeedsViewController.layoutPool.heightOfFeed(feed)

        case .LoadMore:
            return 60
        }
    }

    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return indexPath
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        guard let section = Section(rawValue: indexPath.section) else {
            return
        }

        switch section {

        case .SkillUsers:
            performSegueWithIdentifier("showSkillHome", sender: nil)

        case .UploadingFeed:
            break

        case .Feed:
            performSegueWithIdentifier("showConversation", sender: indexPath)

        case .LoadMore:
            break
        }
    }

    // Report

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {

        guard let section = Section(rawValue: indexPath.section) else {
            return false
        }

        switch section {

        case .SkillUsers:
            return false

        case .UploadingFeed:
            return false

        case .Feed:
            let feed = feeds[indexPath.item]
            if feed.creator.id == YepUserDefaults.userID.value {
                return false
            } else {
                return true
            }

        case .LoadMore:
            return false
        }
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {

        guard let section = Section(rawValue: indexPath.section) else {
            return nil
        }

        if case .Feed = section {

            let reportAction = UITableViewRowAction(style: .Default, title: NSLocalizedString("Report", comment: "")) { [weak self] action, indexPath in

                if let feed = self?.feeds[indexPath.row] {
                    self?.report(.Feed(feed))
                }

                tableView.setEditing(false, animated: true)
            }

            return [reportAction]
        }

        return nil
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }

    // MARK: Copy Message

    @objc private func didRecieveMenuWillHideNotification(notification: NSNotification) {

        selectedIndexPathForMenu = nil
    }

    @objc private func didRecieveMenuWillShowNotification(notification: NSNotification) {

        guard let menu = notification.object as? UIMenuController, selectedIndexPathForMenu = selectedIndexPathForMenu, cell = feedsTableView.cellForRowAtIndexPath(selectedIndexPathForMenu) as? FeedBasicCell else {
            return
        }

        let bubbleFrame = cell.convertRect(cell.messageTextView.frame, toView: view)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIMenuControllerWillShowMenuNotification, object: nil)

        menu.setTargetRect(bubbleFrame, inView: view)
        menu.setMenuVisible(true, animated: true)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didRecieveMenuWillShowNotification:", name: UIMenuControllerWillShowMenuNotification, object: nil)

        feedsTableView.deselectRowAtIndexPath(selectedIndexPathForMenu, animated: true)
    }

    func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {

        defer {
            selectedIndexPathForMenu = indexPath
        }

        guard let _ = tableView.cellForRowAtIndexPath(indexPath) as? FeedBasicCell else {
            return false
        }

        return true
    }

    func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {

        if action == "copy:" {
            return true
        }

        return false
    }

    func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {

        guard let cell = tableView.cellForRowAtIndexPath(indexPath) as? FeedBasicCell else {
            return
        }

        if action == "copy:" {
            UIPasteboard.generalPasteboard().string = cell.messageTextView.text
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
            delay(0.3) { // 人为延迟，增加等待感
                pulllToRefreshView.endRefreshingAndDoFurtherAction() {}

                self?.activityIndicator.alpha = 1
            }
        }

        pullToRefreshView.refreshTimeoutAction = finish

        updateFeeds(finish: finish)
    }

    func scrollView() -> UIScrollView {
        return feedsTableView
    }
}

// MARK: Audio Finish Playing

extension FeedsViewController {

    private func feedAudioDidFinishPlaying() {

        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
            playbackTimer.invalidate()
        }

        if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio {
            setAudioPlayedDuration(0, ofFeedAudio: playingFeedAudio)
            println("setAudioPlayedDuration to 0")
        }

        YepAudioService.sharedManager.resetToDefault()
    }

    @objc private func feedAudioDidFinishPlaying(notification: NSNotification) {
        feedAudioDidFinishPlaying()
    }
}

// MARK: AVAudioPlayerDelegate

extension FeedsViewController: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {

        println("audioPlayerDidFinishPlaying \(flag)")

        feedAudioDidFinishPlaying()
    }
}


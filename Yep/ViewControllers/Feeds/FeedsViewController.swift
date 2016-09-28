//
//  FeedsViewController.swift
//  Yep
//
//  Created by nixzhu on 15/9/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import YepKit
import YepNetworking
import YepPreview
import AVFoundation
import MapKit
import Ruler

final class FeedsViewController: BaseViewController, CanScrollsToTop {

    static let feedNormalImagesCountThreshold: Int = Ruler.universalHorizontal(3, 3, 4, 3, 4).value

    var skill: Skill?
    var needShowSkill: Bool {
        return (skill == nil) ? true : false
    }

    var profileUser: ProfileUser?
    var preparedFeedsCount = 0
    
    var hideRightBarItem: Bool = false

    var uploadingFeeds = [DiscoveredFeed]()
    func handleUploadingErrorMessage(_ message: String) {
        if !uploadingFeeds.isEmpty {
            uploadingFeeds[0].uploadingErrorMessage = message
            feedsTableView.reloadSections(IndexSet(integer: Section.uploadingFeed.rawValue), with: .none)

            println("handleUploadingErrorMessage: \(message)")
        }
    }
    var feeds = [DiscoveredFeed]()

    fileprivate var blockedFeeds = false {
        didSet {
            moreViewManager.blockedFeeds = blockedFeeds
        }
    }
    fileprivate lazy var moreViewManager: FeedsMoreViewManager = {

        let manager = FeedsMoreViewManager()

        manager.toggleBlockFeedsAction = { [weak self] in
            self?.toggleBlockFeeds()
        }

        return manager
    }()

    fileprivate lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.setSearchFieldBackgroundImage(UIImage.yep_searchbarTextfieldBackground, for: UIControlState())
        searchBar.delegate = self
        return searchBar
    }()

    var originalNavigationControllerDelegate: UINavigationControllerDelegate?
    lazy var searchTransition: SearchTransition = {
        return SearchTransition()
    }()

    fileprivate lazy var noFeedsFooterView: InfoView = InfoView(String.trans_promptNoFeeds)
    fileprivate lazy var fetchFailedFooterView: InfoView = InfoView(String.trans_errorFetchFailed)

    @IBOutlet fileprivate weak var feedsTableView: UITableView!  {
        didSet {
            searchBar.sizeToFit()
            feedsTableView.tableHeaderView = searchBar

            feedsTableView.backgroundColor = UIColor.white
            feedsTableView.tableFooterView = UIView()
            feedsTableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine

            feedsTableView.registerNibOf(FeedSkillUsersCell.self)
            feedsTableView.registerNibOf(FeedFilterCell.self)

            feedsTableView.registerClassOf(FeedBasicCell.self)
            feedsTableView.registerClassOf(FeedBiggerImageCell.self)
            feedsTableView.registerClassOf(FeedNormalImagesCell.self)
            feedsTableView.registerClassOf(FeedAnyImagesCell.self)

            feedsTableView.registerClassOf(FeedGithubRepoCell.self)
            feedsTableView.registerClassOf(FeedDribbbleShotCell.self)
            feedsTableView.registerClassOf(FeedVoiceCell.self)
            feedsTableView.registerClassOf(FeedLocationCell.self)
            feedsTableView.registerClassOf(FeedURLCell.self)

            feedsTableView.registerNibOf(LoadMoreTableViewCell.self)
        }
    }

    // PullToRefreshViewDelegate
    // CanScrollsToTop
    var scrollView: UIScrollView? {
        return feedsTableView
    }

    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var activityIndicatorTopConstraint: NSLayoutConstraint!

    fileprivate var selectedIndexPathForMenu: IndexPath?

    fileprivate var filterBarItem: UIBarButtonItem?
    
    fileprivate lazy var filterStyles: [FeedSortStyle] = [
        .Distance,
        .Time,
        .Match,
    ]

    fileprivate func filterItemWithSortStyle(_ sortStyle: FeedSortStyle, currentSortStyle: FeedSortStyle) -> ActionSheetView.Item {
        return .check(
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

    fileprivate func filterItemsWithCurrentSortStyle(_ currentSortStyle: FeedSortStyle) -> [ActionSheetView.Item] {
        var items = filterStyles.map({
            filterItemWithSortStyle($0, currentSortStyle: currentSortStyle)
        })
        items.append(.cancel)
        return items
    }

    fileprivate lazy var filterView: ActionSheetView = {
        let view = ActionSheetView(items: self.filterItemsWithCurrentSortStyle(self.feedSortStyle))
        return view
    }()

    fileprivate lazy var newFeedTypesView: ActionSheetView = {
        let view = ActionSheetView(items: [
            .default(
                title: NSLocalizedString("Text & Photos", comment: ""),
                titleColor: UIColor.yepTintColor(),
                action: { [weak self] in
                    self?.performSegue(withIdentifier: "presentNewFeed", sender: nil)
                    return true
                }
            ),
            .default(
                title: NSLocalizedString("Voice", comment: ""),
                titleColor: UIColor.yepTintColor(),
                action: { [weak self] in
                    self?.performSegue(withIdentifier: "presentNewFeedVoiceRecord", sender: nil)
                    return true
                }
            ),
            .default(
                title: String.trans_titleLocation,
                titleColor: UIColor.yepTintColor(),
                action: { [weak self] in
                    self?.performSegue(withIdentifier: "presentPickLocation", sender: nil)
                    return true
                }
            ),
            .cancel,
            ]
        )
        return view
    }()

    fileprivate lazy var skillTitleView: UIView = {

        let titleLabel = UILabel()

        let textAttributes = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont.skillHomeTextLargeFont()
        ]

        let titleAttr = NSMutableAttributedString(string: self.skill?.localName ?? "", attributes:textAttributes)

        titleLabel.attributedText = titleAttr
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.backgroundColor = UIColor.yepTintColor()
        titleLabel.sizeToFit()

        titleLabel.bounds = titleLabel.frame.insetBy(dx: -25.0, dy: -4.0)

        titleLabel.layer.cornerRadius = titleLabel.frame.size.height/2.0
        titleLabel.layer.masksToBounds = true

        return titleLabel
    }()

    lazy var pullToRefreshView: PullToRefreshView = {

        let pullToRefreshView = PullToRefreshView()
        pullToRefreshView.delegate = self

        self.feedsTableView.insertSubview(pullToRefreshView, at: 0)

        pullToRefreshView.frame = CGRect(x: 0, y: -200, width: self.view.bounds.width, height: 200)

        return pullToRefreshView
    }()

    #if DEBUG
    private lazy var feedsFPSLabel: FPSLabel = {
        let label = FPSLabel()
        return label
    }()
    #endif

    fileprivate var audioPlayedDurations = [String: TimeInterval]()

    fileprivate weak var feedAudioPlaybackTimer: Timer?

    fileprivate func audioPlayedDurationOfFeedAudio(_ feedAudio: FeedAudio) -> TimeInterval {
        let key = feedAudio.feedID

        if !key.isEmpty {
            if let playedDuration = audioPlayedDurations[key] {
                return playedDuration
            }
        }

        return 0
    }

    fileprivate func setAudioPlayedDuration(_ audioPlayedDuration: TimeInterval, ofFeedAudio feedAudio: FeedAudio) {
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

                    let indexPath = IndexPath(row: index, section: Section.feed.rawValue)

                    if let cell = feedsTableView.cellForRow(at: indexPath) as? FeedVoiceCell {
                        cell.audioPlayedDuration = 0
                    }

                    break
                }
            }
        }
    }

    fileprivate func updateFeedsTableViewOrInsertWithIndexPaths(_ indexPaths: [IndexPath]?, animation: UITableViewRowAnimation? = nil) {

        // refresh skillUsers

        let skillUsersIndexPath = IndexPath(row: 0, section: Section.skillUsers.rawValue)
        if let cell = feedsTableView.cellForRow(at: skillUsersIndexPath) as? FeedSkillUsersCell {
            cell.configureWithFeeds(feeds)
        }

        if let indexPaths = indexPaths, feeds.count > 1 {
            // insert
            feedsTableView.insertRows(at: indexPaths, with: animation ?? .automatic)

        } else {
            // or reload
            feedsTableView.reloadData()
        }

        feedsTableView.tableFooterView = feeds.isEmpty ? noFeedsFooterView : UIView()
    }

    fileprivate struct LayoutPool {

        fileprivate var feedCellLayoutHash = [String: FeedCellLayout]()

        fileprivate mutating func feedCellLayoutOfFeed(_ feed: DiscoveredFeed) -> FeedCellLayout {
            let key = feed.id

            if let layout = feedCellLayoutHash[key] {
                return layout

            } else {
                let layout = FeedCellLayout(feed: feed)

                updateFeedCellLayout(layout, forFeed: feed)

                return layout
            }
        }

        fileprivate mutating func updateFeedCellLayout(_ layout: FeedCellLayout, forFeed feed: DiscoveredFeed) {

            let key = feed.id

            if !key.isEmpty {
                feedCellLayoutHash[key] = layout
            }

            //println("feedCellLayoutHash.count: \(feedCellLayoutHash.count)")
        }

        fileprivate mutating func heightOfFeed(_ feed: DiscoveredFeed) -> CGFloat {

            let layout = feedCellLayoutOfFeed(feed)
            return layout.height
        }
    }
    fileprivate static var layoutPool = LayoutPool()

    fileprivate var needShowDistance: Bool = false
    fileprivate var feedSortStyle: FeedSortStyle = .Match {
        didSet {
            needShowDistance = (feedSortStyle == .Distance)

            feeds = []
            feedsTableView.reloadData()

            UIView.performWithoutAnimation { [weak self] in
                self?.filterBarItem?.title = self?.feedSortStyle.nameWithArrow
            }

            updateFeeds()

            YepUserDefaults.feedSortStyle.value = feedSortStyle.rawValue
        }
    }

    //var navigationControllerDelegate: ConversationMessagePreviewNavigationControllerDelegate?
    //var originalNavigationControllerDelegate: UINavigationControllerDelegate?

    fileprivate var previewReferences: [Reference?]?
    fileprivate var previewAttachmentPhotos: [PreviewAttachmentPhoto] = []
    fileprivate var previewDribbblePhotos: [PreviewDribbblePhoto] = []

    deinit {
        NotificationCenter.default.removeObserver(self)
        feedsTableView?.delegate = nil

        println("deinit Feeds")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        pullToRefreshView.frame.size.width = view.bounds.width
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 优先处理侧滑，而不是 scrollView 的上下滚动，避免出现你想侧滑返回的时候，结果触发了 scrollView 的上下滚动
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) {
                    feedsTableView.panGestureRecognizer.require(toFail: recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }

        navigationItem.title = String.trans_titleFeeds

        searchBar.placeholder = NSLocalizedString("Search Feeds", comment: "")

        if skill != nil {
            searchBar.placeholder = NSLocalizedString("Search feeds in channel", comment: "")
            //activityIndicatorTopConstraint.constant = 200
        }

        if profileUser != nil {
            searchBar.placeholder = NSLocalizedString("Search feeds by user", comment: "")
        }

        feedsTableView.separatorColor = UIColor.yepCellSeparatorColor()
        feedsTableView.contentOffset.y = searchBar.frame.height

        NotificationCenter.default.addObserver(self, selector: #selector(FeedsViewController.didRecieveMenuWillShowNotification(_:)), name: Notification.Name.UIMenuControllerWillShowMenu, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedsViewController.didRecieveMenuWillHideNotification(_:)), name: Notification.Name.UIMenuControllerWillHideMenu, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedsViewController.feedAudioDidFinishPlaying(_:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)

        if skill != nil {
            navigationItem.titleView = skillTitleView

            filterOption = .recommended

            // Add to Me
            
            if let skillID = skill?.id, let me = me() {

                let predicate = NSPredicate(format: "skillID = %@", skillID)
                let notInMaster = me.masterSkills.filter(predicate).count == 0
                if notInMaster && me.learningSkills.filter(predicate).count == 0 {
                    let addSkillToMeButton = UIBarButtonItem(title: NSLocalizedString("button.add_skill_to_me", comment: ""), style: .plain, target: self, action: #selector(FeedsViewController.addSkillToMe(_:)))
                    navigationItem.rightBarButtonItem = addSkillToMeButton
                }
            }

        } else if profileUser != nil {
            // do nothing

        } else {
            filterBarItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: self, action: #selector(FeedsViewController.showFilter(_:)))
            navigationItem.leftBarButtonItem = filterBarItem

            NotificationCenter.default.addObserver(self, selector: #selector(FeedsViewController.hideFeedsByCrearor(_:)), name: YepConfig.NotificationName.blockedFeedsByCreator, object: nil)
        }

        if hideRightBarItem {
            if profileUser?.isMe ?? false {
                navigationItem.rightBarButtonItem = nil

            } else {
                let moreBarButtonItem = UIBarButtonItem(image: UIImage.yep_iconMore, style: .plain, target: self, action: #selector(FeedsViewController.moreAction(_:)))
                navigationItem.rightBarButtonItem = moreBarButtonItem

                if let userID = profileUser?.userID {
                    amIBlockedFeedsFromCreator(userID: userID, failureHandler: nil, completion: { [weak self] blocked in
                        self?.blockedFeeds = blocked
                    })
                }
            }
        }

        // 没有 profileUser 才设置 feedSortStyle 以请求服务器
        if profileUser == nil {

            if let
                value = YepUserDefaults.feedSortStyle.value,
                let _feedSortStyle = FeedSortStyle(rawValue: value) {
                    feedSortStyle = _feedSortStyle
                    
            } else {
                feedSortStyle = .Match
            }

            if skill == nil {
                if let realm = try? Realm(), let offlineJSON = OfflineJSON.withName(.Feeds, inRealm: realm) {
                    if let JSON = offlineJSON.JSON, let feeds = parseFeeds(JSON) {
                        self.feeds = feeds.flatMap({ $0 })
                        activityIndicator.stopAnimating()
                    }
                }
            }
        }

        if preparedFeedsCount > 0 {
            currentPageIndex = 2
        } else {
            updateFeeds()
        }

        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: feedsTableView)
        }

        #if DEBUG
            //view.addSubview(feedsFPSLabel)
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        recoverOriginalNavigationDelegate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if blockedFeeds {
            if let userID = profileUser?.userID {
                NotificationCenter.default.post(name: YepConfig.NotificationName.blockedFeedsByCreator, object: userID)
            }
        }
    }

    // MARK: - Actions

    @objc fileprivate func addSkillToMe(_ sender: AnyObject) {
        println("addSkillToMe")
        
        if let skillID = skill?.id, let skillLocalName = skill?.localName {
            
            let doAddSkillToSkillSet: (SkillSet) -> Void = { skillSet in
                
                addSkillWithSkillID(skillID, toSkillSet: skillSet, failureHandler: { reason, errorMessage in
                    defaultFailureHandler(reason, errorMessage)
                    
                }, completion: { [weak self] _ in

                    let message = String.trans_promptSuccessfullyAddedSkill(skillLocalName, to: skillSet.name)
                    YepAlert.alert(title: NSLocalizedString("Success", comment: ""), message: message, dismissTitle: String.trans_titleOK, inViewController: self, withDismissAction: nil)
                    
                    SafeDispatch.async {
                        self?.navigationItem.rightBarButtonItem = nil
                    }
                    
                    syncMyInfoAndDoFurtherAction {
                    }
                })
            }
            
            let alertController = UIAlertController(title: String.trans_titleChooseSkillSet, message: String(format: NSLocalizedString("Which skill set do you want %@ to be?", comment: ""), skillLocalName), preferredStyle: .alert)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: String.trans_cancel, style: .cancel) { action in
            }
            alertController.addAction(cancelAction)
            
            let learningAction: UIAlertAction = UIAlertAction(title: SkillSet.learning.name, style: .default) { action in
                doAddSkillToSkillSet(.learning)
            }
            alertController.addAction(learningAction)
            
            let masterAction: UIAlertAction = UIAlertAction(title: SkillSet.master.name, style: .default) { action in
                doAddSkillToSkillSet(.master)
            }
            alertController.addAction(masterAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }

    @objc fileprivate func showFilter(_ sender: AnyObject) {
        
        if let window = view.window {
            filterView.showInView(window)
        }
    }

    @objc fileprivate func moreAction(_ sender: AnyObject) {

        if let window = view.window {
            moreViewManager.moreView.showInView(window)
        }
    }

    fileprivate var canLoadMore: Bool = false
    fileprivate var currentPageIndex = 1
    fileprivate var isFetchingFeeds = false
    fileprivate var filterOption: FeedFilterCell.Option? {
        didSet {
            updateFeeds()
        }
    }
    enum UpdateFeedsMode {
        case top
        case loadMore
    }
    fileprivate func updateFeeds(mode: UpdateFeedsMode = .top, finish: (() -> Void)? = nil) {

        if isFetchingFeeds {
            finish?()
            return
        }

        isFetchingFeeds = true

        if mode == .top && feeds.isEmpty {
            activityIndicator.startAnimating()
        }

        switch mode {
        case .top:
            canLoadMore = true
            currentPageIndex = 1
        case .loadMore:
            currentPageIndex += 1
        }

        let failureHandler: FailureHandler = { reason, errorMessage in

            SafeDispatch.async { [weak self] in

                self?.feedsTableView.tableFooterView = self?.fetchFailedFooterView

                self?.isFetchingFeeds = false

                self?.activityIndicator.stopAnimating()

                finish?()
            }

            defaultFailureHandler(reason, errorMessage)
        }

        let perPage = 20

        let completion: ([DiscoveredFeed?]) -> Void = { feeds in

            let originalFeedsCount = feeds.count
            println("new feeds.count: \(originalFeedsCount)")
            let validFeeds = feeds.flatMap({ $0 })

            SafeDispatch.async { [weak self] in

                if case .top = mode, validFeeds.isEmpty {
                    self?.feedsTableView.tableFooterView = self?.noFeedsFooterView
                } else {
                    self?.feedsTableView.tableFooterView = UIView()
                }

                self?.canLoadMore = (originalFeedsCount == perPage)

                self?.isFetchingFeeds = false

                self?.activityIndicator.stopAnimating()

                finish?()
            }

            SafeDispatch.async { [weak self] in

                if let strongSelf = self {

                    let newFeeds = validFeeds
                    let oldFeeds = strongSelf.feeds

                    var wayToUpdate: UITableView.WayToUpdate = .none

                    if strongSelf.feeds.isEmpty {
                        wayToUpdate = .reloadData
                    }

                    switch mode {

                    case .top:
                        strongSelf.feeds = newFeeds

                        if Set(oldFeeds.map({ $0.id })) == Set(newFeeds.map({ $0.id })) {
                            wayToUpdate = .none

                        } else {
                            wayToUpdate = .reloadData
                        }

                    case .loadMore:
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

                        let indexPaths = Array(oldFeedsCount..<newFeedsCount).map({ IndexPath(row: $0, section: Section.feed.rawValue) })
                        if !indexPaths.isEmpty {
                            wayToUpdate = .insert(indexPaths)
                        }
                    }

                    // 前面都没导致更新且有新feeds数量和旧feeds一致，再根据 messagesCount 来判断
                    if !wayToUpdate.needsLabor && !newFeeds.isEmpty {

                        var indexesOfMessagesCountUpdated = [Int]()

                        if newFeeds.count == oldFeeds.count {

                            var index = 0
                            while index < newFeeds.count {
                                let newFeed = newFeeds[index]
                                let oldFeed = oldFeeds[index]

                                if newFeed.id != oldFeed.id {
                                    wayToUpdate = .reloadData
                                    break
                                } else if newFeed.messagesCount != oldFeed.messagesCount {
                                    indexesOfMessagesCountUpdated.append(index)
                                }

                                index += 1
                            }

                        } else {
                            wayToUpdate = .reloadData
                        }

                        if !wayToUpdate.needsLabor {
                            let indexPaths = indexesOfMessagesCountUpdated.map({ IndexPath(row: $0, section: Section.feed.rawValue) })

                            println("defer indexPaths.count: \(indexPaths.count)")
                            wayToUpdate = .reloadIndexPaths(indexPaths)
                        }
                    }

                    wayToUpdate.performWithTableView(strongSelf.feedsTableView)
                }
            }
        }

        if let profileUser = profileUser {
            feedsOfUser(profileUser.userID, pageIndex: currentPageIndex, perPage: (preparedFeedsCount > 0) ? preparedFeedsCount : perPage, failureHandler: failureHandler, completion: completion)

        } else {
            var feedSortStyle = self.feedSortStyle

            if skill != nil {
                feedSortStyle = .Time
            }

            let maxFeedID: String?
            if case .loadMore = mode, feedSortStyle.needPageFeedID {
                maxFeedID = feeds.last?.id
            } else {
                maxFeedID = nil
            }

            println("currentPageIndex: \(currentPageIndex)")
            println("maxFeedID: \(maxFeedID)")

            discoverFeedsWithSortStyle(feedSortStyle, skill: skill, pageIndex: currentPageIndex, perPage: perPage, maxFeedID: maxFeedID, failureHandler:failureHandler, completion: completion)
        }
    }

    @IBAction fileprivate func createNewFeed(_ sender: AnyObject) {

        guard let avatarURLString = YepUserDefaults.avatarURLString.value, !avatarURLString.isEmpty else {

            YepAlert.alertSorry(message: NSLocalizedString("You have no avatar! Please set up one first.", comment: ""), inViewController: self)

            return
        }

        if let window = view.window {
            newFeedTypesView.showInView(window)
        }
    }

    fileprivate func updateCellOfFeedAudio(_ feedAudio: FeedAudio, withCurrentTime currentTime: TimeInterval) {

        let feedID = feedAudio.feedID

        for index in 0..<feeds.count {
            let feed = feeds[index]
            if feed.id == feedID {

                let indexPath = IndexPath(row: index, section: Section.feed.rawValue)

                if let cell = feedsTableView.cellForRow(at: indexPath) as? FeedVoiceCell {
                    cell.audioPlayedDuration = currentTime
                }

                break
            }
        }
    }

    @objc fileprivate func updateAudioPlaybackProgress(_ timer: Timer) {

        guard let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio else {
            return
        }

        let currentTime = YepAudioService.sharedManager.audioPlayCurrentTime
        setAudioPlayedDuration(currentTime, ofFeedAudio: playingFeedAudio )
        updateCellOfFeedAudio(playingFeedAudio, withCurrentTime: currentTime)
    }

    @objc fileprivate func updateOnlineAudioPlaybackProgress(_ timer: Timer) {

        guard let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio else {
            return
        }

        let currentTime = YepAudioService.sharedManager.aduioOnlinePlayCurrentTime.seconds
        setAudioPlayedDuration(currentTime, ofFeedAudio: playingFeedAudio )
        updateCellOfFeedAudio(playingFeedAudio, withCurrentTime: currentTime)
    }

    fileprivate func toggleBlockFeeds() {

        guard let userID = profileUser?.userID else {
            return
        }

        if blockedFeeds {
            unblockFeedsFromCreator(userID: userID, failureHandler: nil, completion: { [weak self] in
                self?.blockedFeeds = false
            })
        } else {
            blockFeedsFromCreator(userID: userID, failureHandler: nil, completion: { [weak self] in
                self?.blockedFeeds = true
            })
        }
    }

    @objc fileprivate func hideFeedsByCrearor(_ notifcation: Notification) {

        if let userID = notifcation.object as? String {
            println("hideFeedsByCreator: \(userID)")

            feeds = feeds.filter({ $0.creator.userID != userID })
            SafeDispatch.async { [weak self] in
                self?.feedsTableView.reloadData()
            }
        }
    }

    // MARK: - Navigation

    fileprivate var newFeedViewController: NewFeedViewController?

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else {
            return
        }

        let beforeUploadingFeedAction: (DiscoveredFeed, NewFeedViewController) -> Void = { [weak self] feed, newFeedViewController in

            self?.newFeedViewController = newFeedViewController

            SafeDispatch.async {

                if let strongSelf = self {

                    strongSelf.feedsTableView.yep_scrollsToTop()

                    strongSelf.feedsTableView.beginUpdates()

                    strongSelf.uploadingFeeds.insert(feed, at: 0)

                    let indexPath = IndexPath(row: 0, section: Section.uploadingFeed.rawValue)
                    strongSelf.feedsTableView.insertRows(at: [indexPath], with: .automatic)

                    strongSelf.feedsTableView.endUpdates()
                }
            }
        }

        let afterCreatedFeedAction: (DiscoveredFeed) -> Void = { [weak self] feed in

            self?.newFeedViewController = nil

            SafeDispatch.async { [weak self] in

                guard let strongSelf = self else { return }

                strongSelf.feedsTableView.yep_scrollsToTop()

                strongSelf.feedsTableView.beginUpdates()

                var animation: UITableViewRowAnimation = .automatic

                if !strongSelf.uploadingFeeds.isEmpty {

                    strongSelf.uploadingFeeds = []
                    strongSelf.feedsTableView.reloadSections(IndexSet(integer: Section.uploadingFeed.rawValue), with: .none)

                    animation = .none
                }

                strongSelf.feeds.insert(feed, at: 0)
                let indexPath = IndexPath(row: 0, section: Section.feed.rawValue)
                strongSelf.updateFeedsTableViewOrInsertWithIndexPaths([indexPath], animation: animation)
                
                strongSelf.feedsTableView.endUpdates()
            }

            joinGroup(groupID: feed.groupID, failureHandler: nil, completion: {})
        }

        let getFeedsViewController: () -> FeedsViewController? = { [weak self] in
            return self
        }

        switch identifier {

        case "showSearchFeeds":

            let vc = segue.destination as! SearchFeedsViewController
            vc.originalNavigationControllerDelegate = navigationController?.delegate

            vc.skill = skill
            vc.profileUser = profileUser

            vc.hidesBottomBarWhenPushed = true

            prepareSearchTransition()

        case "showProfile":

            let vc = segue.destination as! ProfileViewController

            if let indexPath = sender as? IndexPath, let section = Section(rawValue: (indexPath as NSIndexPath).section) {

                switch section {
                case .skillUsers:
                    break
                case .filter:
                    break
                case .uploadingFeed:
                    let discoveredUser = uploadingFeeds[indexPath.row].creator
                    vc.prepare(with: discoveredUser)
                case .feed:
                    let discoveredUser = feeds[indexPath.row].creator
                    vc.prepare(with: discoveredUser)
                case .loadMore:
                    break
                }
            }

            recoverOriginalNavigationDelegate()

        case "showSkillHome":

            let vc = segue.destination as! SkillHomeViewController

            if let skill = skill {
                vc.skill = SkillCellSkill(ID: skill.id, localName: skill.localName, coverURLString: skill.coverURLString, category: nil)
            }

            vc.hidesBottomBarWhenPushed = true

            recoverOriginalNavigationDelegate()

        case "showFeedsWithSkill":

            let vc = segue.destination as! FeedsViewController

            if let indexPath = sender as? IndexPath, let section = Section(rawValue: (indexPath as NSIndexPath).section) {

                switch section {
                case .skillUsers:
                    break
                case .filter:
                    break
                case .uploadingFeed:
                    vc.skill = uploadingFeeds[indexPath.row].skill
                case .feed:
                    vc.skill = feeds[indexPath.row].skill
                case .loadMore:
                    break
                }
            }

            vc.hidesBottomBarWhenPushed = true

            recoverOriginalNavigationDelegate()

        case "showConversation":

            let vc = segue.destination as! ConversationViewController

            guard let
                indexPath = sender as? IndexPath,
                let feed = feeds[safe: indexPath.row],
                let realm = try? Realm() else {
                    return
            }

            prepareConversationViewController(vc, withDiscoveredFeed: feed, inRealm: realm)

            recoverOriginalNavigationDelegate()

        case "presentNewFeed":

            guard let
                nvc = segue.destination as? UINavigationController,
                let vc = nvc.topViewController as? NewFeedViewController
            else {
                return
            }

            vc.preparedSkill = skill

            vc.beforeUploadingFeedAction = beforeUploadingFeedAction
            vc.afterCreatedFeedAction = afterCreatedFeedAction
            vc.getFeedsViewController = getFeedsViewController

            recoverOriginalNavigationDelegate()

        case "presentNewFeedVoiceRecord":

            guard let
                nvc = segue.destination as? UINavigationController,
                let vc = nvc.topViewController as? NewFeedVoiceRecordViewController
            else {
                return
            }

            vc.preparedSkill = skill

            vc.beforeUploadingFeedAction = beforeUploadingFeedAction
            vc.afterCreatedFeedAction = afterCreatedFeedAction
            vc.getFeedsViewController = getFeedsViewController

            recoverOriginalNavigationDelegate()

        case "presentPickLocation":

            guard let
                nvc = segue.destination as? UINavigationController,
                let vc = nvc.topViewController as? PickLocationViewController
            else {
                return
            }

            vc.purpose = .feed

            vc.preparedSkill = skill

            vc.afterCreatedFeedAction = afterCreatedFeedAction

            recoverOriginalNavigationDelegate()

        default:
            break
        }
    }

    fileprivate func prepareConversationViewController(_ vc: ConversationViewController, withDiscoveredFeed feed: DiscoveredFeed, inRealm realm: Realm) {

        realm.beginWrite()
        let feedConversation = vc.prepareConversation(for: feed, in: realm)
        let _ = try? realm.commitWrite()

        vc.conversation = feedConversation
        vc.conversationFeed = ConversationFeed.discoveredFeedType(feed)

        vc.afterDeletedFeedAction = { feedID in
            SafeDispatch.async { [weak self] in
                if let strongSelf = self {
                    var deletedFeed: DiscoveredFeed?
                    for feed in strongSelf.feeds {
                        if feed.id == feedID {
                            deletedFeed = feed
                            break
                        }
                    }

                    if let deletedFeed = deletedFeed, let index = strongSelf.feeds.index(of: deletedFeed) {
                        strongSelf.feeds.remove(at: index)

                        let indexPath = IndexPath(row: index, section: Section.feed.rawValue)
                        strongSelf.feedsTableView.deleteRows(at: [indexPath], with: .none)

                        return
                    }
                }

                // 若不能单项删除，给点时间给服务器，防止请求回来的 feeds 包含被删除的
                _ = delay(1) {
                    self?.updateFeeds()
                }

                println("afterDeletedFeedAction")
            }
        }

        vc.conversationDirtyAction = { [weak self] groupID in

            groupWithGroupID(groupID: groupID, failureHandler: nil, completion: { [weak self] groupInfo in

                if let feedInfo = groupInfo["topic"] as? JSONDictionary {

                    guard let strongSelf = self, let feed = DiscoveredFeed.fromFeedInfo(feedInfo, groupInfo: groupInfo) else {
                        return
                    }

                    if let index = strongSelf.feeds.index(of: feed) {
                        if strongSelf.feeds[index].messagesCount != feed.messagesCount {
                            strongSelf.feeds[index].messagesCount = feed.messagesCount

                            let indexPath = IndexPath(row: index, section: Section.feed.rawValue)
                            let wayToUpdate: UITableView.WayToUpdate = .reloadIndexPaths([indexPath])
                            SafeDispatch.async {
                                wayToUpdate.performWithTableView(strongSelf.feedsTableView)
                            }
                        }
                    }
                }
            })

            println("conversationDirtyAction")
        }

        vc.syncPlayFeedAudioAction = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.feedAudioPlaybackTimer = Timer.scheduledTimer(timeInterval: 0.02, target: strongSelf, selector: #selector(FeedsViewController.updateOnlineAudioPlaybackProgress(_:)), userInfo: nil, repeats: true)
        }
    }
}

// MARK: - UISearchBarDelegate

extension FeedsViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {

        performSegue(withIdentifier: "showSearchFeeds", sender: nil)

        return false
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension FeedsViewController: UITableViewDataSource, UITableViewDelegate {

    fileprivate enum Section: Int {
        case skillUsers
        case uploadingFeed
        case feed
        case loadMore
        case filter
    }

    func numberOfSections(in tableView: UITableView) -> Int {

        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            return 0
        }

        switch section {
        case .skillUsers:
            return (skill == nil) ? 0 : 1
        case .filter:
            return (skill == nil) ? 0 : 1
        case .uploadingFeed:
            return uploadingFeeds.count
        case .feed:
            return feeds.count
        case .loadMore:
            return feeds.isEmpty ? 0 : 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            fatalError("Invalide section!")
        }

        func cellForFeed(_ feed: DiscoveredFeed) -> UITableViewCell {

            switch feed.kind {

            case .Text:
                let cell: FeedBasicCell = tableView.dequeueReusableCell()
                return cell

            case .URL:
                let cell: FeedURLCell = tableView.dequeueReusableCell()
                return cell

            case .Image:
                if feed.imageAttachmentsCount == 1 {
                    let cell: FeedBiggerImageCell = tableView.dequeueReusableCell()
                    return cell

                } else if feed.imageAttachmentsCount <= FeedsViewController.feedNormalImagesCountThreshold {
                    let cell: FeedNormalImagesCell = tableView.dequeueReusableCell()
                    return cell

                } else {
                    let cell: FeedAnyImagesCell = tableView.dequeueReusableCell()
                    return cell
                }

            case .GithubRepo:
                let cell: FeedGithubRepoCell = tableView.dequeueReusableCell()
                return cell

            case .DribbbleShot:
                let cell: FeedDribbbleShotCell = tableView.dequeueReusableCell()
                return cell

            case .Audio:
                let cell: FeedVoiceCell = tableView.dequeueReusableCell()
                return cell

            case .Location:
                let cell: FeedLocationCell = tableView.dequeueReusableCell()
                return cell

            default:
                let cell: FeedBasicCell = tableView.dequeueReusableCell()
                return cell
            }
        }

        switch section {

        case .skillUsers:

            let cell: FeedSkillUsersCell = tableView.dequeueReusableCell()

            cell.configureWithFeeds(feeds)

            return cell

        case .filter:

            let cell: FeedFilterCell = tableView.dequeueReusableCell()

            cell.currentOption = filterOption

            cell.chooseOptionAction = { [weak self] option in
                self?.feeds = []
                self?.feedsTableView.reloadData()

                self?.filterOption = option
            }

            return cell

        case .uploadingFeed:

            let feed = uploadingFeeds[indexPath.row]
            let cell = cellForFeed(feed)

            configureFeedCell(cell, with: feed, in: tableView)

            if let cell = cell as? FeedBasicCell {

                cell.retryUploadingFeedAction = { [weak self] cell in

                    self?.newFeedViewController?.post(again: true)

                    if let indexPath = self?.feedsTableView.indexPath(for: cell) {
                        self?.uploadingFeeds[indexPath.row].uploadingErrorMessage = nil
                        cell.hasUploadingErrorMessage = false
                    }
                }

                cell.deleteUploadingFeedAction = { [weak self] cell in

                    if let indexPath = self?.feedsTableView.indexPath(for: cell) {
                        self?.uploadingFeeds.remove(at: indexPath.row)
                        self?.feedsTableView.deleteRows(at: [indexPath], with: .automatic)

                        self?.newFeedViewController = nil
                    }
                }
            }

            return cell

        case .feed:

            let feed = feeds[indexPath.row]
            let cell = cellForFeed(feed)

            configureFeedCell(cell, with: feed, in: tableView)

            return cell

        case .loadMore:

            let cell: LoadMoreTableViewCell = tableView.dequeueReusableCell()
            return cell
        }
    }

    private func configureFeedCell(_ cell: UITableViewCell, with feed: DiscoveredFeed, in tableView: UITableView) {

        guard let cell = cell as? FeedBasicCell else {
            return
        }

        cell.needShowDistance = needShowDistance

        cell.tapAvatarAction = { [weak self] cell in
            if let indexPath = tableView.indexPath(for: cell) { // 不直接捕捉 indexPath
                println("tapAvatarAction indexPath: \((indexPath as NSIndexPath).section), \((indexPath as NSIndexPath).row)")
                self?.performSegue(withIdentifier: "showProfile", sender: indexPath)
            }
        }

        cell.tapSkillAction = { [weak self] cell in
            if let indexPath = tableView.indexPath(for: cell) { // 不直接捕捉 indexPath
                self?.performSegue(withIdentifier: "showFeedsWithSkill", sender: indexPath)
            }
        }

        // simulate select effects when tap on messageTextView or cell.mediaCollectionView's space part
        // 不能直接捕捉 indexPath，不然新插入后，之前捕捉的 indexPath 不能代表 cell 的新位置，模拟点击会错位到其它 cell
        cell.touchesBeganAction = { [weak self] cell in
            guard let indexPath = tableView.indexPath(for: cell) else {
                return
            }
            _ = self?.tableView(tableView, willSelectRowAt: indexPath)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        cell.touchesEndedAction = { [weak self] cell in
            guard let indexPath = tableView.indexPath(for: cell) else {
                return
            }
            _ = delay(0.03) { [weak self] in
                self?.tableView(tableView, didSelectRowAt: indexPath)
            }
        }
        cell.touchesCancelledAction = { cell in
            guard let indexPath = tableView.indexPath(for: cell) else {
                return
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }

        let layout = FeedsViewController.layoutPool.feedCellLayoutOfFeed(feed)

        switch feed.kind {

        case .Text:

            cell.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

        case .URL:

            guard let cell = cell as? FeedURLCell else {
                break
            }

            cell.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

            cell.tapURLInfoAction = { [weak self] URL in
                println("tapURLInfoAction URL: \(URL)")
                self?.yep_openURL(URL)
            }

        case .Image:

            let tapImagesAction: FeedTapImagesAction = { [weak self] transitionViews, attachments, image, index in

                self?.previewReferences = transitionViews

                let previewAttachmentPhotos = attachments.map({ PreviewAttachmentPhoto(attachment: $0) })
                previewAttachmentPhotos[index].image = image

                self?.previewAttachmentPhotos = previewAttachmentPhotos

                let photos: [Photo] = previewAttachmentPhotos.map({ $0 })
                let initialPhoto = photos[index]

                let photosViewController = PhotosViewController(photos: photos, initialPhoto: initialPhoto, delegate: self)
                self?.present(photosViewController, animated: true, completion: nil)
            }

            if feed.imageAttachmentsCount == 1 {
                guard let cell = cell as? FeedBiggerImageCell else {
                    break
                }

                cell.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

                cell.tapImagesAction = tapImagesAction

            } else if feed.imageAttachmentsCount <= FeedsViewController.feedNormalImagesCountThreshold {

                guard let cell = cell as? FeedNormalImagesCell else {
                    break
                }

                cell.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

                cell.tapImagesAction = tapImagesAction

            } else {
                guard let cell = cell as? FeedAnyImagesCell else {
                    break
                }

                cell.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

                cell.tapImagesAction = tapImagesAction
            }

        case .GithubRepo:

            guard let cell = cell as? FeedGithubRepoCell else {
                break
            }

            cell.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

            cell.tapGithubRepoLinkAction = { [weak self] URL in
                self?.yep_openURL(URL)
            }

        case .DribbbleShot:

            guard let cell = cell as? FeedDribbbleShotCell else {
                break
            }

            cell.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

            cell.tapDribbbleShotLinkAction = { [weak self] URL in
                self?.yep_openURL(URL)
            }

            cell.tapDribbbleShotMediaAction = { [weak self] transitionReference, image, imageURL, linkURL in

                guard image != nil else {
                    return
                }

                self?.previewReferences = [transitionReference].map({ Optional($0) })

                let previewDribbblePhoto = PreviewDribbblePhoto(imageURL: imageURL)
                previewDribbblePhoto.image = image

                let previewDribbblePhotos = [previewDribbblePhoto]
                self?.previewDribbblePhotos = previewDribbblePhotos

                let photos: [Photo] = previewDribbblePhotos.map({ $0 })
                let initialPhoto = photos[0]

                let photosViewController = PhotosViewController(photos: photos, initialPhoto: initialPhoto, delegate: self)
                self?.present(photosViewController, animated: true, completion: nil)
            }

        case .Audio:

            guard let cell = cell as? FeedVoiceCell else {
                break
            }

            cell.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

            cell.playOrPauseAudioAction = { [weak self] cell in

                guard let realm = try? Realm(), let feedAudio = FeedAudio.feedAudioWithFeedID(feed.id, inRealm: realm) else {
                    return
                }

                let play: () -> Void = { [weak self] in

                    if let strongSelf = self {

                        let audioPlayedDuration = strongSelf.audioPlayedDurationOfFeedAudio(feedAudio)
                        YepAudioService.sharedManager.playOnlineAudioWithFeedAudio(feedAudio, beginFromTime: audioPlayedDuration, delegate: strongSelf, success: {
                            println("playOnlineAudioWithFeedAudio success!")

                            strongSelf.feedAudioPlaybackTimer?.invalidate()

                            let playbackTimer = Timer.scheduledTimer(timeInterval: 0.02, target: strongSelf, selector: #selector(FeedsViewController.updateOnlineAudioPlaybackProgress(_:)), userInfo: nil, repeats: true)
                            YepAudioService.sharedManager.playbackTimer = playbackTimer

                            cell.audioPlaying = true
                        })
                    }
                }

                if let strongSelf = self {

                    // 如果在播放，就暂停
                    if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio, let onlineAudioPlayer = YepAudioService.sharedManager.onlineAudioPlayer, onlineAudioPlayer.yep_playing {

                        onlineAudioPlayer.pause()

                        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
                            playbackTimer.invalidate()
                        }

                        let feedID = playingFeedAudio.feedID
                        for index in 0..<strongSelf.feeds.count {
                            let feed = strongSelf.feeds[index]
                            if feed.id == feedID {

                                let indexPath = IndexPath(row: index, section: Section.feed.rawValue)

                                if let cell = strongSelf.feedsTableView.cellForRow(at: indexPath) as? FeedVoiceCell {
                                    cell.audioPlaying = false
                                }

                                break
                            }
                        }

                        if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio, playingFeedAudio.feedID == feed.id {
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

            cell.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

            cell.tapLocationAction = { locationName, locationCoordinate in

                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                mapItem.name = locationName

                mapItem.openInMaps(launchOptions: nil)
            }

        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            return
        }

        switch section {

        case .loadMore:

            guard let cell = cell as? LoadMoreTableViewCell else {
                break
            }

            guard canLoadMore else {
                cell.isLoading = false
                break
            }

            println("load more feeds")

            if !cell.isLoading {
                cell.isLoading = true
            }

            updateFeeds(mode: .loadMore, finish: {
                _ = delay(0.5) { [weak cell] in
                    cell?.isLoading = false
                }
            })

        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            return 0
        }

        switch section {

        case .skillUsers:
            return 70

        case .filter:
            return 60

        case .uploadingFeed:
            let feed = uploadingFeeds[indexPath.row]
            return FeedsViewController.layoutPool.heightOfFeed(feed)

        case .feed:
            let feed = feeds[indexPath.row]
            return FeedsViewController.layoutPool.heightOfFeed(feed)

        case .loadMore:
            return 60
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            return
        }

        switch section {

        case .skillUsers:
            performSegue(withIdentifier: "showSkillHome", sender: nil)

        case .filter:
            break

        case .uploadingFeed:
            break

        case .feed:
            performSegue(withIdentifier: "showConversation", sender: indexPath)

        case .loadMore:
            break
        }
    }

    // Report

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            return false
        }

        switch section {

        case .skillUsers:
            return false

        case .filter:
            return false

        case .uploadingFeed:
            return false

        case .feed:
            let feed = feeds[indexPath.item]

            if feed.skill != nil {
                return true

            } else {
                if feed.creator.id == YepUserDefaults.userID.value {
                    return false
                } else {
                    return true
                }
            }

        case .loadMore:
            return false
        }
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            return nil
        }

        if case .feed = section {

            let reportAction = UITableViewRowAction(style: .default, title: NSLocalizedString("Report", comment: "")) { [weak self] action, indexPath in

                if let feed = self?.feeds[indexPath.row] {
                    self?.report(.feed(feedID: feed.id))
                }

                tableView.setEditing(false, animated: true)
            }

            let feed = feeds[indexPath.row]

            let recommendTitle: String
            if feed.recommended {
                recommendTitle = String.trans_titleCancelRecommended
            } else {
                recommendTitle = NSLocalizedString("Recommend", comment: "")
            }

            let recommendAction = UITableViewRowAction(style: .normal, title: recommendTitle) { [weak self] action, indexPath in

                if feed.recommended {
                    cancelRecommendedFeedWithFeedID(feed.id, failureHandler: { [weak self] reason, errorMessage in

                        let message = errorMessage ?? String.trans_promptCancelRecommendedFeedFailed
                        YepAlert.alertSorry(message: message, inViewController: self)
                        
                    }, completion: { [weak self] in
                        self?.feeds[indexPath.row].recommended = false
                    })

                } else {
                    recommendFeedWithFeedID(feed.id, failureHandler: { [weak self] reason, errorMessage in

                        let message = errorMessage ?? NSLocalizedString("Recommend feed failed!", comment: "")
                        YepAlert.alertSorry(message: message, inViewController: self)

                    }, completion: { [weak self] in
                        self?.feeds[indexPath.row].recommended = true
                    })
                }

                tableView.setEditing(false, animated: true)
            }

            if (YepUserDefaults.admin.value == true) && (feed.skill != nil) {
                if feed.creator.id == YepUserDefaults.userID.value {
                    return [recommendAction]
                } else {
                    return [reportAction, recommendAction]
                }

            } else {
                if feed.creator.id == YepUserDefaults.userID.value {
                    return []
                } else {
                    return [reportAction]
                }
            }
        }

        return nil
    }

    // MARK: Copy Message

    @objc fileprivate func didRecieveMenuWillHideNotification(_ notification: Notification) {

        selectedIndexPathForMenu = nil
    }

    @objc fileprivate func didRecieveMenuWillShowNotification(_ notification: Notification) {

        guard let menu = notification.object as? UIMenuController, let selectedIndexPathForMenu = selectedIndexPathForMenu, let cell = feedsTableView.cellForRow(at: selectedIndexPathForMenu) as? FeedBasicCell else {
            return
        }

        let bubbleFrame = cell.convert(cell.messageTextView.frame, to: view)

        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIMenuControllerWillShowMenu, object: nil)

        menu.setTargetRect(bubbleFrame, in: view)
        menu.setMenuVisible(true, animated: true)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedsViewController.didRecieveMenuWillShowNotification(_:)), name: Notification.Name.UIMenuControllerWillShowMenu, object: nil)

        feedsTableView.deselectRow(at: selectedIndexPathForMenu, animated: true)
    }

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {

        defer {
            selectedIndexPathForMenu = indexPath
        }

        guard let _ = tableView.cellForRow(at: indexPath) as? FeedBasicCell else {
            return false
        }

        return true
    }

    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {

        if action == #selector(NSObject.copy) {
            return true
        }

        return false
    }

    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {

        guard let cell = tableView.cellForRow(at: indexPath) as? FeedBasicCell else {
            return
        }

        if action == #selector(NSObject.copy) {
            UIPasteboard.general.string = cell.messageTextView.text
        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        pullToRefreshView.scrollViewDidScroll(scrollView)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        pullToRefreshView.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {

        pullToRefreshView.scrollViewDidEndScrollingAnimation(scrollView)
    }
}

// MARK: PullToRefreshViewDelegate

extension FeedsViewController: PullToRefreshViewDelegate {

    func pulllToRefreshViewDidRefresh(_ pulllToRefreshView: PullToRefreshView) {

        activityIndicator.alpha = 0

        let finish: () -> Void = { [weak self] in
            _ = delay(0.3) { // 人为延迟，增加等待感
                pulllToRefreshView.endRefreshingAndDoFurtherAction() {}

                self?.activityIndicator.alpha = 1

                if let strongSelf = self {
                    //println("strongSelf.feedsTableView.contentOffset.y: \(strongSelf.feedsTableView.contentOffset.y)")
                    strongSelf.feedsTableView.contentOffset.y += strongSelf.searchBar.frame.height
                    //println("strongSelf.feedsTableView.contentOffset.y: \(strongSelf.feedsTableView.contentOffset.y)")
                }
            }
        }

        pullToRefreshView.refreshTimeoutAction = finish

        updateFeeds(finish: finish)
    }
}

// MARK: Audio Finish Playing

extension FeedsViewController {

    fileprivate func feedAudioDidFinishPlaying() {

        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
            playbackTimer.invalidate()
        }

        if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio {
            setAudioPlayedDuration(0, ofFeedAudio: playingFeedAudio)
            println("setAudioPlayedDuration to 0")
        }

        YepAudioService.sharedManager.resetToDefault()
    }

    @objc fileprivate func feedAudioDidFinishPlaying(_ notification: Notification) {
        feedAudioDidFinishPlaying()
    }
}

// MARK: AVAudioPlayerDelegate

extension FeedsViewController: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {

        println("audioPlayerDidFinishPlaying \(flag)")

        feedAudioDidFinishPlaying()
    }
}

// MARK: - UIViewControllerPreviewingDelegate

extension FeedsViewController: UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let indexPath = feedsTableView.indexPathForRow(at: location), let cell = feedsTableView.cellForRow(at: indexPath) else {
            return nil
        }

        previewingContext.sourceRect = cell.frame

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            return nil
        }

        switch section {

        case .feed:

            guard let
                feed = feeds[safe: indexPath.row],
                let realm = try? Realm() else {
                    return nil
            }

            let vc = UIStoryboard.Scene.conversation

            prepareConversationViewController(vc, withDiscoveredFeed: feed, inRealm: realm)

            recoverOriginalNavigationDelegate()

            vc.isPreviewed = true

            return vc

        default:
            return nil
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        show(viewControllerToCommit, sender: self)
    }
}

// MARK: - PhotosViewControllerDelegate

extension FeedsViewController: PhotosViewControllerDelegate {

    func photosViewController(_ vc: PhotosViewController, referenceForPhoto photo: Photo) -> Reference? {

        println("photosViewController:referenceViewForPhoto:\(photo)")

        if let previewAttachmentPhoto = photo as? PreviewAttachmentPhoto {
            if let index = previewAttachmentPhotos.index(of: previewAttachmentPhoto) {
                return previewReferences?[index]
            }

        } else if let previewDribbblePhoto = photo as? PreviewDribbblePhoto {
            if let index = previewDribbblePhotos.index(of: previewDribbblePhoto) {
                return previewReferences?[index]
            }
        }

        return nil
    }

    func photosViewController(_ vc: PhotosViewController, didNavigateToPhoto photo: Photo, atIndex index: Int) {

        println("photosViewController:didNavigateToPhoto:\(photo):atIndex:\(index)")
    }

    func photosViewControllerWillDismiss(_ vc: PhotosViewController) {

        println("photosViewControllerWillDismiss")
    }

    func photosViewControllerDidDismiss(_ vc: PhotosViewController) {

        println("photosViewControllerDidDismiss")

        previewReferences = nil
        previewAttachmentPhotos = []
        previewDribbblePhotos = []
    }
}


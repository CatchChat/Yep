//
//  SearchFeedsViewController.swift
//  Yep
//
//  Created by NIX on 16/4/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import YepKit
import YepNetworking
import YepPreview
import AVFoundation
import MapKit
import Ruler
import KeypathObserver

private let screenHeight: CGFloat = UIScreen.main.bounds.height

final class SearchFeedsViewController: BaseSearchViewController {

    static let feedNormalImagesCountThreshold: Int = Ruler.UniversalHorizontal(3, 4, 4, 3, 4).value

    var skill: Skill?
    var profileUser: ProfileUser?

    fileprivate lazy var searchFeedsFooterView: SearchFeedsFooterView = {

        let footerView = SearchFeedsFooterView(frame: CGRect(x: 0, y: 0, width: 200, height: screenHeight - 64))

        footerView.tapKeywordAction = { [weak self] keyword in

            self?.searchBar.text = keyword

            self?.isKeywordHot = true
            self?.triggerSearchTaskWithSearchText(keyword)

            self?.searchBar.resignFirstResponder()
        }

        footerView.tapBlankAction = { [weak self] in

            self?.searchBar.resignFirstResponder()
        }

        return footerView
    }()

    var feeds = [DiscoveredFeed]() {
        didSet {

            if feeds.isEmpty {

                if keyword != nil {
                    searchFeedsFooterView.style = .noResults

                } else {
                    if skill != nil || profileUser != nil {
                        searchFeedsFooterView.style = .empty
                    } else {
                        searchFeedsFooterView.style = .keywords
                    }
                }

                feedsTableView.tableFooterView = searchFeedsFooterView

            } else {
                feedsTableView.tableFooterView = UIView()
            }
        }
    }

    let needShowSkill: Bool = false

    fileprivate var selectedIndexPathForMenu: IndexPath?

    @IBOutlet weak var feedsTableView: UITableView!  {
        didSet {
            feedsTableView.backgroundColor = UIColor.white
            feedsTableView.tableFooterView = UIView()
            feedsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            feedsTableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine

            feedsTableView.registerClassOf(SearchedFeedBasicCell)
            feedsTableView.registerClassOf(SearchedFeedNormalImagesCell)
            feedsTableView.registerClassOf(SearchedFeedAnyImagesCell)

            feedsTableView.registerClassOf(SearchedFeedGithubRepoCell)
            feedsTableView.registerClassOf(SearchedFeedDribbbleShotCell)
            feedsTableView.registerClassOf(SearchedFeedVoiceCell)
            feedsTableView.registerClassOf(SearchedFeedLocationCell)
            feedsTableView.registerClassOf(SearchedFeedURLCell)

            feedsTableView.registerNibOf(LoadMoreTableViewCell)

            feedsTableView.keyboardDismissMode = .onDrag
        }
    }

    fileprivate var isKeywordHot: Bool = false

    fileprivate var keyword: String? {
        didSet {
            if keyword == nil {
                clearSearchResults()
            }
            if let keyword = keyword , keyword.isEmpty {
                clearSearchResults()
            }
        }
    }
    fileprivate var searchTask: CancelableTask?

    fileprivate func triggerSearchTaskWithSearchText(_ searchText: String) {

        println("try search feeds with keyword: \(searchText)")

        cancel(searchTask)

        if searchText.isEmpty {
            self.keyword = nil
            return
        }

        searchTask = delay(YepConfig.Search.delayInterval) { [weak self] in
            if let footer = self?.feedsTableView.tableFooterView as? SearchFeedsFooterView {
                footer.style = .Searching
            }

            self?.updateSearchResultsWithText(searchText)
        }
    }

    fileprivate struct LayoutPool {

        fileprivate var feedCellLayoutHash = [String: SearchedFeedCellLayout]()

        fileprivate mutating func feedCellLayoutOfFeed(_ feed: DiscoveredFeed) -> SearchedFeedCellLayout {
            let key = feed.id

            if let layout = feedCellLayoutHash[key] {
                return layout

            } else {
                let layout = SearchedFeedCellLayout(feed: feed)

                updateFeedCellLayout(layout, forFeed: feed)

                return layout
            }
        }

        fileprivate mutating func updateFeedCellLayout(_ layout: SearchedFeedCellLayout, forFeed feed: DiscoveredFeed) {

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

    // MARK: Audio Play

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

                    let indexPath = NSIndexPath(forRow: index, inSection: Section.Feed.rawValue)

                    if let cell = feedsTableView.cellForRowAtIndexPath(indexPath) as? SearchedFeedVoiceCell {
                        cell.audioPlayedDuration = 0
                    }
                    
                    break
                }
            }
        }
    }

    fileprivate func updateCellOfFeedAudio(_ feedAudio: FeedAudio, withCurrentTime currentTime: TimeInterval) {

        let feedID = feedAudio.feedID

        for index in 0..<feeds.count {
            let feed = feeds[index]
            if feed.id == feedID {

                let indexPath = NSIndexPath(forRow: index, inSection: Section.Feed.rawValue)

                if let cell = feedsTableView.cellForRowAtIndexPath(indexPath) as? SearchedFeedVoiceCell {
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

    fileprivate var previewReferences: [Reference?]?
    fileprivate var previewAttachmentPhotos: [PreviewAttachmentPhoto] = []
    fileprivate var previewDribbblePhotos: [PreviewDribbblePhoto] = []

    // MARK: Life Circle

    deinit {
        NotificationCenter.default.removeObserver(self)
        println("deinit SearchFeeds")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.placeholder = NSLocalizedString("Search Feeds", comment: "")

        if skill != nil {
            searchBar.placeholder = NSLocalizedString("Search feeds in channel", comment: "")
        }

        if profileUser != nil {
            searchBar.placeholder = NSLocalizedString("Search feeds by user", comment: "")
        }

        feeds = []

        searchBarBottomLineView.alpha = 0

        feedsTableView.layoutMargins = UIEdgeInsets.zero
        feedsTableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

        NotificationCenter.default.addObserver(self, selector: #selector(SearchFeedsViewController.didRecieveMenuWillShowNotification(_:)), name: NSNotification.Name.UIMenuControllerWillShowMenu, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(SearchFeedsViewController.didRecieveMenuWillHideNotification(_:)), name: NSNotification.Name.UIMenuControllerWillHideMenu, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(SearchFeedsViewController.feedAudioDidFinishPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }

    // MARK: - Private

    fileprivate var canLoadMore: Bool = false
    fileprivate var currentPageIndex = 1
    fileprivate var isFetchingFeeds = false
    enum SearchFeedsMode {
        case `init`
        case loadMore
    }
    fileprivate func searchFeedsWithKeyword(_ keyword: String, mode: SearchFeedsMode, finish: (() -> Void)? = nil) {

        if isFetchingFeeds {
            finish?()
            return
        }

        isFetchingFeeds = true

        switch mode {
        case .init:
            canLoadMore = true
            currentPageIndex = 1
        case .loadMore:
            currentPageIndex += 1
        }

        let failureHandler: FailureHandler = { reason, errorMessage in

            SafeDispatch.async { [weak self] in

                self?.isFetchingFeeds = false

                finish?()
            }

            defaultFailureHandler(reason: reason, errorMessage: errorMessage)
        }

        let perPage: Int = 30

        feedsWithKeyword(keyword, skillID: skill?.id, userID: profileUser?.userID, pageIndex: currentPageIndex, perPage: perPage, failureHandler: failureHandler) { [weak self] feeds in

            let originalFeedsCount = feeds.count
            let validFeeds = feeds.flatMap({ $0 })

            SafeDispatch.async { [weak self] in

                guard let strongSelf = self else {
                    return
                }

                self?.isFetchingFeeds = false

                finish?()

                let newFeeds = validFeeds
                let oldFeeds = strongSelf.feeds

                self?.canLoadMore = (originalFeedsCount == perPage)

                var wayToUpdate: UITableView.WayToUpdate = .None

                if strongSelf.feeds.isEmpty {
                    wayToUpdate = .ReloadData
                }

                switch mode {

                case .Init:
                    strongSelf.feeds = newFeeds

                    if Set(oldFeeds.map({ $0.id })) == Set(newFeeds.map({ $0.id })) {
                        wayToUpdate = .None

                    } else {
                        wayToUpdate = .ReloadData
                    }

                case .LoadMore:
                    let oldFeedsCount = oldFeeds.count

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
                }

                wayToUpdate.performWithTableView(strongSelf.feedsTableView)
            }
        }
    }

    fileprivate func hideKeyboard() {

        searchBar.resignFirstResponder()
    }

    fileprivate func updateResultsTableView(scrollsToTop: Bool = false) {
        SafeDispatch.async { [weak self] in
            self?.feedsTableView.reloadData()

            if scrollsToTop {
                self?.feedsTableView.yep_scrollsToTop()
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showProfile":
            let vc = segue.destination as! ProfileViewController

            if let indexPath = sender as? IndexPath, let section = Section(rawValue: (indexPath as NSIndexPath).section) {

                switch section {
                case .feed:
                    let discoveredUser = feeds[indexPath.row].creator
                    vc.prepare(with: discoveredUser)
                case .loadMore:
                    break
                }
            }

            prepareOriginalNavigationControllerDelegate()

        case "showConversation":

            let vc = segue.destination as! ConversationViewController

            guard let
                indexPath = sender as? IndexPath,
                let feed = feeds[safe: indexPath.row],
                let realm = try? Realm() else {
                    return
            }

            realm.beginWrite()
            let feedConversation = vc.prepareConversation(for: feed, in: realm)
            let _ = try? realm.commitWrite()

            vc.conversation = feedConversation
            vc.conversationFeed = ConversationFeed.DiscoveredFeedType(feed)

            vc.afterDeletedFeedAction = { feedID in
                SafeDispatch.async { [weak self] in
                    guard let strongSelf = self else { return }

                    var deletedFeed: DiscoveredFeed?
                    for feed in strongSelf.feeds {
                        if feed.id == feedID {
                            deletedFeed = feed
                            break
                        }
                    }

                    if let deletedFeed = deletedFeed, let index = strongSelf.feeds.indexOf(deletedFeed) {
                        strongSelf.feeds.removeAtIndex(index)

                        let indexPath = NSIndexPath(forRow: index, inSection: Section.Feed.rawValue)
                        strongSelf.feedsTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .None)

                        return
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

                        if let index = strongSelf.feeds.indexOf(feed) {
                            if strongSelf.feeds[index].messagesCount != feed.messagesCount {
                                strongSelf.feeds[index].messagesCount = feed.messagesCount

                                let indexPath = NSIndexPath(forRow: index, inSection: Section.Feed.rawValue)
                                let wayToUpdate: UITableView.WayToUpdate = .ReloadIndexPaths([indexPath])
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
                strongSelf.feedAudioPlaybackTimer = Timer.scheduledTimer(timeInterval: 0.02, target: strongSelf, selector: #selector(SearchFeedsViewController.updateOnlineAudioPlaybackProgress(_:)), userInfo: nil, repeats: true)
            }

            prepareOriginalNavigationControllerDelegate()
            
        default:
            break
        }
    }
}

// MARK: - UISearchBarDelegate

extension SearchFeedsViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {

        UIView.animate(withDuration: 0.1, delay: 0.0, options: UIViewAnimationOptions(), animations: { [weak self] _ in
            self?.searchBarBottomLineView.alpha = 1
        }, completion: nil)

        return true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {

        searchBar.text = nil

        if isKeywordHot {
            isKeywordHot = false

            keyword = nil
            feeds = []
            feedsTableView.reloadData()

            searchBar.becomeFirstResponder()

        } else {
            searchBar.resignFirstResponder()

            UIView.animate(withDuration: 0.1, delay: 0.0, options: UIViewAnimationOptions(), animations: { [weak self] _ in
                self?.searchBarBottomLineView.alpha = 0
            }, completion: nil)

            navigationController?.popViewController(animated: true)
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        isKeywordHot = false

        triggerSearchTaskWithSearchText(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        hideKeyboard()
    }

    fileprivate func clearSearchResults() {

        feeds = []

        updateResultsTableView(scrollsToTop: true)
    }

    fileprivate func updateSearchResultsWithText(_ searchText: String) {

        let searchText = searchText.trimming(.whitespace)

        // 不要重复搜索一样的内容
        if let keyword = self.keyword , keyword == searchText {
            return
        }

        self.keyword = searchText

        guard !searchText.isEmpty else {
            return
        }

        searchFeedsWithKeyword(searchText, mode: .init)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension SearchFeedsViewController: UITableViewDataSource, UITableViewDelegate {

    fileprivate enum Section: Int {
        case feed
        case loadMore
    }

    func numberOfSections(in tableView: UITableView) -> Int {

        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            return 0
        }

        switch section {
        case .feed:
            return feeds.count
        case .loadMore:
            return feeds.isEmpty ? 0 : 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            return UITableViewCell()
        }

        func cellForFeed(_ feed: DiscoveredFeed) -> UITableViewCell {

            switch feed.kind {

            case .Text:
                let cell: SearchedFeedBasicCell = tableView.dequeueReusableCell()
                return cell

            case .URL:
                let cell: SearchedFeedURLCell = tableView.dequeueReusableCell()
                return cell

            case .Image:
                if feed.imageAttachmentsCount <= SearchFeedsViewController.feedNormalImagesCountThreshold {
                    let cell: SearchedFeedNormalImagesCell = tableView.dequeueReusableCell()
                    return cell

                } else {
                    let cell: SearchedFeedAnyImagesCell = tableView.dequeueReusableCell()
                    return cell
                }

            case .GithubRepo:
                let cell: SearchedFeedGithubRepoCell = tableView.dequeueReusableCell()
                return cell

            case .DribbbleShot:
                let cell: SearchedFeedDribbbleShotCell = tableView.dequeueReusableCell()
                return cell

            case .Audio:
                let cell: SearchedFeedVoiceCell = tableView.dequeueReusableCell()
                return cell

            case .Location:
                let cell: SearchedFeedLocationCell = tableView.dequeueReusableCell()
                return cell

            default:
                let cell: SearchedFeedBasicCell = tableView.dequeueReusableCell()
                return cell
            }
        }

        switch section {

        case .feed:

            let feed = feeds[indexPath.row]
            return cellForFeed(feed)

        case .loadMore:

            let cell: LoadMoreTableViewCell = tableView.dequeueReusableCell()
            return cell
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            return
        }

        func configureFeedCell(_ cell: UITableViewCell, withFeed feed: DiscoveredFeed) {

            guard let cell = cell as? SearchedFeedBasicCell else {
                return
            }

            cell.tapAvatarAction = { [weak self] cell in
                if let indexPath = tableView.indexPath(for: cell) { // 不直接捕捉 indexPath
                    println("tapAvatarAction indexPath: \((indexPath as NSIndexPath).section), \((indexPath as NSIndexPath).row)")
                    self?.hideKeyboard()
                    self?.performSegue(withIdentifier: "showProfile", sender: indexPath)
                }
            }

            // simulate select effects when tap on messageTextView or cell.mediaCollectionView's space part
            // 不能直接捕捉 indexPath，不然新插入后，之前捕捉的 indexPath 不能代表 cell 的新位置，模拟点击会错位到其它 cell
            cell.touchesBeganAction = { [weak self] cell in
                guard let indexPath = tableView.indexPath(for: cell) else {
                    return
                }
                self?.tableView(tableView, willSelectRowAt: indexPath)
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
            cell.touchesEndedAction = { [weak self] cell in
                guard let indexPath = tableView.indexPath(for: cell) else {
                    return
                }
                delay(0.03) { [weak self] in
                    self?.tableView(tableView, didSelectRowAtIndexPath: indexPath)
                }
            }
            cell.touchesCancelledAction = { cell in
                guard let indexPath = tableView.indexPath(for: cell) else {
                    return
                }
                tableView.deselectRow(at: indexPath, animated: true)
            }

            let layout = SearchFeedsViewController.layoutPool.feedCellLayoutOfFeed(feed)

            switch feed.kind {

            case .Text:

                cell.configureWithFeed(feed, layout: layout, keyword: keyword)

            case .URL:

                guard let cell = cell as? SearchedFeedURLCell else {
                    break
                }

                cell.configureWithFeed(feed, layout: layout, keyword: keyword)

                cell.tapURLInfoAction = { [weak self] URL in
                    println("tapURLInfoAction URL: \(URL)")
                    self?.yep_openURL(URL)
                }

            case .Image:

                let tapImagesAction: FeedTapImagesAction = { [weak self] transitionReferences, attachments, image, index in

                    self?.previewReferences = transitionReferences

                    let previewAttachmentPhotos = attachments.map({ PreviewAttachmentPhoto(attachment: $0) })
                    previewAttachmentPhotos[index].image = image

                    self?.previewAttachmentPhotos = previewAttachmentPhotos

                    let photos: [Photo] = previewAttachmentPhotos.map({ $0 })
                    let initialPhoto = photos[index]

                    let photosViewController = PhotosViewController(photos: photos, initialPhoto: initialPhoto, delegate: self)
                    self?.presentViewController(photosViewController, animated: true, completion: nil)
                }

                if feed.imageAttachmentsCount <= SearchFeedsViewController.feedNormalImagesCountThreshold {

                    guard let cell = cell as? SearchedFeedNormalImagesCell else {
                        break
                    }

                    cell.configureWithFeed(feed, layout: layout, keyword: keyword)

                    cell.tapImagesAction = tapImagesAction

                } else {
                    guard let cell = cell as? SearchedFeedAnyImagesCell else {
                        break
                    }

                    cell.configureWithFeed(feed, layout: layout, keyword: keyword)

                    cell.tapImagesAction = tapImagesAction
                }

            case .GithubRepo:

                guard let cell = cell as? SearchedFeedGithubRepoCell else {
                    break
                }

                cell.configureWithFeed(feed, layout: layout, keyword: keyword)

                cell.tapGithubRepoLinkAction = { [weak self] URL in
                    self?.yep_openURL(URL)
                }

            case .DribbbleShot:

                guard let cell = cell as? SearchedFeedDribbbleShotCell else {
                    break
                }

                cell.configureWithFeed(feed, layout: layout, keyword: keyword)

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

                guard let cell = cell as? SearchedFeedVoiceCell else {
                    break
                }

                cell.configureWithFeed(feed, layout: layout, keyword: keyword)

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

                                let playbackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: strongSelf, selector: #selector(SearchFeedsViewController.updateOnlineAudioPlaybackProgress(_:)), userInfo: nil, repeats: true)
                                YepAudioService.sharedManager.playbackTimer = playbackTimer

                                cell.audioPlaying = true
                            })
                        }
                    }

                    if let strongSelf = self {

                        // 如果在播放，就暂停
                        if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio, let onlineAudioPlayer = YepAudioService.sharedManager.onlineAudioPlayer , onlineAudioPlayer.yep_playing {

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

                            if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio , playingFeedAudio.feedID == feed.id {
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

                guard let cell = cell as? SearchedFeedLocationCell else {
                    break
                }

                cell.configureWithFeed(feed, layout: layout, keyword: keyword)

                cell.tapLocationAction = { locationName, locationCoordinate in

                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                    mapItem.name = locationName

                    mapItem.openInMaps(launchOptions: nil)
                }

            default:
                break
            }
        }

        switch section {

        case .feed:

            let feed = feeds[indexPath.row]
            configureFeedCell(cell, withFeed: feed)

        case .loadMore:

            guard let cell = cell as? LoadMoreTableViewCell else {
                break
            }

            guard canLoadMore else {
                cell.isLoading = false
                break
            }

            println("search more feeds")

            if !cell.isLoading {
                cell.isLoading = true
            }

            if let keyword = self.keyword {
                searchFeedsWithKeyword(keyword, mode: .LoadMore, finish: {
                    delay(0.5) { [weak cell] in
                        cell?.isLoading = false
                    }
                })
            } else {
                cell.isLoading = false
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            return 0
        }

        switch section {

        case .feed:
            let feed = feeds[indexPath.row]
            return SearchFeedsViewController.layoutPool.heightOfFeed(feed)

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

        hideKeyboard()

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            return
        }

        switch section {

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

        case .feed:
            let feed = feeds[indexPath.item]
            if feed.creator.id == YepUserDefaults.userID.value {
                return false
            } else {
                return true
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
                    self?.report(.Feed(feedID: feed.id))
                }

                tableView.setEditing(false, animated: true)
            }

            return [reportAction]
        }

        return nil
    }
    
    // MARK: Copy Message
    
    @objc fileprivate func didRecieveMenuWillHideNotification(_ notification: Notification) {
        
        selectedIndexPathForMenu = nil
    }
    
    @objc fileprivate func didRecieveMenuWillShowNotification(_ notification: Notification) {
        
        guard let menu = notification.object as? UIMenuController, let selectedIndexPathForMenu = selectedIndexPathForMenu, let cell = feedsTableView.cellForRow(at: selectedIndexPathForMenu) as? SearchedFeedBasicCell else {
            return
        }
        
        let bubbleFrame = cell.convert(cell.messageTextView.frame, to: view)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIMenuControllerWillShowMenu, object: nil)
        
        menu.setTargetRect(bubbleFrame, in: view)
        menu.setMenuVisible(true, animated: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SearchFeedsViewController.didRecieveMenuWillShowNotification(_:)), name: NSNotification.Name.UIMenuControllerWillShowMenu, object: nil)
        
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
        
        if action == #selector(NSObject.copy(_:)) {
            return true
        }
        
        return false
    }
    
    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? FeedBasicCell else {
            return
        }
        
        if action == #selector(NSObject.copy(_:)) {
            UIPasteboard.general.string = cell.messageTextView.text
        }
    }
}

// MARK: Audio Finish Playing

extension SearchFeedsViewController {

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

extension SearchFeedsViewController: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {

        println("audioPlayerDidFinishPlaying \(flag)")
        
        feedAudioDidFinishPlaying()
    }
}

// MARK: - PhotosViewControllerDelegate

extension SearchFeedsViewController: PhotosViewControllerDelegate {

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


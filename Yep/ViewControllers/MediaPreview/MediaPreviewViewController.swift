//
//  MediaPreviewViewController.swift
//  Yep
//
//  Created by nixzhu on 15/11/10.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation
import MonkeyKing
import Kingfisher
import Ruler

let mediaPreviewWindow = UIWindow(frame: UIScreen.mainScreen().bounds)

enum PreviewMedia {

    case MessageType(message: Message)
    case AttachmentType(attachment: DiscoveredAttachment)
    case WebImage(imageURL: NSURL, linkURL: NSURL)
}

class MediaPreviewViewController: UIViewController {

    var previewMedias: [PreviewMedia] = []
    var startIndex: Int = 0
    var currentIndex: Int = 0 {
        didSet {
            if let previewMedia = previewMedias[safe: currentIndex] {
                switch previewMedia {
                case .MessageType(let message):
                    guard !message.mediaPlayed else {
                        break
                    }
                    guard let realm = message.realm else {
                        break
                    }
                    let _ = try? realm.write {
                        message.mediaPlayed = true
                    }
                case .AttachmentType:
                    break
                case .WebImage:
                    break
                }
            }
        }
    }

    private struct AttachmentImagePool {
        var imagesDic = [String: UIImage]()

        mutating func addImage(image: UIImage, forKey key: String) {
            guard !key.isEmpty else {
                return
            }

            if imagesDic[key] == nil {
                imagesDic[key] = image
            }
        }

        func imageWithKey(key: String) -> UIImage? {
            return imagesDic[key]
        }
    }
    private var attachmentImagePool = AttachmentImagePool()

    var currentPlayer: AVPlayer?

    @IBOutlet weak var mediasCollectionView: UICollectionView!
    @IBOutlet weak var mediaControlView: MediaControlView!

    lazy var topPreviewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill // 缩放必要
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.clearColor()
        return imageView
    }()
    lazy var bottomPreviewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill // 缩放必要
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.clearColor()
        return imageView
    }()
    var previewImageViewInitalFrame: CGRect?
    var topPreviewImage: UIImage?
    var bottomPreviewImage: UIImage?

    weak var transitionView: UIView?

    var afterDismissAction: (() -> Void)?

    var showFinished = false

    let mediaViewCellID = "MediaViewCell"

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        println("deinit MediaPreview")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mediasCollectionView.backgroundColor = UIColor.clearColor()
        mediasCollectionView.registerNib(UINib(nibName: mediaViewCellID, bundle: nil), forCellWithReuseIdentifier: mediaViewCellID)

        guard let previewImageViewInitalFrame = previewImageViewInitalFrame else {
            return
        }

        topPreviewImageView.frame = previewImageViewInitalFrame
        bottomPreviewImageView.frame = previewImageViewInitalFrame
        view.addSubview(bottomPreviewImageView)
        view.addSubview(topPreviewImageView)

        guard let bottomPreviewImage = bottomPreviewImage else {
            return
        }

        bottomPreviewImageView.image = bottomPreviewImage

        topPreviewImageView.image = topPreviewImage

        let viewWidth = UIScreen.mainScreen().bounds.width
        let viewHeight = UIScreen.mainScreen().bounds.height

        let previewImageWidth = bottomPreviewImage.size.width
        let previewImageHeight = bottomPreviewImage.size.height

        // 利用 image.size 以及 view.frame 来确保 imageView 在缩放时平滑（配合 ScaleAspectFill）
        let previewImageViewWidth = viewWidth
        let previewImageViewHeight = (previewImageHeight / previewImageWidth) * previewImageViewWidth

        view.backgroundColor = UIColor.clearColor()

        mediasCollectionView.alpha = 0
        mediaControlView.alpha = 0

        topPreviewImageView.alpha = 0
        bottomPreviewImageView.alpha = 1

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in

            self?.view.backgroundColor = UIColor.blackColor()

            if let _ = self?.topPreviewImage {
                self?.topPreviewImageView.alpha = 1
                self?.bottomPreviewImageView.alpha = 0
            }

            let frame = CGRect(x: 0, y: (viewHeight - previewImageViewHeight) * 0.5, width: previewImageViewWidth, height: previewImageViewHeight)
            self?.topPreviewImageView.frame = frame
            self?.bottomPreviewImageView.frame = frame

        }, completion: { [weak self] _ in
            self?.mediasCollectionView.alpha = 1

            let fade: (() -> Void)? = { [weak self] in
                self?.topPreviewImageView.alpha = 0
                self?.bottomPreviewImageView.alpha = 0
            }

            UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveLinear, animations: { [weak self] in
                self?.mediaControlView.alpha = 1

            }, completion: { _ in
                Ruler.iPhoneHorizontal(fade, nil, nil).value?()
            })
            
            UIView.animateWithDuration(0.1, delay: 0.1, options: .CurveLinear, animations: {
                Ruler.iPhoneHorizontal(nil, fade, fade).value?()

            }, completion: { [weak self] _ in
                self?.showFinished = true
                println("showFinished")
            })
        })

        let swipeUp = UISwipeGestureRecognizer(target: self, action: "dismiss")
        swipeUp.direction = .Up
        view.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: "dismiss")
        swipeDown.direction = .Down
        view.addGestureRecognizer(swipeDown)

        currentIndex = startIndex

        prepareInAdvance()
    }

    var isFirstLayoutSubviews = true

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isFirstLayoutSubviews {

            let item = startIndex

            let indexPath = NSIndexPath(forItem: item, inSection: 0)
            mediasCollectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: false)

            delay(0.1) { [weak self] in

                guard let cell = self?.mediasCollectionView.cellForItemAtIndexPath(indexPath) as? MediaViewCell else {
                    return
                }

                guard let previewMedia = self?.previewMedias[safe: item] else {
                    return
                }

                self?.prepareForShareWithCell(cell, previewMedia: previewMedia)
            }
        }
        
        isFirstLayoutSubviews = false
    }

    // MARK: Private

    private func prepareInAdvance() {

        for previewMedia in previewMedias {

            if case let .AttachmentType(attachment) = previewMedia {

                ImageCache.sharedInstance.imageOfAttachment(attachment, withMinSideLength: nil, completion: { [weak self] (url, image, _) in
                    if let image = image {
                        self?.attachmentImagePool.addImage(image, forKey: attachment.URLString)
                    }
                })
            }
        }
    }

    // MARK: Actions

    func dismiss() {

        guard showFinished else {
            return
        }

        currentPlayer?.removeObserver(self, forKeyPath: "status")
        currentPlayer?.pause()

        let finishDismissAction: () -> Void = { [weak self] in

            mediaPreviewWindow.windowLevel = UIWindowLevelNormal

            self?.afterDismissAction?()

            delay(0.05) {
                mediaPreviewWindow.rootViewController = nil
            }
        }

        if case .MessageType = previewMedias[0] {

            guard currentIndex == startIndex else {

                transitionView?.alpha = 1

                UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                    self?.view.backgroundColor = UIColor.clearColor()
                    self?.mediaControlView.alpha = 0
                    self?.mediasCollectionView.alpha = 0

                }, completion: { _ in
                    finishDismissAction()
                })

                return
            }
        }

        if let _ = topPreviewImage {
            topPreviewImageView.alpha = 1
            bottomPreviewImageView.alpha = 0

        } else {
            bottomPreviewImageView.alpha = 1
        }

        mediasCollectionView.alpha = 0

        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
            self?.mediaControlView.alpha = 0
        }, completion: nil)


        var frame = self.previewImageViewInitalFrame ?? CGRectZero

        if case .AttachmentType = previewMedias[0] {
            let offsetIndex = currentIndex - startIndex
            if abs(offsetIndex) > 0 {
                let offsetX = CGFloat(offsetIndex) * frame.width + CGFloat(offsetIndex) * 5
                frame.origin.x += offsetX
            }
        }

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in

            self?.view.backgroundColor = UIColor.clearColor()

            if let _ = self?.topPreviewImage {
                self?.topPreviewImageView.alpha = 0
                self?.bottomPreviewImageView.alpha = 1
            }

            self?.topPreviewImageView.frame = frame
            self?.bottomPreviewImageView.frame = frame

        }, completion: { _ in
            finishDismissAction()
        })
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        if let player = object as? AVPlayer {

            let indexPath = NSIndexPath(forItem: currentIndex, inSection: 0)
            guard let cell = mediasCollectionView.cellForItemAtIndexPath(indexPath) as? MediaViewCell else {
                return
            }

            if player == cell.mediaView.videoPlayerLayer.player {

                if keyPath == "status" {
                    switch player.status {

                    case AVPlayerStatus.Failed:
                        println("Failed")

                    case AVPlayerStatus.ReadyToPlay:
                        println("ReadyToPlay")
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.mediaView.videoPlayerLayer.player?.play()

                            cell.mediaView.videoPlayerLayer.hidden = false
                            cell.mediaView.scrollView.hidden = true
                        }

                    case AVPlayerStatus.Unknown:
                        println("Unknown")
                    }
                }
            }
        }
    }

    func playerItemDidReachEnd(notification: NSNotification) {
        mediaControlView.playState = .Pause
        
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seekToTime(kCMTimeZero)
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension MediaPreviewViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return previewMedias.count
    }

    private func configureCell(cell: MediaViewCell, withPreviewMedia previewMedia: PreviewMedia) {

        cell.activityIndicator.startAnimating()

        switch previewMedia {

        case .MessageType(let message):

            switch message.mediaType {

            case MessageMediaType.Image.rawValue:

                mediaControlView.type = .Image

                cell.mediaView.scrollView.hidden = false
                cell.mediaView.videoPlayerLayer.hidden = true

                if
                    let imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localAttachmentName),
                    let image = UIImage(contentsOfFile: imageFileURL.path!) {
                        cell.mediaView.image = image
                }

                cell.activityIndicator.stopAnimating()

            case MessageMediaType.Video.rawValue:

                mediaControlView.type = .Video
                mediaControlView.playState = .Playing

                if
                    let imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localThumbnailName),
                    let image = UIImage(contentsOfFile: imageFileURL.path!) {
                        cell.mediaView.image = image
                }

                cell.activityIndicator.stopAnimating()

            default:
                cell.activityIndicator.stopAnimating()
            }

        case .AttachmentType(let attachment):

            mediaControlView.type = .Image

            if let image = attachmentImagePool.imageWithKey(attachment.URLString) {
                cell.mediaView.image = image

                cell.activityIndicator.stopAnimating()

            } else {
                ImageCache.sharedInstance.imageOfAttachment(attachment, withMinSideLength: nil, completion: { [weak self] (url, image, _) in
                    guard url.absoluteString == attachment.URLString else {
                        return
                    }

                    cell.mediaView.image = image

                    cell.activityIndicator.stopAnimating()

                    if let image = image {
                        self?.attachmentImagePool.addImage(image, forKey: attachment.URLString)
                    }
                })
            }

        case .WebImage(let imageURL, _):

            mediaControlView.type = .Image

            let imageView = UIImageView()

            imageView.kf_setImageWithURL(imageURL, placeholderImage: nil, optionsInfo: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in

                dispatch_async(dispatch_get_main_queue()) {
                    cell.mediaView.image = image

                    cell.activityIndicator.stopAnimating()
                }
            })
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(mediaViewCellID, forIndexPath: indexPath) as! MediaViewCell
        return cell
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        if let cell = cell as? MediaViewCell {
            let previewMedia = previewMedias[indexPath.item]
            configureCell(cell, withPreviewMedia: previewMedia)

            cell.mediaView.tapToDismissAction = { [weak self] in
                self?.dismiss()
            }
        }
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        return UIScreen.mainScreen().bounds.size
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        //return UIEdgeInsetsZero
    }


    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {

        let newCurrentIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)

        if newCurrentIndex != currentIndex {

            currentPlayer?.removeObserver(self, forKeyPath: "status")
            currentPlayer?.pause()
            currentPlayer = nil

            let indexPath = NSIndexPath(forItem: newCurrentIndex, inSection: 0)

            guard let cell = mediasCollectionView.cellForItemAtIndexPath(indexPath) as? MediaViewCell else {
                return
            }

            let previewMedia = previewMedias[newCurrentIndex]

            prepareForShareWithCell(cell, previewMedia: previewMedia)

            currentIndex = newCurrentIndex

            println("scroll to new media")

            transitionView?.alpha = (currentIndex == startIndex) ? 0 : 1

            if case .AttachmentType = previewMedias[0] {

                guard let image = cell.mediaView.image else {
                    return
                }

                bottomPreviewImageView.image = image

                let viewWidth = UIScreen.mainScreen().bounds.width
                let viewHeight = UIScreen.mainScreen().bounds.height

                let previewImageWidth = image.size.width
                let previewImageHeight = image.size.height

                let previewImageViewWidth = viewWidth
                let previewImageViewHeight = (previewImageHeight / previewImageWidth) * previewImageViewWidth

                let frame = CGRect(x: 0, y: (viewHeight - previewImageViewHeight) * 0.5, width: previewImageViewWidth, height: previewImageViewHeight)

                bottomPreviewImageView.frame = frame
            }
        }
    }

    private func prepareForShareWithCell(cell: MediaViewCell, previewMedia: PreviewMedia) {

        switch previewMedia {

        case .MessageType(let message):

            switch message.mediaType {

            case MessageMediaType.Image.rawValue:

                mediaControlView.type = .Image

                if let
                    imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localAttachmentName),
                    image = UIImage(contentsOfFile: imageFileURL.path!) {

                        mediaControlView.shareAction = { [weak self] in

                            let info = MonkeyKing.Info(
                                title: nil,
                                description: nil,
                                thumbnail: nil,
                                media: .Image(image)
                            )

                            let sessionMessage = MonkeyKing.Message.WeChat(.Session(info: info))

                            let weChatSessionActivity = WeChatActivity(
                                type: .Session,
                                message: sessionMessage,
                                finish: { success in
                                    println("share Image to WeChat Session success: \(success)")
                                }
                            )

                            let timelineMessage = MonkeyKing.Message.WeChat(.Timeline(info: info))

                            let weChatTimelineActivity = WeChatActivity(
                                type: .Timeline,
                                message: timelineMessage,
                                finish: { success in
                                    println("share Image to WeChat Timeline success: \(success)")
                                }
                            )

                            let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])

                            self?.presentViewController(activityViewController, animated: true, completion: nil)
                        }
                }

            case MessageMediaType.Video.rawValue:

                mediaControlView.type = .Video
                mediaControlView.playState = .Playing

                if let
                    imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localThumbnailName),
                    image = UIImage(contentsOfFile: imageFileURL.path!) {
                        cell.mediaView.image = image
                }

                if let videoFileURL = NSFileManager.yepMessageVideoURLWithName(message.localAttachmentName) {
                    let asset = AVURLAsset(URL: videoFileURL, options: [:])
                    let playerItem = AVPlayerItem(asset: asset)

                    playerItem.seekToTime(kCMTimeZero)
                    let player = AVPlayer(playerItem: playerItem)

                    mediaControlView.timeLabel.text = ""

                    player.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(0.1, Int32(NSEC_PER_SEC)), queue: nil, usingBlock: { [weak self] time in

                        guard let currentItem = player.currentItem else {
                            return
                        }

                        if currentItem.status == .ReadyToPlay {
                            let durationSeconds = CMTimeGetSeconds(currentItem.duration)
                            let currentSeconds = CMTimeGetSeconds(time)
                            let coundDownTime = Double(Int((durationSeconds - currentSeconds) * 10)) / 10
                            self?.mediaControlView.timeLabel.text = "\(coundDownTime)"
                        }
                    })

                    NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidReachEnd:", name: AVPlayerItemDidPlayToEndTimeNotification, object: player.currentItem)

                    mediaControlView.playAction = { mediaControlView in
                        player.play()

                        mediaControlView.playState = .Playing
                    }

                    mediaControlView.pauseAction = { mediaControlView in
                        player.pause()

                        mediaControlView.playState = .Pause
                    }

                    cell.mediaView.videoPlayerLayer.player = player

                    cell.mediaView.videoPlayerLayer.player?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)

                    currentPlayer = player

                    mediaControlView.shareAction = { [weak self] in
                        let activityViewController = UIActivityViewController(activityItems: [videoFileURL], applicationActivities: nil)

                        self?.presentViewController(activityViewController, animated: true, completion: { () -> Void in
                        })
                    }
                }

            default:
                break
            }

        case .AttachmentType:

            guard let image = cell.mediaView.image else {
                return
            }

            mediaControlView.type = .Image

            mediaControlView.shareAction = { [weak self] in

                let info = MonkeyKing.Info(
                    title: nil,
                    description: nil,
                    thumbnail: nil,
                    media: .Image(image)
                )

                let sessionMessage = MonkeyKing.Message.WeChat(.Session(info: info))

                let weChatSessionActivity = WeChatActivity(
                    type: .Session,
                    message: sessionMessage,
                    finish: { success in
                        println("share Image to WeChat Session success: \(success)")
                    }
                )
                
                let timelineMessage = MonkeyKing.Message.WeChat(.Timeline(info: info))
                
                let weChatTimelineActivity = WeChatActivity(
                    type: .Timeline,
                    message: timelineMessage,
                    finish: { success in
                        println("share Image to WeChat Timeline success: \(success)")
                    }
                )
                
                let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])
                
                self?.presentViewController(activityViewController, animated: true, completion: nil)
            }

        case .WebImage(_, let linkURL):

            mediaControlView.shareAction = { [weak self] in

                let info = MonkeyKing.Info(
                    title: nil,
                    description: nil,
                    thumbnail: nil,
                    media: .URL(linkURL)
                )

                let sessionMessage = MonkeyKing.Message.WeChat(.Session(info: info))

                let weChatSessionActivity = WeChatActivity(
                    type: .Session,
                    message: sessionMessage,
                    finish: { success in
                        println("share WebImage URL to WeChat Session success: \(success)")
                    }
                )

                let timelineMessage = MonkeyKing.Message.WeChat(.Timeline(info: info))

                let weChatTimelineActivity = WeChatActivity(
                    type: .Timeline,
                    message: timelineMessage,
                    finish: { success in
                        println("share WebImage URL to WeChat Timeline success: \(success)")
                    }
                )

                let activityViewController = UIActivityViewController(activityItems: [linkURL], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])

                self?.presentViewController(activityViewController, animated: true, completion: nil)
            }
        }
    }
}


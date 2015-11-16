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

let mediaPreviewWindow = UIWindow(frame: UIScreen.mainScreen().bounds)

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
                }
            }
        }
    }

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

    var afterDismissAction: (() -> Void)?

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

            UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in

                self?.mediaControlView.alpha = 1

            }, completion: nil)

            self?.topPreviewImageView.alpha = 0
            self?.bottomPreviewImageView.alpha = 0
        })

        let tap = UITapGestureRecognizer(target: self, action: "dismiss")
        view.addGestureRecognizer(tap)

        let swipeUp = UISwipeGestureRecognizer(target: self, action: "dismiss")
        swipeUp.direction = .Up
        view.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: "dismiss")
        swipeDown.direction = .Down
        view.addGestureRecognizer(swipeDown)

        currentIndex = startIndex
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

    // MARK: Actions

    func dismiss() {

        currentPlayer?.removeObserver(self, forKeyPath: "status")
        currentPlayer?.pause()

        let finishDismissAction: () -> Void = { [weak self] in

            mediaPreviewWindow.windowLevel = UIWindowLevelNormal

            self?.afterDismissAction?()

            //delay(0.01) {
                mediaPreviewWindow.rootViewController = nil
            //}
        }

//        guard currentIndex == startIndex else {
//
//            UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
//                self?.view.backgroundColor = UIColor.clearColor()
//                self?.mediaControlView.alpha = 0
//                self?.mediasCollectionView.alpha = 0
//
//            }, completion: { _ in
//                finishDismissAction()
//            })
//
//            return
//        }

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

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in

            self?.view.backgroundColor = UIColor.clearColor()

            if let _ = self?.topPreviewImage {
                self?.topPreviewImageView.alpha = 0
                self?.bottomPreviewImageView.alpha = 1
            }

            let frame = self?.previewImageViewInitalFrame ?? CGRectZero
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

            case MessageMediaType.Video.rawValue:

                mediaControlView.type = .Video
                mediaControlView.playState = .Playing

                if
                    let imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localThumbnailName),
                    let image = UIImage(contentsOfFile: imageFileURL.path!) {
                        cell.mediaView.image = image
                }

            default:
                break
            }

        case .AttachmentType(let attachment):

            mediaControlView.type = .Image

            ImageCache.sharedInstance.imageOfAttachment(attachment, withSize: nil, completion: { (url, image) in
                guard url.absoluteString == attachment.URLString else {
                    return
                }
                cell.mediaView.image = image
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
        }
    }
}


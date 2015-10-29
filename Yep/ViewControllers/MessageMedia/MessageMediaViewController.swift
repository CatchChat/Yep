//
//  MessageMediaViewController.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation
import MonkeyKing
import Kingfisher

enum PreviewMedia {

    case MessageType(message: Message)
    case AttachmentType(imageURL: NSURL)
}

class MessageMediaViewController: UIViewController {

    var previewMedias: [PreviewMedia] = []
    var startIndex: Int = 0
    var currentIndex: Int = 0

    var currentPlayer: AVPlayer?

    let mediaViewCellID = "MediaViewCell"

    @IBOutlet weak var mediasCollectionView: UICollectionView!

    @IBOutlet weak var mediaControlView: MediaControlView!

    var hideStatusBar = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Preview", comment: "")

        automaticallyAdjustsScrollViewInsets = false

        mediasCollectionView.registerNib(UINib(nibName: mediaViewCellID, bundle: nil), forCellWithReuseIdentifier: mediaViewCellID)

        mediasCollectionView.backgroundColor = UIColor.clearColor()

        mediaControlView.hidden = true


        currentIndex = startIndex
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: false)

        tabBarController?.tabBar.hidden = true
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        delay(0.01) {
            self.hideStatusBar = true
        }

        mediaControlView.alpha = 0
        mediaControlView.hidden = false

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.mediaControlView.alpha = 1
        }, completion: { _ in })
    }

    var isFirstLayoutSubviews = true

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isFirstLayoutSubviews {
            let startIndexPath = NSIndexPath(forItem: startIndex, inSection: 0)
            mediasCollectionView.scrollToItemAtIndexPath(startIndexPath, atScrollPosition: .CenteredHorizontally, animated: false)

            guard let cell = mediasCollectionView.cellForItemAtIndexPath(startIndexPath) as? MediaViewCell else {
                return
            }

            let previewMedia = previewMedias[startIndex]

            prepareForShareWithCell(cell, previewMedia: previewMedia)
        }

        isFirstLayoutSubviews = false
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        //mediaView.videoPlayerLayer.player?.pause()
    }

    // MARK: Actions

    func dismiss() {

//        switch previewMedia {
//        case .MessageType(let message):
//            if message.mediaType == MessageMediaType.Video.rawValue {
//                mediaView.videoPlayerLayer.player?.removeObserver(self, forKeyPath: "status")
//            }
//        default:
//            break
//        }

        navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func swipeUp(sender: UISwipeGestureRecognizer) {
        dismiss()
    }

    @IBAction func swipeDown(sender: UISwipeGestureRecognizer) {
        dismiss()
    }

    @IBAction func tap(sender: UITapGestureRecognizer) {
        dismiss()
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

    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Fade
    }

    override func prefersStatusBarHidden() -> Bool {
        return hideStatusBar
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate 

extension MessageMediaViewController: UICollectionViewDataSource, UICollectionViewDelegate {

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

                cell.mediaView.scrollView.hidden = true
                cell.mediaView.videoPlayerLayer.hidden = false

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

        case .AttachmentType(let imageURL):

            mediaControlView.type = .Image

            cell.mediaView.helperImageView.kf_setImageWithURL(imageURL, placeholderImage: nil, optionsInfo: nil, completionHandler: { (image, error, cacheType, imageURL) in

                guard let image = image else {
                    return
                }

                cell.mediaView.image = image
            })
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(mediaViewCellID, forIndexPath: indexPath) as! MediaViewCell

//        if let pinchGestureRecognizer = cell.mediaView.scrollView.pinchGestureRecognizer {
//            collectionView.addGestureRecognizer(pinchGestureRecognizer)
//        }
//        let panGestureRecognizer = cell.mediaView.scrollView.panGestureRecognizer
//        collectionView.addGestureRecognizer(panGestureRecognizer)

        return cell
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        if let cell = cell as? MediaViewCell {
            let previewMedia = previewMedias[indexPath.item]
            configureCell(cell, withPreviewMedia: previewMedia)
        }
    }


//    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
//        if let cell = cell as? MediaViewCell {
//            if let pinchGestureRecognizer = cell.mediaView.scrollView.pinchGestureRecognizer {
//                collectionView.removeGestureRecognizer(pinchGestureRecognizer)
//            }
//            let panGestureRecognizer = cell.mediaView.scrollView.panGestureRecognizer
//            collectionView.removeGestureRecognizer(panGestureRecognizer)
//        }
//    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        return UIScreen.mainScreen().bounds.size
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    //func scrollViewDidScroll(scrollView: UIScrollView) {

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

                if
                    let imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localAttachmentName),
                    let image = UIImage(contentsOfFile: imageFileURL.path!) {

                        mediaControlView.shareAction = {

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

                            self.presentViewController(activityViewController, animated: true, completion: nil)
                        }
                }

            case MessageMediaType.Video.rawValue:

                mediaControlView.type = .Video
                mediaControlView.playState = .Playing

                if
                    let imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localThumbnailName),
                    let image = UIImage(contentsOfFile: imageFileURL.path!) {
                        cell.mediaView.image = image
                }

                if
                    let videoFileURL = NSFileManager.yepMessageVideoURLWithName(message.localAttachmentName) {
                        let asset = AVURLAsset(URL: videoFileURL, options: [:])
                        let playerItem = AVPlayerItem(asset: asset)

                        //let x = NSFileManager.defaultManager().fileExistsAtPath(videoFileURL.path!)

                        playerItem.seekToTime(kCMTimeZero)
                        //mediaView.videoPlayerLayer.player.replaceCurrentItemWithPlayerItem(playerItem)
                        let player = AVPlayer(playerItem: playerItem)

                        mediaControlView.timeLabel.text = ""

                        player.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(0.1, Int32(NSEC_PER_SEC)), queue: nil, usingBlock: { time in

                            guard let currentItem = player.currentItem else {
                                return
                            }

                            if currentItem.status == .ReadyToPlay {
                                let durationSeconds = CMTimeGetSeconds(currentItem.duration)
                                let currentSeconds = CMTimeGetSeconds(time)
                                let coundDownTime = Double(Int((durationSeconds - currentSeconds) * 10)) / 10
                                self.mediaControlView.timeLabel.text = "\(coundDownTime)"
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

                        //mediaView.videoPlayerLayer.player.play()
                        //mediaView.imageView.removeFromSuperview()

                        mediaControlView.shareAction = {
                            let activityViewController = UIActivityViewController(activityItems: [videoFileURL], applicationActivities: nil)

                            self.presentViewController(activityViewController, animated: true, completion: { () -> Void in
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


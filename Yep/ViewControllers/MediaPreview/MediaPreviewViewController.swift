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
    var currentIndex: Int = 0

    var currentPlayer: AVPlayer?

    @IBOutlet weak var mediasCollectionView: UICollectionView!
    @IBOutlet weak var mediaControlView: MediaControlView!

    lazy var previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    var previewImageViewInitalFrame: CGRect?
    var previewImage: UIImage?

    var afterDismissAction: (() -> Void)?

    let mediaViewCellID = "MediaViewCell"

    deinit {
        println("deinit MediaPreview")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mediasCollectionView.registerNib(UINib(nibName: mediaViewCellID, bundle: nil), forCellWithReuseIdentifier: mediaViewCellID)

        guard let previewImageViewInitalFrame = previewImageViewInitalFrame else {
            return
        }

        previewImageView.frame = previewImageViewInitalFrame
        view.addSubview(previewImageView)

        guard let previewImage = previewImage else {
            return
        }

        previewImageView.image = previewImage

        let viewWidth = UIScreen.mainScreen().bounds.width
        let viewHeight = UIScreen.mainScreen().bounds.height

        let previewImageWidth = previewImage.size.width
        let previewImageHeight = previewImage.size.height

        let previewImageViewWidth = viewWidth
        let previewImageViewHeight = (previewImageHeight / previewImageWidth) * previewImageViewWidth
//        let previewImageViewWidth: CGFloat
//        let previewImageViewHeight: CGFloat
//
//        if previewImageWidth > previewImageHeight {
//            previewImageViewWidth = viewWidth
//            previewImageViewHeight = (previewImageHeight / previewImageWidth) * previewImageViewWidth
//
//        } else {
//            // TODO: size
//            previewImageViewWidth = viewWidth
//            previewImageViewHeight = (previewImageHeight / previewImageWidth) * previewImageViewWidth
//        }

        //let finalWidth = UIScreen.mainScreen().bounds.width
        //let finalHeight = UIScreen.mainScreen().bounds.height

        view.backgroundColor = UIColor.clearColor()

        mediasCollectionView.alpha = 0
        mediaControlView.alpha = 0

        UIView.animateWithDuration(1.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in

            self?.view.backgroundColor = UIColor.blackColor()

            self?.previewImageView.frame = CGRect(x: 0, y: (viewHeight - previewImageViewHeight) * 0.5, width: previewImageViewWidth, height: previewImageViewHeight)

        }, completion: { [weak self] _ in
            self?.mediasCollectionView.alpha = 1

            UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in

                self?.mediaControlView.alpha = 1

            }, completion: nil)

            self?.previewImageView.alpha = 0
        })

        let tap = UITapGestureRecognizer(target: self, action: "dismiss")
        view.addGestureRecognizer(tap)

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

        previewImageView.alpha = 1

        mediasCollectionView.alpha = 0

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
            self?.mediaControlView.alpha = 0
        }, completion: nil)

        UIView.animateWithDuration(1.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in

            self?.view.backgroundColor = UIColor.clearColor()

            self?.previewImageView.frame = self?.previewImageViewInitalFrame ?? CGRectZero

        }, completion: { [weak self] _ in
            mediaPreviewWindow.windowLevel = UIWindowLevelNormal

            self?.afterDismissAction?()

            delay(0.2) {
                mediaPreviewWindow.rootViewController = nil
            }
        })
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


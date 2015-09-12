//
//  MessageMediaViewController.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation

class MessageMediaViewController: UIViewController {

    var message: Message?

    @IBOutlet weak var mediaView: MediaView!

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
        

        if let message = message {

            switch message.mediaType {

            case MessageMediaType.Image.rawValue:

                mediaControlView.type = .Image

                if
                    let imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localAttachmentName),
                    let image = UIImage(contentsOfFile: imageFileURL.path!) {
                        mediaView.image = image

                        mediaControlView.shareAction = {

                            MonkeyKing.registerAccount(.WeChat(appID: YepConfig.ChinaSocialNetwork.WeChat.appID))
                            
                            let info = MonkeyKing.Message.WeChatSubtype.Info(
                                title: nil,
                                description: nil,
                                thumbnail: nil,
                                media: .Image(image)
                            )

                            let sessionMessage = MonkeyKing.Message.WeChat(.Session(info))

                            let weChatSessionActivity = WeChatActivity(
                                type: .Session,
                                canPerform: sessionMessage.canBeDelivered,
                                perform: {
                                    MonkeyKing.shareMessage(sessionMessage) { success in
                                        println("share Image to WeChat Session success: \(success)")
                                    }
                                }
                            )

                            let timelineMessage = MonkeyKing.Message.WeChat(.Timeline(info))

                            let weChatTimelineActivity = WeChatActivity(
                                type: .Timeline,
                                canPerform: timelineMessage.canBeDelivered,
                                perform: {
                                    MonkeyKing.shareMessage(timelineMessage) { success in
                                        println("share Image to WeChat Timeline success: \(success)")
                                    }
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
                        mediaView.image = image
                }

                if
                    let videoFileURL = NSFileManager.yepMessageVideoURLWithName(message.localAttachmentName),
                    let asset = AVURLAsset(URL: videoFileURL, options: [:]),
                    let playerItem = AVPlayerItem(asset: asset) {

                        let x = NSFileManager.defaultManager().fileExistsAtPath(videoFileURL.path!)

                        playerItem.seekToTime(kCMTimeZero)
                        //mediaView.videoPlayerLayer.player.replaceCurrentItemWithPlayerItem(playerItem)
                        let player = AVPlayer(playerItem: playerItem)

                        mediaControlView.timeLabel.text = ""

                        player.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(0.1, Int32(NSEC_PER_SEC)), queue: nil, usingBlock: { time in

                            if player.currentItem.status == .ReadyToPlay {
                                let durationSeconds = CMTimeGetSeconds(player.currentItem.duration)
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

                        mediaView.videoPlayerLayer.player = player

                        mediaView.videoPlayerLayer.player.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(0), context: nil)

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
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        delay(0.01) {
            self.hideStatusBar = true
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        mediaView.videoPlayerLayer.player.pause()
    }

    // MARK: Actions

    func dismiss() {
        if let message = message {
            if message.mediaType == MessageMediaType.Video.rawValue {
                mediaView.videoPlayerLayer.player.removeObserver(self, forKeyPath: "status")
            }
        }

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

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if let player = object as? AVPlayer {

            if player == mediaView.videoPlayerLayer.player {

                if keyPath == "status" {
                    switch player.status {

                    case AVPlayerStatus.Failed:
                        println("Failed")

                    case AVPlayerStatus.ReadyToPlay:
                        println("ReadyToPlay")
                        dispatch_async(dispatch_get_main_queue()) {
                            self.mediaView.videoPlayerLayer.player.play()
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

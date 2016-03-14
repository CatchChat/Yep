//
//  MediaPreviewView.swift
//  Yep
//
//  Created by NIX on 15/6/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation

class MediaPreviewView: UIView {

    weak var parentViewController: UIViewController?

    var initialframe: CGRect = CGRectZero

    var message: Message? {
        didSet {
            if let message = message {

                switch message.mediaType {

                case MessageMediaType.Image.rawValue:

                    mediaControlView.type = .Image

                    if
                        let imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localAttachmentName),
                        let image = UIImage(contentsOfFile: imageFileURL.path!) {

                            mediaView.scrollView.hidden = false
                            mediaView.image = image
                            mediaView.coverImage = image

                            mediaControlView.shareAction = {
                                if let vc = self.parentViewController {

                                    UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                                        self.alpha = 0.0
                                    }, completion: { finished in
                                    })

                                    let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                                    
                                    activityViewController.completionWithItemsHandler = { (_, _, _, _) in
                                        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                                            self.alpha = 1.0
                                        }, completion: { finished in
                                        })
                                    }

                                    vc.presentViewController(activityViewController, animated: true, completion: nil)
                                }
                            }
                    }

                case MessageMediaType.Video.rawValue:

                    mediaControlView.type = .Video
                    mediaControlView.playState = .Playing

                    if
                        let videoFileURL = NSFileManager.yepMessageVideoURLWithName(message.localAttachmentName) {
                            let playerItem = AVPlayerItem(asset: AVURLAsset(URL: videoFileURL, options: [:]))

                            //let x = NSFileManager.defaultManager().fileExistsAtPath(videoFileURL.path!)

                            playerItem.seekToTime(kCMTimeZero)

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

                            mediaView.videoPlayerLayer.player = player

                            mediaView.videoPlayerLayer.player?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)

                            mediaView.videoPlayerLayer.addObserver(self, forKeyPath: "readyForDisplay", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)

                            //mediaView.videoPlayerLayer.player.play()
                            mediaView.scrollView.hidden = true

                            if
                                let imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localThumbnailName),
                                let image = UIImage(contentsOfFile: imageFileURL.path!) {
                                    mediaView.coverImage = image
                            }
                            
                            mediaControlView.shareAction = {
                                if let vc = self.parentViewController {

                                    UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                                        self.alpha = 0.0
                                    }, completion: { finished in
                                    })

                                    let activityViewController = UIActivityViewController(activityItems: [videoFileURL], applicationActivities: nil)

                                    activityViewController.completionWithItemsHandler = { (_, _, _, _) in
                                        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                                            self.alpha = 1.0
                                        }, completion: { finished in
                                        })
                                    }

                                    vc.presentViewController(activityViewController, animated: true, completion: nil)
                                }
                            }
                    }
                    
                default:
                    break
                }
            }
        }
    }

    lazy var mediaView: MediaView = {
        let view = MediaView()
        return view
        }()

    lazy var mediaControlView: MediaControlView = {
        let view = MediaControlView()
        return view
        }()


    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.blackColor()
        
        clipsToBounds = true

        makeUI()

        addHideGesture()
    }

    func makeUI() {
        addSubview(mediaView)
        addSubview(mediaControlView)

        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaControlView.translatesAutoresizingMaskIntoConstraints = false

        let viewsDictionary = [
            "mediaView": mediaView,
            "mediaControlView": mediaControlView,
        ]

        let mediaViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[mediaView]|", options: [], metrics: nil, views: viewsDictionary)

        let mediaViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[mediaView]|", options: [], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(mediaViewConstraintsV)
        NSLayoutConstraint.activateConstraints(mediaViewConstraintsH)


        let mediaControlViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[mediaControlView]|", options: [], metrics: nil, views: viewsDictionary)

        let mediaControlViewConstraintHeight = NSLayoutConstraint(item: mediaControlView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 50)

        let mediaControlViewConstraintBottom = NSLayoutConstraint(item: mediaControlView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activateConstraints(mediaControlViewConstraintsH)
        NSLayoutConstraint.activateConstraints([mediaControlViewConstraintHeight, mediaControlViewConstraintBottom])
    }

    func addHideGesture() {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: "hide")
        swipeUp.direction = .Up

        let swipeDown = UISwipeGestureRecognizer(target: self, action: "hide")
        swipeDown.direction = .Down

        addGestureRecognizer(swipeUp)
        addGestureRecognizer(swipeDown)
    }

    func hide() {
        if let message = message {
            if message.mediaType == MessageMediaType.Video.rawValue {
                mediaView.videoPlayerLayer.player?.pause()
                mediaView.videoPlayerLayer.player?.removeObserver(self, forKeyPath: "status")
            }
        }

        UIView.animateWithDuration(0.05, delay: 0.0, options: .CurveLinear, animations: { _ in
            self.mediaView.coverImageView.alpha = 1
            self.mediaControlView.alpha = 0

        }, completion: { finished in

            UIView.animateWithDuration(0.10, delay: 0.0, options: .CurveEaseOut, animations: { _ in
                self.frame = self.initialframe
                self.layoutIfNeeded()

            }, completion: { finished in
                self.removeFromSuperview()
            })
        })
    }

    func showMediaOfMessage(message: Message, inView view: UIView?, withInitialFrame initialframe: CGRect, fromViewController viewController: UIViewController) {
        if let parentView = view {

            parentView.addSubview(self)

            backgroundColor = UIColor.blackColor()

            parentViewController = viewController

            self.message = message


            self.initialframe = initialframe

            mediaControlView.alpha = 0

            frame = initialframe
            layoutIfNeeded()

            UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseOut, animations: { _ in
                self.frame = parentView.bounds
                self.layoutIfNeeded()

            }, completion: { finished in
                if message.mediaType != MessageMediaType.Video.rawValue {
                    self.mediaView.coverImage = nil
                }

                UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveLinear, animations: { _ in
                    self.mediaControlView.alpha = 1
                }, completion: { finished in
                })
            })
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        struct VideoPrepareState {
            static var readyToPlay = false
            static var readyForDisplay = false

            static var isReady: Bool {
                return readyToPlay && readyForDisplay
            }
        }

        if let player = object as? AVPlayer {

            if player == mediaView.videoPlayerLayer.player {

                if keyPath == "status" {
                    switch player.status {

                    case AVPlayerStatus.Failed:
                        println("Failed")

                    case AVPlayerStatus.ReadyToPlay:
                        println("ReadyToPlay")

                        VideoPrepareState.readyToPlay = true

                        delay(0.3) {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.mediaView.videoPlayerLayer.player?.play()
                            }
                        }

                    case AVPlayerStatus.Unknown:
                        println("Unknown")
                    }
                }
            }
        }

        if let videoPlayerLayer = object as? AVPlayerLayer {
            if keyPath == "readyForDisplay" {
                if videoPlayerLayer.readyForDisplay {
                    VideoPrepareState.readyForDisplay = true
                }
            }
        }

        if VideoPrepareState.isReady {
            self.mediaView.coverImage = nil
        }
    }

    func playerItemDidReachEnd(notification: NSNotification) {
        mediaControlView.playState = .Pause

        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seekToTime(kCMTimeZero)
        }
    }
}

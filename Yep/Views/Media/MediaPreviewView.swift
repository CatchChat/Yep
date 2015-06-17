//
//  MediaPreviewView.swift
//
//
//  Created by NIX on 15/6/15.
//
//

import UIKit
import AVFoundation

class MediaPreviewView: UIView {

    weak var parentViewController: UIViewController?

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
                        let videoFileURL = NSFileManager.yepMessageVideoURLWithName(message.localAttachmentName),
                        let asset = AVURLAsset(URL: videoFileURL, options: [:]),
                        let playerItem = AVPlayerItem(asset: asset) {

                            let x = NSFileManager.defaultManager().fileExistsAtPath(videoFileURL.path!)

                            playerItem.seekToTime(kCMTimeZero)

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

        clipsToBounds = true

        makeUI()

        addHideGesture()
    }

    func makeUI() {
        addSubview(mediaView)
        addSubview(mediaControlView)

        mediaView.setTranslatesAutoresizingMaskIntoConstraints(false)
        mediaControlView.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "mediaView": mediaView,
            "mediaControlView": mediaControlView,
        ]

        let mediaViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[mediaView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let mediaViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[mediaView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(mediaViewConstraintsV)
        NSLayoutConstraint.activateConstraints(mediaViewConstraintsH)


        let mediaControlViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[mediaControlView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

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
                mediaView.videoPlayerLayer.player.pause()
                mediaView.videoPlayerLayer.player.removeObserver(self, forKeyPath: "status")
            }
        }

        removeFromSuperview()
    }

    func showMediaOfMessage(message: Message, inView view: UIView?, withInitialFrame initialframe: CGRect, fromViewController viewController: UIViewController) {
        if let parentView = view {

            parentView.addSubview(self)

            backgroundColor = UIColor.blackColor()

            parentViewController = viewController

            self.message = message

//            frame = initialframe
//
//            UIView.animateWithDuration(2.5, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
//                self.frame = parentView.bounds
//            }, completion: { finished in
//            })

//            frame = parentView.bounds
//
//            center = CGPoint(x: CGRectGetMidX(initialframe), y: CGRectGetMidY(initialframe))
//            
//            let scale = initialframe.width / parentView.bounds.width
////            transform = CGAffineTransformScale(scale, scale)
//            transform = CGAffineTransformScale(transform, scale, scale)


            frame = initialframe

            layoutIfNeeded()

            UIView.animateWithDuration(5.5, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                self.frame = parentView.bounds
                self.layoutIfNeeded()

            }, completion: { finished in
                self.mediaView.coverImage = nil
            })
        }
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
}

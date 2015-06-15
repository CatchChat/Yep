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

    var message: Message? {
        didSet {
            if let message = message {

                switch message.mediaType {

                case MessageMediaType.Image.rawValue:

                    mediaControlView.type = .Image

                    if
                        let imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localAttachmentName),
                        let image = UIImage(contentsOfFile: imageFileURL.path!) {
                            mediaView.image = image

                            mediaControlView.shareAction = {
                                let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)

                                //self.presentViewController(activityViewController, animated: true, completion: { () -> Void in
                                //})
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
                            mediaView.imageView.removeFromSuperview()
                            
                            
                            mediaControlView.shareAction = {
                                let activityViewController = UIActivityViewController(activityItems: [videoFileURL], applicationActivities: nil)
                                
                                //self.presentViewController(activityViewController, animated: true, completion: { () -> Void in
                                //})
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

        makeUI()
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


    func showMessage(message: Message, inView view: UIView?) {
        if let superView = view {

            superView.addSubview(self)

            frame = superView.bounds

            backgroundColor = UIColor.redColor()


            self.message = message
        }
    }
}

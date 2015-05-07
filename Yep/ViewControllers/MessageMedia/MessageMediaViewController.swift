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

    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let message = message {

            switch message.mediaType {

            case MessageMediaType.Image.rawValue:

                mediaControlView.type = .Image

                if
                    let imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localAttachmentName),
                    let image = UIImage(contentsOfFile: imageFileURL.path!) {
                        mediaView.imageView.image = image
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
                        mediaView.videoPlayerLayer.player = AVPlayer(playerItem: playerItem)

                        mediaView.videoPlayerLayer.player.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(0), context: nil)

                        //mediaView.videoPlayerLayer.player.play()
                        mediaView.imageView.removeFromSuperview()
                }

            default:
                break
            }
        }
    }

    @IBAction func swipeDown(sender: UISwipeGestureRecognizer) {

        if let message = message {
            if message.mediaType == MessageMediaType.Video.rawValue {
                mediaView.videoPlayerLayer.player.removeObserver(self, forKeyPath: "status")
            }
        }

        dismissViewControllerAnimated(true, completion: nil)
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
}

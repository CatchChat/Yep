//
//  MediaPreviewViewController.swift
//  Yep
//
//  Created by nixzhu on 15/11/10.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation
import YepKit
import MonkeyKing
import Kingfisher
import Ruler

let mediaPreviewWindow = UIWindow(frame: UIScreen.main.bounds)

enum PreviewMedia {

    case messageType(message: Message)
    case attachmentType(attachment: DiscoveredAttachment)
    case webImage(imageURL: URL, linkURL: URL)
}

final class MediaPreviewViewController: UIViewController {

    var previewMedias: [PreviewMedia] = []
    var startIndex: Int = 0
    var currentIndex: Int = 0 {
        didSet {
            if let previewMedia = previewMedias[safe: currentIndex] {
                switch previewMedia {
                case .messageType(let message):
                    guard !message.mediaPlayed else {
                        break
                    }
                    guard let realm = message.realm else {
                        break
                    }
                    let _ = try? realm.write {
                        message.mediaPlayed = true
                    }
                case .attachmentType:
                    break
                case .webImage:
                    break
                }
            }
        }
    }

    fileprivate struct AttachmentImagePool {
        var imagesDic = [String: UIImage]()

        mutating func addImage(_ image: UIImage, forKey key: String) {
            guard !key.isEmpty else {
                return
            }

            if imagesDic[key] == nil {
                imagesDic[key] = image
            }
        }

        func imageWithKey(_ key: String) -> UIImage? {
            return imagesDic[key]
        }
    }
    fileprivate var attachmentImagePool = AttachmentImagePool()

    var currentPlayer: AVPlayer?

    @IBOutlet weak var mediasCollectionView: UICollectionView!
    @IBOutlet weak var mediaControlView: MediaControlView!

    lazy var topPreviewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill // 缩放必要
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.clear
        return imageView
    }()
    lazy var bottomPreviewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill // 缩放必要
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.clear
        return imageView
    }()
    var previewImageViewInitalFrame: CGRect?
    var topPreviewImage: UIImage?
    var bottomPreviewImage: UIImage?

    weak var transitionView: UIView?

    var afterDismissAction: (() -> Void)?

    var showFinished = false

    deinit {
        NotificationCenter.default.removeObserver(self)
        println("deinit MediaPreview")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mediasCollectionView.backgroundColor = UIColor.clear

        mediasCollectionView.registerNibOf(MediaViewCell.self)

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

        let viewWidth = UIScreen.main.bounds.width
        let viewHeight = UIScreen.main.bounds.height

        let previewImageWidth = bottomPreviewImage.size.width
        let previewImageHeight = bottomPreviewImage.size.height

        // 利用 image.size 以及 view.frame 来确保 imageView 在缩放时平滑（配合 ScaleAspectFill）
        let previewImageViewWidth = viewWidth
        let previewImageViewHeight = (previewImageHeight / previewImageWidth) * previewImageViewWidth

        view.backgroundColor = UIColor.clear

        mediasCollectionView.alpha = 0
        mediaControlView.alpha = 0

        topPreviewImageView.alpha = 0
        bottomPreviewImageView.alpha = 1

        UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions(), animations: { [weak self] in

            self?.view.backgroundColor = UIColor.black

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

            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: { [weak self] in
                self?.mediaControlView.alpha = 1

            }, completion: { _ in
                Ruler.iPhoneHorizontal(fade, nil, nil).value?()
            })
            
            UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveLinear, animations: {
                Ruler.iPhoneHorizontal(nil, fade, fade).value?()

            }, completion: { [weak self] _ in
                self?.showFinished = true
                println("showFinished")
            })
        })

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(MediaPreviewViewController.tryDismiss))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(MediaPreviewViewController.tryDismiss))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)

        currentIndex = startIndex

        prepareInAdvance()
    }

    var isFirstLayoutSubviews = true

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isFirstLayoutSubviews {

            let item = startIndex

            let indexPath = IndexPath(item: item, section: 0)
            mediasCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)

            _ = delay(0.1) { [weak self] in

                guard let cell = self?.mediasCollectionView.cellForItem(at: indexPath) as? MediaViewCell else {
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

    fileprivate func prepareInAdvance() {

        for previewMedia in previewMedias {

            if case let .attachmentType(attachment) = previewMedia {

                ImageCache.sharedInstance.imageOfAttachment(attachment, withMinSideLength: nil, completion: { [weak self] (url, image, _) in
                    if let image = image {
                        self?.attachmentImagePool.addImage(image, forKey: attachment.URLString)
                    }
                })
            }
        }
    }

    // MARK: Actions

    func tryDismiss() {

        guard showFinished else {
            return
        }

        currentPlayer?.removeObserver(self, forKeyPath: "status")
        currentPlayer?.pause()

        let finishDismissAction: () -> Void = { [weak self] in

            mediaPreviewWindow.windowLevel = UIWindowLevelNormal

            self?.afterDismissAction?()

            _ = delay(0.05) {
                mediaPreviewWindow.rootViewController = nil
            }
        }

        if case .messageType = previewMedias[0] {

            guard currentIndex == startIndex else {

                transitionView?.alpha = 1

                UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions(), animations: { [weak self] in
                    self?.view.backgroundColor = UIColor.clear
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

        UIView.animate(withDuration: 0.1, delay: 0.0, options: UIViewAnimationOptions(), animations: { [weak self] in
            self?.mediaControlView.alpha = 0
        }, completion: nil)


        var frame = self.previewImageViewInitalFrame ?? CGRect.zero

        if case .attachmentType = previewMedias[0] {
            let offsetIndex = currentIndex - startIndex
            if abs(offsetIndex) > 0 {
                let offsetX = CGFloat(offsetIndex) * frame.width + CGFloat(offsetIndex) * 5
                frame.origin.x += offsetX
            }
        }

        UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions(), animations: { [weak self] in

            self?.view.backgroundColor = UIColor.clear

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

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        if let player = object as? AVPlayer {

            let indexPath = IndexPath(item: currentIndex, section: 0)
            guard let cell = mediasCollectionView.cellForItem(at: indexPath) as? MediaViewCell else {
                return
            }

            if player == cell.mediaView.videoPlayerLayer.player {

                if keyPath == "status" {
                    switch player.status {

                    case AVPlayerStatus.failed:
                        println("Failed")

                    case AVPlayerStatus.readyToPlay:
                        println("ReadyToPlay")
                        SafeDispatch.async {
                            cell.mediaView.videoPlayerLayer.player?.play()

                            cell.mediaView.videoPlayerLayer.isHidden = false
                            cell.mediaView.scrollView.isHidden = true
                        }

                    case AVPlayerStatus.unknown:
                        println("Unknown")
                    }
                }
            }
        }
    }

    func playerItemDidReachEnd(_ notification: Notification) {
        mediaControlView.playState = .pause
        
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: kCMTimeZero)
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension MediaPreviewViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return previewMedias.count
    }

    fileprivate func configureCell(_ cell: MediaViewCell, withPreviewMedia previewMedia: PreviewMedia) {

        cell.activityIndicator.startAnimating()

        switch previewMedia {

        case .messageType(let message):

            switch message.mediaType {

            case MessageMediaType.image.rawValue:

                mediaControlView.type = .image

                cell.mediaView.scrollView.isHidden = false
                cell.mediaView.videoPlayerLayer.isHidden = true

                if
                    let imageFileURL = message.imageFileURL,
                    let image = UIImage(contentsOfFile: imageFileURL.path) {
                        cell.mediaView.image = image
                }

                cell.activityIndicator.stopAnimating()

            case MessageMediaType.video.rawValue:

                mediaControlView.type = .video
                mediaControlView.playState = .playing

                if
                    let imageFileURL = message.videoThumbnailFileURL,
                    let image = UIImage(contentsOfFile: imageFileURL.path) {
                        cell.mediaView.image = image
                }

                cell.activityIndicator.stopAnimating()

            default:
                cell.activityIndicator.stopAnimating()
            }

        case .attachmentType(let attachment):

            mediaControlView.type = .image

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

        case .webImage(let imageURL, _):

            mediaControlView.type = .image

            let imageView = UIImageView()

            imageView.kf.setImage(with: imageURL, placeholder: nil, options: nil) { (image, error, cacheType, imageURL) in

                SafeDispatch.async {
                    cell.mediaView.image = image

                    cell.activityIndicator.stopAnimating()
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell: MediaViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        if let cell = cell as? MediaViewCell {
            let previewMedia = previewMedias[(indexPath as NSIndexPath).item]
            configureCell(cell, withPreviewMedia: previewMedia)

            cell.mediaView.tapToDismissAction = { [weak self] in
                self?.tryDismiss()
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: IndexPath!) -> CGSize {
        return UIScreen.main.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        //return UIEdgeInsetsZero
    }


    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        let newCurrentIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)

        if newCurrentIndex != currentIndex {

            currentPlayer?.removeObserver(self, forKeyPath: "status")
            currentPlayer?.pause()
            currentPlayer = nil

            let indexPath = IndexPath(item: newCurrentIndex, section: 0)

            guard let cell = mediasCollectionView.cellForItem(at: indexPath) as? MediaViewCell else {
                return
            }

            let previewMedia = previewMedias[newCurrentIndex]

            prepareForShareWithCell(cell, previewMedia: previewMedia)

            currentIndex = newCurrentIndex

            println("scroll to new media")

            transitionView?.alpha = (currentIndex == startIndex) ? 0 : 1

            if case .attachmentType = previewMedias[0] {

                guard let image = cell.mediaView.image else {
                    return
                }

                bottomPreviewImageView.image = image

                let viewWidth = UIScreen.main.bounds.width
                let viewHeight = UIScreen.main.bounds.height

                let previewImageWidth = image.size.width
                let previewImageHeight = image.size.height

                let previewImageViewWidth = viewWidth
                let previewImageViewHeight = (previewImageHeight / previewImageWidth) * previewImageViewWidth

                let frame = CGRect(x: 0, y: (viewHeight - previewImageViewHeight) * 0.5, width: previewImageViewWidth, height: previewImageViewHeight)

                bottomPreviewImageView.frame = frame
            }
        }
    }

    fileprivate func prepareForShareWithCell(_ cell: MediaViewCell, previewMedia: PreviewMedia) {

        switch previewMedia {

        case .messageType(let message):

            guard let mediaType = MessageMediaType(rawValue: message.mediaType) else {
                break
            }

            switch mediaType {

            case .image:

                mediaControlView.type = .image

                guard let imageFileURL = message.imageFileURL else { break }
                guard let image = UIImage(contentsOfFile: imageFileURL.path) else { break }

                mediaControlView.shareAction = { [weak self] in
                    let info = MonkeyKing.Info(
                        title: nil,
                        description: nil,
                        thumbnail: nil,
                        media: .image(image)
                    )
                    self?.yep_share(info: info, defaultActivityItem: image)
                }

            case .video:

                mediaControlView.type = .video
                mediaControlView.playState = .playing

                if let imageFileURL = message.videoThumbnailFileURL, let image = UIImage(contentsOfFile: imageFileURL.path) {
                        cell.mediaView.image = image
                }

                if let videoFileURL = message.videoFileURL {
                    let asset = AVURLAsset(url: videoFileURL, options: [:])
                    let playerItem = AVPlayerItem(asset: asset)

                    playerItem.seek(to: kCMTimeZero)
                    let player = AVPlayer(playerItem: playerItem)

                    mediaControlView.timeLabel.text = ""

                    player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1, Int32(NSEC_PER_SEC)), queue: nil, using: { [weak self] time in

                        guard let currentItem = player.currentItem else {
                            return
                        }

                        if currentItem.status == .readyToPlay {
                            let durationSeconds = CMTimeGetSeconds(currentItem.duration)
                            let currentSeconds = CMTimeGetSeconds(time)
                            let coundDownTime = Double(Int((durationSeconds - currentSeconds) * 10)) / 10
                            self?.mediaControlView.timeLabel.text = "\(coundDownTime)"
                        }
                    })

                    NotificationCenter.default.addObserver(self, selector: #selector(MediaPreviewViewController.playerItemDidReachEnd(_:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)

                    mediaControlView.playAction = { mediaControlView in
                        player.play()

                        mediaControlView.playState = .playing
                    }

                    mediaControlView.pauseAction = { mediaControlView in
                        player.pause()

                        mediaControlView.playState = .pause
                    }

                    cell.mediaView.videoPlayerLayer.player = player

                    cell.mediaView.videoPlayerLayer.player?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)

                    currentPlayer = player

                    mediaControlView.shareAction = { [weak self] in
                        let activityViewController = UIActivityViewController(activityItems: [videoFileURL], applicationActivities: nil)

                        self?.present(activityViewController, animated: true, completion: nil)
                    }
                }

            default:
                break
            }

        case .attachmentType:

            mediaControlView.type = .image

            mediaControlView.shareAction = { [weak self] in

                guard let image = cell.mediaView.image else {
                    return
                }

                let info = MonkeyKing.Info(
                    title: nil,
                    description: nil,
                    thumbnail: nil,
                    media: .image(image)
                )
                self?.yep_share(info: info, defaultActivityItem: image)
            }

        case .webImage(_, let linkURL):

            mediaControlView.shareAction = { [weak self] in

                let info = MonkeyKing.Info(
                    title: nil,
                    description: nil,
                    thumbnail: nil,
                    media: .url(linkURL)
                )
                self?.yep_share(info: info, defaultActivityItem: linkURL)
            }
        }
    }
}


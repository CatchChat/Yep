//
//  MediaPreviewViewController.swift
//  Yep
//
//  Created by nixzhu on 15/11/10.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

let mediaPreviewWindow = UIWindow(frame: UIScreen.mainScreen().bounds)

class MediaPreviewViewController: UIViewController {

    var previewMedias: [PreviewMedia] = []
    var startIndex: Int = 0
    
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
}


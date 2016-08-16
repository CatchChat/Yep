//
//  QuickPickPhotosCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Photos
import YepKit
import Proposer

final class QuickPickPhotosCell: UITableViewCell {

    @IBOutlet weak var photosCollectionView: UICollectionView!

    var alertCanNotAccessCameraRollAction: (() -> Void)?
    var takePhotoAction: (() -> Void)?
    var pickedPhotosAction: (Set<PHAsset> -> Void)?

    var images: PHFetchResult?
    lazy var imageManager = PHCachingImageManager()
    var imageCacheController: ImageCacheController!

    var pickedImageSet = Set<PHAsset>() {
        didSet {
            pickedPhotosAction?(pickedImageSet)
        }
    }
    var completion: ((images: [UIImage], imageAssetSet: Set<PHAsset>) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .None

        photosCollectionView.backgroundColor = UIColor.clearColor()

        photosCollectionView.registerNibOf(CameraCell)
        photosCollectionView.registerNibOf(PhotoCell)

        photosCollectionView.showsHorizontalScrollIndicator = false

        if let layout = photosCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: 70, height: 70)
            layout.minimumInteritemSpacing = 10
            layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

            photosCollectionView.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        }

        proposeToAccess(.Photos, agreed: {
            SafeDispatch.async { [weak self] in
                if let strongSelf = self {
                    let options = PHFetchOptions()
                    options.sortDescriptors = [
                        NSSortDescriptor(key: "creationDate", ascending: false)
                    ]
                    let images = PHAsset.fetchAssetsWithMediaType(.Image, options: options)
                    strongSelf.images = images
                    strongSelf.imageCacheController = ImageCacheController(imageManager: strongSelf.imageManager, images: images, preheatSize: 1)

                    strongSelf.photosCollectionView.dataSource = self
                    strongSelf.photosCollectionView.delegate = self

                    strongSelf.photosCollectionView.reloadData()

                    PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(strongSelf)
                }
            }

        }, rejected: { [weak self] in
            self?.alertCanNotAccessCameraRollAction?()
        })
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension QuickPickPhotosCell: PHPhotoLibraryChangeObserver {

    func photoLibraryDidChange(changeInstance: PHChange) {

        if let
            _images = images,
            changeDetails = changeInstance.changeDetailsForFetchResult(_images) {

                SafeDispatch.async { [weak self] in
                    self?.images = changeDetails.fetchResultAfterChanges
                    self?.photosCollectionView.reloadData()
                }
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension QuickPickPhotosCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return images?.count ?? 0
        default:
            return 0
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        switch indexPath.section {

        case 0:
            let cell: CameraCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            return cell

        case 1:
            let cell: PhotoCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            return cell

        default:
            return UICollectionViewCell()
        }
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        if let cell = cell as? PhotoCell {
            cell.imageManager = imageManager

            if let imageAsset = images?[indexPath.item] as? PHAsset {
                cell.imageAsset = imageAsset
                cell.photoPickedImageView.hidden = !pickedImageSet.contains(imageAsset)
            }
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        switch indexPath.section {

        case 0:
            takePhotoAction?()

        case 1:
            if let imageAsset = images?[indexPath.item] as? PHAsset {

                if pickedImageSet.contains(imageAsset) {
                    pickedImageSet.remove(imageAsset)

                } else {
                    pickedImageSet.insert(imageAsset)
                }

                let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
                cell.photoPickedImageView.hidden = !pickedImageSet.contains(imageAsset)
            }

        default:
            break
        }
    }
}


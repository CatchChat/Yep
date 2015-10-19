//
//  QuickPickPhotosCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Photos

class QuickPickPhotosCell: UITableViewCell {

    @IBOutlet weak var photosCollectionView: UICollectionView!

    var takePhotoAction: (() -> Void)?

    var pickedPhotosAction: (Set<PHAsset> -> Void)?

    var images: PHFetchResult!
    let imageManager = PHCachingImageManager()
    var imageCacheController: ImageCacheController!

    var pickedImageSet = Set<PHAsset>() {
        didSet {
            pickedPhotosAction?(pickedImageSet)
        }
    }
    var completion: ((images: [UIImage], imageAssetSet: Set<PHAsset>) -> Void)?

    let cameraCellID = "CameraCell"
    let photoCellID = "PhotoCell"

    override func awakeFromNib() {
        super.awakeFromNib()

        photosCollectionView.registerNib(UINib(nibName: cameraCellID, bundle: nil), forCellWithReuseIdentifier: cameraCellID)
        photosCollectionView.registerNib(UINib(nibName: photoCellID, bundle: nil), forCellWithReuseIdentifier: photoCellID)
        photosCollectionView.dataSource = self
        photosCollectionView.delegate = self

        if let layout = photosCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: 70, height: 70)
            layout.minimumInteritemSpacing = 10
            layout.sectionInset = UIEdgeInsetsZero
        }

        images = PHAsset.fetchAssetsWithMediaType(.Image, options: nil)
        imageCacheController = ImageCacheController(imageManager: imageManager, images: images, preheatSize: 1)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

extension QuickPickPhotosCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return images.count
        default:
            return 0
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        switch indexPath.section {

        case 0:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cameraCellID, forIndexPath: indexPath) as! CameraCell
            return cell

        case 1:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(photoCellID, forIndexPath: indexPath) as! PhotoCell
            return cell

        default:
            return UICollectionViewCell()
        }
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        if let cell = cell as? PhotoCell {
            cell.imageManager = imageManager

            if let imageAsset = images[indexPath.item] as? PHAsset {
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
            if let imageAsset = images[indexPath.item] as? PHAsset {

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


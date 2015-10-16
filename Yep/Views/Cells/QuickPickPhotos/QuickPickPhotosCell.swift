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

    var images: PHFetchResult!
    let imageManager = PHCachingImageManager()
    var imageCacheController: ImageCacheController!

    var pickedImageSet = Set<PHAsset>()
    var completion: ((images: [UIImage], imageAssetSet: Set<PHAsset>) -> Void)?

    let photoCellID = "PhotoCell"

    override func awakeFromNib() {
        super.awakeFromNib()

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
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(photoCellID, forIndexPath: indexPath) as! PhotoCell
        return cell
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
}


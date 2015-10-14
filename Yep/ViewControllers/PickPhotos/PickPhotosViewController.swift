//
//  PickPhotosViewController.swift
//  Yep
//
//  Created by nixzhu on 15/10/14.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Photos

class PickPhotosViewController: UICollectionViewController, PHPhotoLibraryChangeObserver {

    var images: PHFetchResult!
    let imageManager = PHCachingImageManager()
    var imageCacheController: ImageCacheController!

    let photoCellID = "PhotoCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView?.registerNib(UINib(nibName: photoCellID, bundle: nil), forCellWithReuseIdentifier: photoCellID)

        images = PHAsset.fetchAssetsWithMediaType(.Image, options: nil)
        imageCacheController = ImageCacheController(imageManager: imageManager, images: images, preheatSize: 1)

        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(photoCellID, forIndexPath: indexPath) as! PhotoCell

        cell.imageManager = imageManager
        cell.imageAsset = images[indexPath.item] as? PHAsset

        return cell
    }

    // MARK: - ScrollViewDelegate
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let indexPaths = collectionView?.indexPathsForVisibleItems()
        imageCacheController.updateVisibleCells(indexPaths as [NSIndexPath]!)
    }

    // MARK: - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(changeInstance: PHChange) {
        let changeDetails = changeInstance.changeDetailsForFetchResult(images)

        self.images = changeDetails!.fetchResultAfterChanges
        dispatch_async(dispatch_get_main_queue()) {
            // Loop through the visible cell indices
            let indexPaths = self.collectionView?.indexPathsForVisibleItems()
            for indexPath in indexPaths as [NSIndexPath]! {
                if changeDetails!.changedIndexes!.containsIndex(indexPath.item) {
                    let cell = self.collectionView?.cellForItemAtIndexPath(indexPath) as! PhotoCell
                    cell.imageAsset = changeDetails!.fetchResultAfterChanges[indexPath.item] as? PHAsset
                }
            }
        }
    }
}


//
//  PickPhotosViewController.swift
//  Yep
//
//  Created by nixzhu on 15/10/14.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Photos
import Ruler

class PickPhotosViewController: UICollectionViewController, PHPhotoLibraryChangeObserver {

    var images: PHFetchResult!
    let imageManager = PHCachingImageManager()
    var imageCacheController: ImageCacheController!

    let photoCellID = "PhotoCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Pick Photos", comment: "")

        collectionView?.backgroundColor = UIColor.whiteColor()
        collectionView?.alwaysBounceVertical = true
        collectionView?.registerNib(UINib(nibName: photoCellID, bundle: nil), forCellWithReuseIdentifier: photoCellID)

        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {

            let width: CGFloat = Ruler.iPhoneHorizontal(77.5, 92.5, 101).value
            let height = width
            layout.itemSize = CGSize(width: width, height: height)

            let gap: CGFloat = Ruler.iPhoneHorizontal(2, 1, 2).value
            layout.minimumInteritemSpacing = gap
            layout.minimumLineSpacing = gap
            layout.sectionInset = UIEdgeInsets(top: gap, left: gap, bottom: gap, right: gap)
        }

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

        if let imageAsset = images[indexPath.item] as? PHAsset {
            cell.imageAsset = imageAsset
            cell.photoPickedImageView.hidden = !pickedImagesSet.contains(imageAsset)
        }

        return cell
    }

    var pickedImagesSet = Set<PHAsset>()

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        if let imageAsset = images[indexPath.item] as? PHAsset {
            if pickedImagesSet.contains(imageAsset) {
                pickedImagesSet.remove(imageAsset)
            } else {
                pickedImagesSet.insert(imageAsset)
            }

            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
            cell.photoPickedImageView.hidden = !pickedImagesSet.contains(imageAsset)
        }
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


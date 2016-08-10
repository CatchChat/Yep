//
//  PickPhotosViewController.swift
//  Yep
//
//  Created by nixzhu on 15/10/14.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Photos
import YepKit
import Ruler

protocol ReturnPickedPhotosDelegate: class {
    func returnSelectedImages(images: [UIImage], imageAssets: [PHAsset])
}

final class PickPhotosViewController: UICollectionViewController, PHPhotoLibraryChangeObserver {

    var images: PHFetchResult? {
        didSet {
            collectionView?.reloadData()
            guard let images = images, collectionView = collectionView else { return }
            
            collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: images.count - 1, inSection: 0), atScrollPosition: .CenteredVertically, animated: false)
        }
    }
    var imagesDidFetch: Bool = false
    let imageManager = PHCachingImageManager()
    var imageCacheController: ImageCacheController?

    weak var delegate: ReturnPickedPhotosDelegate?
    var album: AlbumListController?
    
    var pickedImageSet = Set<PHAsset>()
    var pickedImages = [PHAsset]()
    var completion: ((images: [UIImage], imageAssets: [PHAsset]) -> Void)?
    var imageLimit = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "\(NSLocalizedString("Pick Photos", comment: "")) (\(imageLimit + pickedImages.count)/4)"

        collectionView?.backgroundColor = UIColor.whiteColor()
        collectionView?.alwaysBounceVertical = true
        automaticallyAdjustsScrollViewInsets = false

        collectionView?.registerNibOf(PhotoCell)

        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {

            let width: CGFloat = Ruler<CGFloat>.iPhoneVertical(77.5, 77.5, 92.5, 102).value
            let height = width
            layout.itemSize = CGSize(width: width, height: height)

            let gap: CGFloat = Ruler<CGFloat>.iPhoneHorizontal(1, 1, 1).value
            layout.minimumInteritemSpacing = gap
            layout.minimumLineSpacing = gap
            layout.sectionInset = UIEdgeInsets(top: gap + 64, left: gap, bottom: gap, right: gap)
        }
        
        let backBarButtonItem = UIBarButtonItem(image: UIImage.yep_iconBack, style: .Plain, target: self, action: #selector(PickPhotosViewController.back(_:)))
        navigationItem.leftBarButtonItem = backBarButtonItem
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(PickPhotosViewController.done(_:)))
        navigationItem.rightBarButtonItem = doneButton
        
        if !imagesDidFetch {
            let options = PHFetchOptions()
            options.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: true)
            ]
            images = PHAsset.fetchAssetsWithMediaType(.Image, options: options)
        }
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        
        
        guard var vcStack = navigationController?.viewControllers else { return }
        if !vcStack.isEmpty {
            if !(vcStack[1] is AlbumListController) {
                album = AlbumListController()
                vcStack.insert(self.album!, atIndex: 1)
                navigationController?.setViewControllers(vcStack, animated: false)
            } else {
                album = vcStack[1] as? AlbumListController
            }
        }
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let images = images else { return }
        
        imageCacheController = ImageCacheController(imageManager: imageManager, images: images, preheatSize: 1)
        
        navigationController?.interactivePopGestureRecognizer?.enabled = true
    }
    
    // MARK: Actions
    
    func back(sender: UIBarButtonItem) {
        album?.imageLimit   = imageLimit
        album?.pickedImages.appendContentsOf(pickedImages)
        navigationController?.popViewControllerAnimated(true)
    }
    
    func done(sender: UIBarButtonItem) {

        var images = [UIImage]()

        let options = PHImageRequestOptions.yep_sharedOptions

        let pickedImageAssets = pickedImages

        for imageAsset in pickedImageAssets {

            let maxSize: CGFloat = 1024

            let pixelWidth = CGFloat(imageAsset.pixelWidth)
            let pixelHeight = CGFloat(imageAsset.pixelHeight)

            //println("pixelWidth: \(pixelWidth)")
            //println("pixelHeight: \(pixelHeight)")

            let targetSize: CGSize

            if pixelWidth > pixelHeight {
                let width = maxSize
                let height = floor(maxSize * (pixelHeight / pixelWidth))
                targetSize = CGSize(width: width, height: height)

            } else {
                let height = maxSize
                let width = floor(maxSize * (pixelWidth / pixelHeight))
                targetSize = CGSize(width: width, height: height)
            }

            //println("targetSize: \(targetSize)")

            imageManager.requestImageDataForAsset(imageAsset, options: options, resultHandler: { (data, String, imageOrientation, _) -> Void in
                if let data = data, image = UIImage(data: data) {
                    if let image = image.resizeToSize(targetSize, withInterpolationQuality: .Medium) {
                        images.append(image)
                    }
                }
            })
        }
        
        if let vcStack = navigationController?.viewControllers {
            weak var destVC: NewFeedViewController?
            for vc in vcStack {
                if vc is NewFeedViewController {
                    let vc = vc as! NewFeedViewController
                    destVC = vc
                    destVC?.returnSelectedImages(images, imageAssets: pickedImageAssets)
                    break
                }
            }
            if let destVC = destVC {
                navigationController?.popToViewController(destVC, animated: true)
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell: PhotoCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
        return cell
    }

    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        if let cell = cell as? PhotoCell {
            cell.imageManager = imageManager

            if let imageAsset = images?[indexPath.item] as? PHAsset {
                cell.imageAsset = imageAsset
                cell.photoPickedImageView.hidden = !pickedImageSet.contains(imageAsset)
            }
        }
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if let imageAsset = images?[indexPath.item] as? PHAsset {
            if pickedImageSet.contains(imageAsset) {
                pickedImageSet.remove(imageAsset)
                if let index = pickedImages.indexOf(imageAsset) {
                    pickedImages.removeAtIndex(index)
                }
            } else {
                if pickedImageSet.count + imageLimit == 4 {
                    return
                }
                if !pickedImageSet.contains(imageAsset) {
                    pickedImageSet.insert(imageAsset)
                    pickedImages.append(imageAsset)
                }
            }
            title = "\(NSLocalizedString("Pick Photos", comment: "")) (\(pickedImageSet.count + imageLimit)/4)"
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
            cell.photoPickedImageView.hidden = !pickedImageSet.contains(imageAsset)
        }
    }

    /*
    // MARK: - ScrollViewDelegate

    override func scrollViewDidScroll(scrollView: UIScrollView) {

        let indexPaths = collectionView?.indexPathsForVisibleItems()
        imageCacheController?.updateVisibleCells(indexPaths as [NSIndexPath]!)
    }
    */
    
    // MARK: - PHPhotoLibraryChangeObserver

    func photoLibraryDidChange(changeInstance: PHChange) {

        guard let changeDetails = changeInstance.changeDetailsForFetchResult(images!) else {
            return
        }

        self.images = changeDetails.fetchResultAfterChanges

        SafeDispatch.async {
            // Loop through the visible cell indices
            guard let
                indexPaths = self.collectionView?.indexPathsForVisibleItems(),
                changedIndexes = changeDetails.changedIndexes else {
                    return
            }

            for indexPath in indexPaths {
                if changedIndexes.containsIndex(indexPath.item) {
                    let cell = self.collectionView?.cellForItemAtIndexPath(indexPath) as! PhotoCell
                    cell.imageAsset = changeDetails.fetchResultAfterChanges[indexPath.item] as? PHAsset
                }
            }
        }
    }
}

extension PickPhotosViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
            return true
        }
        return false
    }
    
}
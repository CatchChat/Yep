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
    func returnSelectedImages(_ images: [UIImage], imageAssets: [PHAsset])
}

final class PickPhotosViewController: UICollectionViewController, PHPhotoLibraryChangeObserver {

    var images: PHFetchResult<PHAsset>? {
        didSet {
            collectionView?.reloadData()
            guard let images = images, let collectionView = collectionView else { return }
            
            collectionView.scrollToItem(at: IndexPath(item: images.count - 1, section: 0), at: .centeredVertically, animated: false)
        }
    }
    var imagesDidFetch: Bool = false
    let imageManager = PHCachingImageManager()
    var imageCacheController: ImageCacheController?

    weak var delegate: ReturnPickedPhotosDelegate?
    var album: AlbumListController?
    
    var pickedImageSet = Set<PHAsset>()
    var pickedImages = [PHAsset]()
    var completion: ((_ images: [UIImage], _ imageAssets: [PHAsset]) -> Void)?
    var imageLimit = 0

    var newTitle: String {
        return String.trans_titlePickPhotos + "(\(imageLimit + pickedImages.count)/\(YepConfig.Feed.maxImagesCount))"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = newTitle

        collectionView?.backgroundColor = UIColor.white
        collectionView?.alwaysBounceVertical = true
        automaticallyAdjustsScrollViewInsets = false

        collectionView?.registerNibOf(PhotoCell.self)

        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {

            let width: CGFloat = Ruler<CGFloat>.iPhoneVertical(77.5, 77.5, 92.5, 102).value
            let height = width
            layout.itemSize = CGSize(width: width, height: height)

            let gap: CGFloat = Ruler<CGFloat>.iPhoneHorizontal(1, 1, 1).value
            layout.minimumInteritemSpacing = gap
            layout.minimumLineSpacing = gap
            layout.sectionInset = UIEdgeInsets(top: gap + 64, left: gap, bottom: gap, right: gap)
        }
        
        let backBarButtonItem = UIBarButtonItem(image: UIImage.yep_iconBack, style: .plain, target: self, action: #selector(PickPhotosViewController.back(_:)))
        navigationItem.leftBarButtonItem = backBarButtonItem
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(PickPhotosViewController.done(_:)))
        navigationItem.rightBarButtonItem = doneButton
        
        if !imagesDidFetch {
            let options = PHFetchOptions()
            options.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: true)
            ]
            images = PHAsset.fetchAssets(with: .image, options: options)
        }
        
        PHPhotoLibrary.shared().register(self)
        
        
        guard var vcStack = navigationController?.viewControllers else { return }
        if !vcStack.isEmpty {
            if !(vcStack[1] is AlbumListController) {
                album = AlbumListController()
                vcStack.insert(self.album!, at: 1)
                navigationController?.setViewControllers(vcStack, animated: false)
            } else {
                album = vcStack[1] as? AlbumListController
            }
        }
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let images = images else { return }
        
        imageCacheController = ImageCacheController(imageManager: imageManager, images: images, preheatSize: 1)
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    // MARK: Actions
    
    func back(_ sender: UIBarButtonItem) {
        album?.imageLimit   = imageLimit
        album?.pickedImages.append(contentsOf: pickedImages)
        _ = navigationController?.popViewController(animated: true)
    }
    
    func done(_ sender: UIBarButtonItem) {

        var images = [UIImage]()

        let options = PHImageRequestOptions.yep_sharedOptions

        let pickedImageAssets = pickedImages

        let maxSize: CGFloat = Config.Media.imageWidth

        for imageAsset in pickedImageAssets {

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

            imageManager.requestImageData(for: imageAsset, options: options, resultHandler: { (data, String, imageOrientation, _) -> Void in
                if let data = data, let image = UIImage(data: data) {
                    if let image = image.resizeToSize(targetSize, withInterpolationQuality: .medium) {
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
                _ = navigationController?.popToViewController(destVC, animated: true)
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell: PhotoCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        if let cell = cell as? PhotoCell {
            cell.imageManager = imageManager

            if let imageAsset = images?[indexPath.item] {
                cell.imageAsset = imageAsset
                cell.photoPickedImageView.isHidden = !pickedImageSet.contains(imageAsset)
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let imageAsset = images?[indexPath.item] {
            if pickedImageSet.contains(imageAsset) {
                pickedImageSet.remove(imageAsset)
                if let index = pickedImages.index(of: imageAsset) {
                    pickedImages.remove(at: index)
                }
            } else {
                if (pickedImageSet.count + imageLimit) == YepConfig.Feed.maxImagesCount {
                    return
                }
                if !pickedImageSet.contains(imageAsset) {
                    pickedImageSet.insert(imageAsset)
                    pickedImages.append(imageAsset)
                }
            }

            title = newTitle

            let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
            cell.photoPickedImageView.isHidden = !pickedImageSet.contains(imageAsset)
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

    func photoLibraryDidChange(_ changeInstance: PHChange) {

        guard let changeDetails = changeInstance.changeDetails(for: images!) else {
            return
        }

        self.images = changeDetails.fetchResultAfterChanges

        SafeDispatch.async {
            // Loop through the visible cell indices
            guard let
                indexPaths = self.collectionView?.indexPathsForVisibleItems,
                let changedIndexes = changeDetails.changedIndexes else {
                    return
            }

            for indexPath in indexPaths {
                if changedIndexes.contains(indexPath.item) {
                    let cell = self.collectionView?.cellForItem(at: indexPath) as! PhotoCell
                    cell.imageAsset = changeDetails.fetchResultAfterChanges[indexPath.item]
                }
            }
        }
    }
}

extension PickPhotosViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
            return true
        }
        return false
    }
    
}

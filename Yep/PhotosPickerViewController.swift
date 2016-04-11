//
//  PhotosPickerViewController.swift
//  Yep
//
//  Created by ChaiYixiao on 4/11/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit
import Photos
import Ruler

class PhotosPickerViewController: UIViewController {
    
    var images: PHFetchResult!
    let imageManager = PHCachingImageManager()
    var imageCacheController: ImageCacheController!
    
    var pickedImageSet = Set<PHAsset>()
    var pickedImages = [PHAsset]()
    var completion: ((images: [UIImage], imageAssets: [PHAsset]) -> Void)?
    var imageLimit = 0
        
    var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.allowsEditing = true
        imagePicker.navigationItem.rightBarButtonItem = nil
        return imagePicker
    }()
    var pickPhotosVC = PickPhotosViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // BackButton 回到 PhotoLibrary
        navigationController?.presentViewController(imagePicker, animated: false, completion: nil)
        imagePicker.delegate = self

        pickPhotosVC = UIStoryboard(name: "PickPhotos", bundle: nil).instantiateViewControllerWithIdentifier("PickPhotosViewController") as! PickPhotosViewController
        pickPhotosVC.delegate = self
        pickPhotosVC.pickedImageSet = pickedImageSet
        pickPhotosVC.imageLimit = imageLimit
        pickPhotosVC.completion = completion

        print(imagePicker.topViewController,imagePicker.presentingViewController,"___!")
        self.imagePicker.pushViewController(self.pickPhotosVC, animated: true)
        print(imagePicker.topViewController,imagePicker.presentingViewController,"___2")

        title = "\(NSLocalizedString("Pick Photos", comment: "")) (\(imageLimit)/4)"
        
//        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(PhotosPickerViewController.done(_:)))
//        imagePicker.navigationItem.rightBarButtonItem = doneButton

        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        images = PHAsset.fetchAssetsWithMediaType(.Image, options: options)
        imageCacheController = ImageCacheController(imageManager: imageManager, images: images, preheatSize: 1)

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.enabled = true
    }
    
    // MARK: Actions
    
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
        
        completion?(images: images, imageAssets: pickedImageAssets)
        navigationController?.popViewControllerAnimated(true)
    }
}

extension PhotosPickerViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
 
    }

}

extension PhotosPickerViewController: PhotosPickerDelegate {
    func dismissPhotoPicker(){
        dismissViewControllerAnimated(false, completion: nil)
        navigationController?.popViewControllerAnimated(true)
    }
}
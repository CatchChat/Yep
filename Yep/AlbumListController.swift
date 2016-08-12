//
//  AlbumListController.swift
//  Yep
//
//  Created by ChaiYixiao on 4/12/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit
import Photos

// @note use this model to store the album's 'result, 'count, 'name, 'startDate to avoid request and reserve too much times

final class Album: NSObject {
    var results: PHFetchResult?
    var count = 0
    var name: String?
    var startDate: NSDate?
    var identifier: String?
}

private let defaultAlbumIdentifier = "com.Yep.photoPicker"

final class AlbumListController: UITableViewController {

    var pickedImageSet = Set<PHAsset>()
    var pickedImages = [PHAsset]()
    var completion: ((images: [UIImage], imageAssets: [PHAsset]) -> Void)?

    var imageLimit = 0
    
    var assetsCollection: [Album]?

    lazy var pickPhotosVC: PickPhotosViewController = {
        return UIStoryboard.Scene.pickPhotos
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cancelButton = UIBarButtonItem(title: String.trans_cancel, style: .Plain, target: self, action: #selector(AlbumListController.cancel(_:)))
        navigationItem.rightBarButtonItem = cancelButton
        navigationItem.hidesBackButton = true
        
        tableView.registerNibOf(AlbumListCell)

        tableView.tableFooterView = UIView()
        
        assetsCollection = fetchAlbumList()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.interactivePopGestureRecognizer?.enabled = true
    }

    @objc private func cancel(sender: UIBarButtonItem) {
        
        if let vcStack = navigationController?.viewControllers {
            var destVC: UIViewController?
            for vc in vcStack {
                if vc.isKindOfClass(NewFeedViewController) {
                    destVC = vc
                    break
                }
            }
            if let destVC = destVC {
                navigationController?.popToViewController(destVC, animated: true)
            }
        }
    }
    
    func fetchAlbumIdentifier() -> String? {
        let string = NSUserDefaults.standardUserDefaults().objectForKey(defaultAlbumIdentifier) as? String
        return string
    }
    
    func fetchAlbum() -> Album {
        let album = Album()
        let identifier = fetchAlbumIdentifier()
        guard identifier != nil else {
            return album
        }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.Image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let result = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: nil)
        if result.count <= 0 {
            return album
        }
        
        let collection = result.firstObject as? PHAssetCollection
        let requestResult = PHAsset.fetchAssetsInAssetCollection(collection!, options: options)
        album.count = requestResult.count
        album.name = collection?.localizedTitle
        album.results = requestResult
        album.startDate = collection?.startDate
        album.identifier = collection?.localIdentifier
        return album
    }
    
    func fetchAlbumList() -> [Album]? {
        let userAlbumsOptions = PHFetchOptions()
        userAlbumsOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
        userAlbumsOptions.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        var results: [PHFetchResult] = []
        results.append(PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .AlbumRegular, options: nil))
        results.append(PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: userAlbumsOptions))
        var list: [Album] = []
        guard !results.isEmpty else {
            return nil
        }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.Image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        for (_, result) in results.enumerate() {
            result.enumerateObjectsUsingBlock {  (collection, idx, stop) in
                if let album = collection as? PHAssetCollection{
                    guard  album.localizedTitle !=  NSLocalizedString("Recently Deleted", comment: "") else { return }
                    
                    let assetResults = PHAsset.fetchAssetsInAssetCollection(album, options: options)
                   
                    var count = 0
                    switch album.assetCollectionType {
                    case .Album:
                        count = assetResults.count
                    case .SmartAlbum:
                        count = assetResults.count
                    case .Moment:
                        count = 0
                    }
                    if count > 0 {
                        autoreleasepool {
                            let ab = Album()
                            ab.count = count
                            ab.results = assetResults
                            ab.name = album.localizedTitle
                            ab.startDate = album.startDate
                            ab.identifier = album.localIdentifier
                            list.append(ab)
                        }
                    }
                }
                
            }

        }

        return list
    }

    func fetchImageWithAsset(asset: PHAsset?, targetSize: CGSize, imageResultHandler: (image: UIImage?)->Void) -> PHImageRequestID? {
        guard let asset = asset else {
            return nil
        }
        
        let options = PHImageRequestOptions()
        options.resizeMode = .Exact
        
        let scale = UIScreen.mainScreen().scale
        
        let size = CGSizeMake(targetSize.width * scale, targetSize.height * scale);
        
        return PHCachingImageManager.defaultManager().requestImageForAsset(asset,targetSize: size, contentMode: .AspectFill, options: options) { (result, info) in
            imageResultHandler(image: result)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return assetsCollection == nil ? 0 : assetsCollection!.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: AlbumListCell = tableView.dequeueReusableCell()
        if let album = assetsCollection?[indexPath.row] {
            cell.countLabel.text = "(\(album.count))"
            cell.titleLabel.text = album.name 
            fetchImageWithAsset(album.results?.lastObject as? PHAsset, targetSize: CGSizeMake(60, 60), imageResultHandler: { (image) in
                cell.posterImageView.image = image
            })
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let album = assetsCollection?[indexPath.row] else { return }

        pickPhotosVC.imagesDidFetch = true
        pickPhotosVC.pickedImages = pickedImages
        pickPhotosVC.pickedImageSet = Set(pickedImages)
        pickPhotosVC.imageLimit = imageLimit
        pickPhotosVC.images = album.results
        completion = pickPhotosVC.completion
        pickPhotosVC.delegate = self
        navigationController?.pushViewController(pickPhotosVC, animated: true)
    }
}

extension AlbumListController: ReturnPickedPhotosDelegate {

    func returnSelectedImages(images: [UIImage], imageAssets: [PHAsset]) {
        pickedImages.appendContentsOf(imageAssets)
    }
}
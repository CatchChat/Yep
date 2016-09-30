//
//  AlbumListController.swift
//  Yep
//
//  Created by ChaiYixiao on 4/12/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit
import Photos
import YepKit

// @note use this model to store the album's 'result, 'count, 'name, 'startDate to avoid request and reserve too much times

final class Album: NSObject {
    var results: PHFetchResult<PHAsset>?
    var count = 0
    var name: String?
    var startDate: Date?
    var identifier: String?
}

private let defaultAlbumIdentifier = "com.Yep.photoPicker"

final class AlbumListController: UITableViewController {

    var pickedImageSet = Set<PHAsset>()
    var pickedImages = [PHAsset]()
    var completion: ((_ images: [UIImage], _ imageAssets: [PHAsset]) -> Void)?

    var imageLimit = 0
    
    var assetsCollection: [Album]?

    lazy var pickPhotosVC: PickPhotosViewController = {
        return UIStoryboard.Scene.pickPhotos
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cancelButton = UIBarButtonItem(title: String.trans_cancel, style: .plain, target: self, action: #selector(AlbumListController.cancel(_:)))
        navigationItem.rightBarButtonItem = cancelButton
        navigationItem.hidesBackButton = true
        
        tableView.registerNibOf(AlbumListCell.self)

        tableView.tableFooterView = UIView()
        
        assetsCollection = fetchAlbumList()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    @objc fileprivate func cancel(_ sender: UIBarButtonItem) {
        
        if let vcStack = navigationController?.viewControllers {
            var destVC: UIViewController?
            for vc in vcStack {
                if vc.isKind(of: NewFeedViewController.self) {
                    destVC = vc
                    break
                }
            }
            if let destVC = destVC {
                _ = navigationController?.popToViewController(destVC, animated: true)
            }
        }
    }
    
    fileprivate func fetchAlbumIdentifier() -> String? {
        let string = UserDefaults.standard.object(forKey: defaultAlbumIdentifier) as? String
        return string
    }
    
    fileprivate func fetchAlbum() -> Album {
        let album = Album()
        let identifier = fetchAlbumIdentifier()
        guard identifier != nil else {
            return album
        }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        if result.count <= 0 {
            return album
        }
        
        guard let collection = result.firstObject else {
            return album
        }

        let requestResult = PHAsset.fetchAssets(in: collection, options: options)
        album.count = requestResult.count
        album.name = collection.localizedTitle
        album.results = requestResult
        album.startDate = collection.startDate
        album.identifier = collection.localIdentifier

        return album
    }
    
    fileprivate func fetchAlbumList() -> [Album]? {
        let userAlbumsOptions = PHFetchOptions()
        userAlbumsOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
        userAlbumsOptions.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        var results: [PHFetchResult<PHAssetCollection>] = []
        results.append(PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil))
        results.append(PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: userAlbumsOptions))
        var list: [Album] = []
        guard !results.isEmpty else {
            return nil
        }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        for (_, result) in results.enumerated() {

            result.enumerateObjects({ (collection: PHAssetCollection, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                let album = collection
                guard  album.localizedTitle !=  NSLocalizedString("Recently Deleted", comment: "") else {
                    return
                }
                
                let assetResults = PHAsset.fetchAssets(in: album, options: options)
               
                let count: Int
                switch album.assetCollectionType {
                case .album:
                    count = assetResults.count
                case .smartAlbum:
                    count = assetResults.count
                case .moment:
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
            })
        }

        return list
    }

    fileprivate func fetchImageWithAsset(_ asset: PHAsset?, targetSize: CGSize, imageResultHandler: @escaping (_ image: UIImage?)->Void) -> PHImageRequestID? {
        guard let asset = asset else {
            return nil
        }
        
        let options = PHImageRequestOptions()
        options.resizeMode = .exact
        
        let scale = UIScreen.main.scale
        
        let size = CGSize(width: targetSize.width * scale, height: targetSize.height * scale);
        
        return PHCachingImageManager.default().requestImage(for: asset,targetSize: size, contentMode: .aspectFill, options: options) { (result, info) in
            imageResultHandler(result)
        }
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return assetsCollection == nil ? 0 : assetsCollection!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: AlbumListCell = tableView.dequeueReusableCell()

        if let album = assetsCollection?[indexPath.row] {
            cell.countLabel.text = "(\(album.count))"
            cell.titleLabel.text = album.name

            SafeDispatch.async(onQueue: DispatchQueue.global(qos: .default)) { [weak self] in

                _ = self?.fetchImageWithAsset(album.results?.lastObject, targetSize: CGSize(width: 60, height: 60), imageResultHandler: { (image) in

                    SafeDispatch.async {
                        cell.posterImageView.image = image
                    }
                })
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return 60
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

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

    func returnSelectedImages(_ images: [UIImage], imageAssets: [PHAsset]) {
        pickedImages.append(contentsOf: imageAssets)
    }
}

//
//  PhotoCacheController.swift
//  Yep
//
//  Created by nixzhu on 15/10/14.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import Foundation
import Photos

final class ImageCacheController {

    fileprivate var cachedIndices = NSIndexSet()
    fileprivate let cachePreheatSize: Int
    fileprivate let imageCache: PHCachingImageManager
    fileprivate let images: PHFetchResult<PHAsset>
    fileprivate let targetSize = CGSize(width: 80, height: 80)
    fileprivate let contentMode = PHImageContentMode.aspectFill

    init(imageManager: PHCachingImageManager, images: PHFetchResult<PHAsset>, preheatSize: Int = 1) {
        self.cachePreheatSize = preheatSize
        self.imageCache = imageManager
        self.images = images
    }

    func updateVisibleCells(_ visibleCells: [IndexPath]) {

        guard !visibleCells.isEmpty else {
            return
        }

        let updatedCache = NSMutableIndexSet()
        for path in visibleCells {
            updatedCache.add(path.item)
        }

        let minCache = max(0, updatedCache.firstIndex - cachePreheatSize)
        let maxCache = min(images.count - 1, updatedCache.lastIndex + cachePreheatSize)

        updatedCache.add(in: NSMakeRange(minCache, maxCache - minCache + 1))

        // Which indices can be chucked?
        cachedIndices.enumerated().forEach { (index, _) in
            if !updatedCache.contains(index) {
                let asset: PHAsset! = self.images[index]
                self.imageCache.stopCachingImages(for: [asset], targetSize: self.targetSize, contentMode: self.contentMode, options: nil)
                //println("Stopping caching image \(index)")
            }
        }
        // And which are new?
        updatedCache.enumerated().forEach { (index, _) in
            if !self.cachedIndices.contains(index) {
                let asset: PHAsset = self.images[index]
                self.imageCache.startCachingImages(for: [asset], targetSize: self.targetSize, contentMode: self.contentMode, options: nil)
                //println("Starting caching image \(index)")
            }
        }

        cachedIndices = updatedCache
    }
}


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

    private var cachedIndices = NSIndexSet()
    let cachePreheatSize: Int
    let imageCache: PHCachingImageManager
    let images: PHFetchResult
    var targetSize = CGSize(width: 80, height: 80)
    var contentMode = PHImageContentMode.AspectFill

    init(imageManager: PHCachingImageManager, images: PHFetchResult, preheatSize: Int = 1) {
        self.cachePreheatSize = preheatSize
        self.imageCache = imageManager
        self.images = images
    }

    func updateVisibleCells(visibleCells: [NSIndexPath]) {

        guard !visibleCells.isEmpty else {
            return
        }

        let updatedCache = NSMutableIndexSet()
        for path in visibleCells {
            updatedCache.addIndex(path.item)
        }

        let minCache = max(0, updatedCache.firstIndex - cachePreheatSize)
        let maxCache = min(images.count - 1, updatedCache.lastIndex + cachePreheatSize)

        updatedCache.addIndexesInRange(NSMakeRange(minCache, maxCache - minCache + 1))

        // Which indices can be chucked?
        self.cachedIndices.enumerateIndexesUsingBlock { index, _ in
            if !updatedCache.containsIndex(index) {
                let asset: PHAsset! = self.images[index] as! PHAsset
                self.imageCache.stopCachingImagesForAssets([asset], targetSize: self.targetSize, contentMode: self.contentMode, options: nil)
                //println("Stopping caching image \(index)")
            }
        }
        // And which are new?
        updatedCache.enumerateIndexesUsingBlock { index, _ in
            if !self.cachedIndices.containsIndex(index) {
                let asset: PHAsset! = self.images[index] as! PHAsset
                self.imageCache.startCachingImagesForAssets([asset], targetSize: self.targetSize, contentMode: self.contentMode, options: nil)
                //println("Starting caching image \(index)")
            }
        }

        cachedIndices = NSIndexSet(indexSet: updatedCache)
    }
}


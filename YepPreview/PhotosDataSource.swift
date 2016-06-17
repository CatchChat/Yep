//
//  PhotosDataSource.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

class PhotosDataSource: NSObject {

    let photos: NSArray

    init(photos: NSArray) {
        self.photos = photos
    }
}

extension PhotosDataSource: PhotosViewControllerDataSource {

    var numberOfPhotos: Int {

        return photos.count
    }

    func photoAtIndex(index: Int) -> Photo? {

        if index < numberOfPhotos {
            return photos[index] as? Photo
        }

        return nil
    }

    func indexOfPhoto(photo: Photo) -> Int {

        return photos.indexOfObject(photo)
    }

    func containsPhoto(photo: Photo) -> Bool {

        return photos.containsObject(photo)
    }
}


//
//  PhotosDataSource.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

class PhotosDataSource: NSObject {

    let photos: [Photo]

    private let _photos: NSArray!

    init(photos: [Photo]) {
        self.photos = photos

        let _photos = NSMutableArray()
        for photo in photos {
            _photos.addObject(photo)
        }
        self._photos = _photos
    }
}

extension PhotosDataSource: PhotosViewControllerDataSource {

    var numberOfPhotos: Int {

        return photos.count
    }

    func photoAtIndex(index: Int) -> Photo? {

        if (index >= 0) && (index < numberOfPhotos) {
            return photos[index]
        }

        return nil
    }

    func indexOfPhoto(photo: Photo) -> Int {

        return _photos.indexOfObject(photo)
    }

    func containsPhoto(photo: Photo) -> Bool {

        return _photos.containsObject(photo)
    }
}


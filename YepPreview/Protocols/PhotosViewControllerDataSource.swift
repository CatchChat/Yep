//
//  PhotosViewControllerDataSource.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

protocol PhotosViewControllerDataSource: class {

    var numberOfPhotos: Int { get }
    func photoAtIndex(index: Int) -> Photo?
    func indexOfPhoto(photo: Photo) -> Int
    func containsPhoto(photo: Photo) -> Bool
}


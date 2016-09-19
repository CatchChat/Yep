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
    func photoAtIndex(_ index: Int) -> Photo?
    func indexOfPhoto(_ photo: Photo) -> Int
    func containsPhoto(_ photo: Photo) -> Bool
}


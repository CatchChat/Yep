//
//  Photo.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

public protocol Photo: class {

    var image: UIImage? { get }

    var updatedImage: ((image: UIImage?) -> Void)? { get set }
}


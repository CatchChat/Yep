//
//  ImageType.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

public enum ImageType {

    case image(UIImage)
    case imageData(NSData)
    case imageURL(NSURL)
    case imageFileURL(NSURL)

    var image: UIImage? {
        switch self {
        case .image(let image): return image
        case .imageData(let data): return UIImage(data: data)
        case .imageURL: return nil
        case .imageFileURL: return nil
        }
    }
}


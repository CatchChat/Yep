//
//  OpenGraphInfoType.swift
//  Yep
//
//  Created by nixzhu on 16/1/15.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

public protocol OpenGraphInfoType {

    var URL: NSURL { get }

    var siteName: String { get }
    var title: String { get }
    var infoDescription: String { get }
    var thumbnailImageURLString: String { get }
}



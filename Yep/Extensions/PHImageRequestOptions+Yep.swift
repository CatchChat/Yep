//
//  PHImageRequestOptions+Yep.swift
//  Yep
//
//  Created by nixzhu on 16/1/4.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Photos

extension PHImageRequestOptions {

    static var yep_sharedOptions: PHImageRequestOptions {

        let options = PHImageRequestOptions()
        options.synchronous = true
        options.version = .Current
        options.deliveryMode = .HighQualityFormat
        options.resizeMode = .Exact
        options.networkAccessAllowed = true

        return options
    }
}


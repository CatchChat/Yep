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
        options.isSynchronous = true
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true

        return options
    }
}


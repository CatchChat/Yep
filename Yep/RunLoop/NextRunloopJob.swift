//
//  NextRunloopJob.swift
//  Yep
//
//  Created by NIX on 16/7/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

func doInNextRunLoop(_ job: @escaping ()->()) {

    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(0) / Double(NSEC_PER_SEC)) {
        job()
    }
}


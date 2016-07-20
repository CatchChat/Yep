//
//  NextRunloopJob.swift
//  Yep
//
//  Created by NIX on 16/7/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

func doInNextRunLoop(job: dispatch_block_t) {

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue()) {
        job()
    }
}


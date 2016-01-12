//
//  OpenGraphService.swift
//  Yep
//
//  Created by nixzhu on 16/1/12.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Alamofire

func openGraphWithURLString(URLString: String, failureHandler: ((Reason, String?) -> Void)?, completion: () -> Void) {

    Alamofire.request(.GET, URLString, parameters: nil, encoding: .URL).responseString { responseString in
        println("\n openGraphWithURLString: \(URLString)\n\(responseString)")
    }
}


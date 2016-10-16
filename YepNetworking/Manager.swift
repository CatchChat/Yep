//
//  Manager.swift
//  Yep
//
//  Created by NIX on 16/5/19.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

open class Manager {

    fileprivate init() {
    }

    open static var accessToken: (() -> String?)?

    open static var authFailedAction: ((_ statusCode: Int, _ host: String) -> Void)?

    open static var networkActivityCountChangedAction: ((_ count: Int) -> Void)?
}


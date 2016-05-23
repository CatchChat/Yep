//
//  Config.swift
//  Yep
//
//  Created by NIX on 16/5/23.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

public class Config {

    public static var updatedAccessTokenAction: (() -> Void)?
    public static var updatedPusherIDAction: ((pusherID: String) -> Void)?
}


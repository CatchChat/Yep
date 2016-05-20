//
//  Manager.swift
//  Yep
//
//  Created by NIX on 16/5/19.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

public class Manager {

    private init() {
    }

    public static var accessToken: (() -> String?)?

    public static var authFailedAction: ((statusCode: Int, host: String) -> Void)?

    public static var networkActivityCountChangedAction: ((count: Int) -> Void)?
}


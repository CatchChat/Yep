//
//  Store.swift
//  Yep
//
//  Created by NIX on 16/8/31.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import ReSwift

let mainStore = Store<AppState>(
    reducer: MobilePhoneReducer(),
    state: nil
)

